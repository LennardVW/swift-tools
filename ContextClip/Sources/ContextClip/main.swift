import Foundation
import AppKit

// MARK: - Context-Aware Clipboard Item
struct ClipItem: Codable, Identifiable {
    let id: UUID
    let content: String
    let contentType: ContentType
    let timestamp: Date
    let context: ClipContext
    
    var searchText: String {
        return "\(content) \(context.appName) \(context.windowTitle) \(context.url ?? "")"
    }
}

enum ContentType: String, Codable {
    case text
    case url
    case code
    case email
    case imagePath
}

struct ClipContext: Codable {
    let appName: String
    let appBundleID: String
    let windowTitle: String
    let url: String? // If from browser
    let filePath: String? // If from Finder/code editor
    let projectName: String? // Extracted from path or window title
}

// MARK: - Smart Clipboard Manager
@MainActor
final class ContextClipboard {
    static let shared = ContextClipboard()
    private var history: [ClipItem] = []
    private let maxItems = 100
    private var lastClipboardContent: String = ""
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                await self.checkClipboard()
            }
        }
    }
    
    private func checkClipboard() async {
        guard let clipboard = NSPasteboard.general.string(forType: .string),
              clipboard != lastClipboardContent,
              !clipboard.isEmpty else {
            return
        }
        
        lastClipboardContent = clipboard
        
        // Capture context
        let context = await captureContext()
        let type = detectContentType(clipboard)
        
        let item = ClipItem(
            id: UUID(),
            content: clipboard,
            contentType: type,
            timestamp: Date(),
            context: context
        )
        
        history.insert(item, at: 0)
        
        // Keep only recent items
        if history.count > maxItems {
            history.removeLast()
        }
        
        print("📋 Captured from \(context.appName): \(clipboard.prefix(50))...")
    }
    
    private func captureContext() async -> ClipContext {
        let workspace = NSWorkspace.shared
        
        // Get frontmost app
        guard let frontApp = workspace.frontmostApplication else {
            return ClipContext(
                appName: "Unknown",
                appBundleID: "",
                windowTitle: "",
                url: nil,
                filePath: nil,
                projectName: nil
            )
        }
        
        let appName = frontApp.localizedName ?? "Unknown"
        let bundleID = frontApp.bundleIdentifier ?? ""
        
        // Try to get window title (requires accessibility permissions)
        var windowTitle = ""
        var url: String? = nil
        var filePath: String? = nil
        var projectName: String? = nil
        
        // For browsers, try to get URL
        if bundleID.contains("safari") || bundleID.contains("chrome") {
            url = await getBrowserURL(for: bundleID)
        }
        
        // For code editors, extract project from path
        if bundleID.contains("xcode") || bundleID.contains("vscode") {
            (filePath, projectName) = await getEditorContext(for: bundleID)
        }
        
        return ClipContext(
            appName: appName,
            appBundleID: bundleID,
            windowTitle: windowTitle,
            url: url,
            filePath: filePath,
            projectName: projectName
        )
    }
    
    private func detectContentType(_ content: String) -> ContentType {
        if content.hasPrefix("http") || content.hasPrefix("www") {
            return .url
        } else if content.contains("@") && content.contains(".") && !content.contains(" ") {
            return .email
        } else if content.contains("{") || content.contains("def ") || content.contains("func ") {
            return .code
        } else {
            return .text
        }
    }
    
    private func getBrowserURL(for bundleID: String) async -> String? {
        // Use AppleScript to get current URL from browser
        var script = ""
        if bundleID.contains("safari") {
            script = "tell application \"Safari\" to return URL of current tab of front window"
        } else if bundleID.contains("chrome") {
            script = "tell application \"Google Chrome\" to return URL of active tab of front window"
        }
        
        guard !script.isEmpty else { return nil }
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        try? task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func getEditorContext(for bundleID: String) async -> (filePath: String?, projectName: String?) {
        // Extract project name from window title or active document
        // This is simplified - real implementation would use editor-specific AppleScripts
        return (nil, nil)
    }
    
    // MARK: - Search
    
    func search(query: String) -> [ClipItem] {
        let lowerQuery = query.lowercased()
        
        // Smart search: understand natural language queries
        // "from safari" -> items from Safari
        // "2 hours ago" -> items from last 2 hours
        // "link" -> URLs
        // "code" -> code snippets
        
        let timeFilter = parseTimeFilter(from: query)
        let appFilter = parseAppFilter(from: query)
        let typeFilter = parseTypeFilter(from: query)
        
        return history.filter { item in
            var matches = true
            
            // Time filter
            if let timeFilter = timeFilter {
                matches = matches && Date().timeIntervalSince(item.timestamp) <= timeFilter
            }
            
            // App filter
            if let appFilter = appFilter {
                matches = matches && item.context.appName.lowercased().contains(appFilter)
            }
            
            // Type filter
            if let typeFilter = typeFilter {
                matches = matches && item.contentType == typeFilter
            }
            
            // Text search
            if !lowerQuery.isEmpty && timeFilter == nil && appFilter == nil && typeFilter == nil {
                matches = matches && item.searchText.lowercased().contains(lowerQuery)
            }
            
            return matches
        }
    }
    
    private func parseTimeFilter(from query: String) -> TimeInterval? {
        // "2 hours ago", "yesterday", "10 minutes ago"
        let patterns = [
            ("(\\d+)\\s*hours?\\s*ago", 3600.0),
            ("(\\d+)\\s*minutes?\\s*ago", 60.0),
            ("(\\d+)\\s*days?\\s*ago", 86400.0),
            ("yesterday", 86400.0),
            ("today", 0.0),
        ]
        
        for (pattern, multiplier) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(query.startIndex..., in: query)
                if let match = regex.firstMatch(in: query, options: [], range: range) {
                    if let numberRange = Range(match.range(at: 1), in: query) {
                        let number = Double(query[numberRange]) ?? 1
                        return number * multiplier
                    } else if pattern == "yesterday" {
                        return 86400
                    }
                }
            }
        }
        return nil
    }
    
    private func parseAppFilter(from query: String) -> String? {
        let patterns = [
            "from\\s+(\\w+)",
            "in\\s+(safari|chrome|xcode|vscode)",
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(query.startIndex..., in: query)
                if let match = regex.firstMatch(in: query, options: [], range: range) {
                    if let appRange = Range(match.range(at: 1), in: query) {
                        return String(query[appRange]).lowercased()
                    }
                }
            }
        }
        return nil
    }
    
    private func parseTypeFilter(from query: String) -> ContentType? {
        if query.contains("link") || query.contains("url") {
            return .url
        } else if query.contains("code") {
            return .code
        } else if query.contains("email") {
            return .email
        }
        return nil
    }
    
    func listRecent(count: Int = 10) -> [ClipItem] {
        return Array(history.prefix(count))
    }
    
    func copyToClipboard(_ item: ClipItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
        print("📋 Copied: \(item.content.prefix(50))...")
    }
}

// MARK: - CLI Interface
struct ContextClipCLI {
    static func main() async {
        let clipboard = ContextClipboard.shared
        
        print("📋 ContextClip started. Monitoring clipboard...")
        print("\nCommands:")
        print("  list [n]          - Show last n items (default 10)")
        print("  search <query>    - Search clipboard history")
        print("  copy <id>         - Copy item to clipboard")
        print("  quit              - Exit\n")
        
        while true {
            print("> ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else { continue }
            
            let parts = input.split(separator: " ", maxSplits: 1)
            guard let command = parts.first?.lowercased() else { continue }
            
            switch command {
            case "list", "ls":
                let count = parts.count > 1 ? Int(parts[1]) ?? 10 : 10
                await listItems(count: count)
                
            case "search", "s", "find":
                let query = parts.count > 1 ? String(parts[1]) : ""
                await searchItems(query: query)
                
            case "copy", "cp":
                if parts.count > 1 {
                    await copyItem(id: String(parts[1]))
                }
                
            case "quit", "exit", "q":
                print("👋 Goodbye!")
                return
                
            default:
                print("Unknown command. Try: list, search, copy, quit")
            }
        }
    }
    
    static func listItems(count: Int) async {
        let items = ContextClipboard.shared.listRecent(count: count)
        
        for item in items {
            let timeAgo = formatTimeAgo(item.timestamp)
            print("\n[\(item.id.uuidString.prefix(8))] \(timeAgo)")
            print("  From: \(item.context.appName)")
            if let url = item.context.url {
                print("  URL: \(url)")
            }
            print("  Content: \(item.content.prefix(100))\(item.content.count > 100 ? "..." : "")")
        }
    }
    
    static func searchItems(query: String) async {
        let results = ContextClipboard.shared.search(query: query)
        
        if results.isEmpty {
            print("No results found for '\(query)'")
        } else {
            print("Found \(results.count) items:")
            for item in results {
                let timeAgo = formatTimeAgo(item.timestamp)
                print("  [\(item.id.uuidString.prefix(8))] \(timeAgo) - \(item.context.appName): \(item.content.prefix(50))...")
            }
        }
    }
    
    static func copyItem(id: String) async {
        // Find item by partial ID
        let items = ContextClipboard.shared.listRecent(count: 100)
        if let item = items.first(where: { $0.id.uuidString.hasPrefix(id) }) {
            ContextClipboard.shared.copyToClipboard(item)
            print("✅ Copied to clipboard")
        } else {
            print("❌ Item not found")
        }
    }
    
    static func formatTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// Run CLI
await ContextClipCLI.main()
