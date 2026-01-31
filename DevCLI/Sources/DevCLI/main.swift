import Foundation

// MARK: - Entry Point
@main
struct DevCLI {
    static func main() async throws {
        let cli = DevCLI()
        try await cli.run()
    }
    
    func run() async throws {
        let arguments = CommandLine.arguments
        
        guard arguments.count > 1 else {
            printHelp()
            return
        }
        
        let command = arguments[1]
        let args = Array(arguments.dropFirst(2))
        
        switch command {
        case "json", "j":
            try await handleJSONCommand(args)
        case "base64", "b64":
            try handleBase64Command(args)
        case "uuid", "u":
            handleUUIDCommand(args)
        case "timestamp", "ts":
            handleTimestampCommand(args)
        case "help", "-h", "--help":
            printHelp()
        default:
            print("Unknown command: \(command)")
            printHelp()
        }
    }
    
    func printHelp() {
        print("""
        DevCLI - Developer utilities for macOS
        
        USAGE:
            devcli <command> [options]
        
        COMMANDS:
            json, j          Format and validate JSON
            base64, b64      Encode/decode Base64
            uuid, u          Generate UUIDs
            timestamp, ts    Convert timestamps
            help             Show this help message
        
        EXAMPLES:
            devcli json '{"key":"value"}'
            devcli json --pretty file.json
            devcli base64 encode "Hello World"
            devcli base64 decode SGVsbG8gV29ybGQ=
            devcli uuid --count 5
            devcli timestamp now
        """)
    }
}

// MARK: - JSON Command
extension DevCLI {
    func handleJSONCommand(_ args: [String]) async throws {
        guard !args.isEmpty else {
            print("Usage: devcli json <json-string-or-file> [--compact]")
            return
        }
        
        let input: String
        let pretty = !args.contains("--compact")
        
        // Check if input is a file path
        let potentialPath = args[0]
        let fileURL = URL(fileURLWithPath: potentialPath)
        
        if FileManager.default.fileExists(atPath: potentialPath),
           let contents = try? String(contentsOf: fileURL) {
            input = contents
        } else {
            input = args[0]
        }
        
        guard let data = input.data(using: .utf8) else {
            print("Error: Invalid input encoding")
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            let outputOptions: JSONSerialization.WritingOptions = pretty 
                ? [.prettyPrinted, .sortedKeys]
                : [.sortedKeys]
            
            let outputData = try JSONSerialization.data(withJSONObject: json, options: outputOptions)
            
            if let output = String(data: outputData, encoding: .utf8) {
                print(output)
            }
        } catch {
            print("Error: Invalid JSON - \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Base64 Command
extension DevCLI {
    func handleBase64Command(_ args: [String]) throws {
        guard args.count >= 2 else {
            print("Usage: devcli base64 <encode|decode> <string>")
            return
        }
        
        let action = args[0]
        let input = args[1]
        
        switch action {
        case "encode", "e":
            if let data = input.data(using: .utf8) {
                let encoded = data.base64EncodedString()
                print(encoded)
            }
            
        case "decode", "d":
            if let data = Data(base64Encoded: input),
               let decoded = String(data: data, encoding: .utf8) {
                print(decoded)
            } else {
                print("Error: Invalid Base64 string")
            }
            
        default:
            print("Unknown action: \(action). Use 'encode' or 'decode'")
        }
    }
}

// MARK: - UUID Command
extension DevCLI {
    func handleUUIDCommand(_ args: [String]) {
        let count = args.first(where: { $0.hasPrefix("--count=") })
            .flatMap { Int($0.dropFirst(8)) } 
            ?? 1
        
        let uppercase = args.contains("--uppercase")
        
        for _ in 0..<count {
            var uuid = UUID().uuidString
            if uppercase {
                uuid = uuid.uppercased()
            }
            print(uuid)
        }
    }
}

// MARK: - Timestamp Command
extension DevCLI {
    func handleTimestampCommand(_ args: [String]) {
        guard let subcommand = args.first else {
            print("Usage: devcli timestamp <now|convert> [value]")
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = .current
        
        switch subcommand {
        case "now", "n":
            let timestamp = Int(Date().timeIntervalSince1970)
            let formatted = formatter.string(from: Date())
            print("Unix: \(timestamp)")
            print("Local: \(formatted)")
            
        case "convert", "c":
            guard args.count > 1, let timestamp = Double(args[1]) else {
                print("Error: Provide a valid timestamp")
                return
            }
            let date = Date(timeIntervalSince1970: timestamp)
            print(formatter.string(from: date))
            
        default:
            print("Unknown subcommand: \(subcommand)")
        }
    }
}
