import Foundation
import AppKit
import Combine

// MARK: - Flow State Detector
/// Detects flow states based on input patterns, not just time tracking
@MainActor
final class FlowDetector: ObservableObject {
    @Published var currentState: FlowState = .neutral
    @Published var flowScore: Double = 0.0 // 0.0 to 1.0
    @Published var sessionDuration: TimeInterval = 0
    @Published var interruptions: Int = 0
    
    private var inputTracker = InputTracker()
    private var sessionStart: Date?
    private var lastFlowEntry: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // Flow detection parameters
    private let flowThreshold = 0.75
    private let interruptionThreshold: TimeInterval = 15 // seconds of inactivity
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        // Analyze input patterns every 5 seconds
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.analyzeFlow()
                }
            }
            .store(in: &cancellables)
    }
    
    private func analyzeFlow() async {
        let metrics = await inputTracker.getMetrics()
        
        // Calculate flow score based on multiple factors
        var score: Double = 0.0
        
        // 1. Typing rhythm consistency (0-0.3)
        if metrics.typingWPM > 30 && metrics.typingConsistency > 0.7 {
            score += 0.3
        } else if metrics.typingWPM > 20 {
            score += 0.15
        }
        
        // 2. Mouse movement fluidity (0-0.2)
        if metrics.mouseFluidity > 0.8 {
            score += 0.2
        } else if metrics.mouseFluidity > 0.5 {
            score += 0.1
        }
        
        // 3. App switch frequency (0-0.25)
        if metrics.appSwitchesPerMinute < 2 {
            score += 0.25
        } else if metrics.appSwitchesPerMinute < 5 {
            score += 0.1
        }
        
        // 4. Focus duration (0-0.25)
        if let start = sessionStart {
            let duration = Date().timeIntervalSince(start)
            if duration > 300 { // 5 minutes
                score += 0.25
            } else if duration > 60 {
                score += 0.1
            }
        }
        
        flowScore = min(score, 1.0)
        
        // Update state
        let newState: FlowState
        if flowScore >= flowThreshold {
            newState = .flow
            if currentState != .flow {
                enterFlow()
            }
        } else if flowScore > 0.4 {
            newState = .focused
        } else if metrics.timeSinceLastInput > interruptionThreshold {
            newState = .distracted
            if currentState == .flow || currentState == .focused {
                interruptions += 1
            }
        } else {
            newState = .neutral
        }
        
        currentState = newState
        
        if let start = sessionStart {
            sessionDuration = Date().timeIntervalSince(start)
        }
    }
    
    private func enterFlow() {
        sessionStart = Date()
        lastFlowEntry = Date()
        
        // Trigger flow optimizations
        FlowOptimizer.shared.enterFlowMode()
        
        print("🌊 Entering FLOW state!")
    }
    
    func endSession() {
        if let start = sessionStart {
            let duration = Date().timeIntervalSince(start)
            print("📊 Flow session ended: \(Int(duration/60)) minutes, \(interruptions) interruptions")
        }
        
        sessionStart = nil
        FlowOptimizer.shared.exitFlowMode()
    }
}

enum FlowState: String, CaseIterable {
    case distracted = "😵 Distracted"
    case neutral = "😐 Neutral"
    case focused = "🎯 Focused"
    case flow = "🌊 FLOW"
    
    var color: String {
        switch self {
        case .distracted: return "🔴"
        case .neutral: return "⚪️"
        case .focused: return "🟡"
        case .flow: return "🟢"
        }
    }
}

// MARK: - Input Metrics
struct InputMetrics {
    let typingWPM: Double
    let typingConsistency: Double // 0-1, how consistent the rhythm is
    let mouseFluidity: Double // 0-1, smooth vs jerky movements
    let appSwitchesPerMinute: Double
    let timeSinceLastInput: TimeInterval
}

// MARK: - Input Tracker
@MainActor
final class InputTracker {
    private var keystrokeTimes: [Date] = []
    private var lastAppSwitch: Date?
    private var appSwitchCount = 0
    private var lastMousePosition: NSPoint?
    private var mouseMovementSamples: [Double] = []
    private var lastInputTime = Date()
    
    func recordKeystroke() {
        keystrokeTimes.append(Date())
        lastInputTime = Date()
        
        // Keep only last 60 seconds
        keystrokeTimes.removeAll { Date().timeIntervalSince($0) > 60 }
    }
    
    func recordMouseMove(position: NSPoint) {
        if let last = lastMousePosition {
            let distance = hypot(position.x - last.x, position.y - last.y)
            mouseMovementSamples.append(distance)
        }
        lastMousePosition = position
        lastInputTime = Date()
        
        // Keep only recent samples
        if mouseMovementSamples.count > 100 {
            mouseMovementSamples.removeFirst()
        }
    }
    
    func recordAppSwitch() {
        appSwitchCount += 1
        lastAppSwitch = Date()
        lastInputTime = Date()
    }
    
    func getMetrics() -> InputMetrics {
        // Calculate WPM
        let wpm = Double(keystrokeTimes.count) / 5.0 // rough estimate
        
        // Calculate typing consistency (standard deviation of intervals)
        var consistency: Double = 0
        if keystrokeTimes.count > 2 {
            var intervals: [TimeInterval] = []
            for i in 1..<keystrokeTimes.count {
                intervals.append(keystrokeTimes[i].timeIntervalSince(keystrokeTimes[i-1]))
            }
            let mean = intervals.reduce(0, +) / Double(intervals.count)
            let variance = intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count)
            let stdDev = sqrt(variance)
            consistency = 1.0 / (1.0 + stdDev) // Higher = more consistent
        }
        
        // Calculate mouse fluidity
        var fluidity: Double = 0
        if mouseMovementSamples.count > 10 {
            let mean = mouseMovementSamples.reduce(0, +) / Double(mouseMovementSamples.count)
            let variance = mouseMovementSamples.map { pow($0 - mean, 2) }.reduce(0, +) / Double(mouseMovementSamples.count)
            // Lower variance = more fluid (consistent speed)
            fluidity = 1.0 / (1.0 + variance / 1000)
        }
        
        // App switches per minute
        let switchesPerMin = Double(appSwitchCount) * (60.0 / max(Date().timeIntervalSince(lastAppSwitch ?? Date()), 1))
        
        // Reset counter periodically
        if Date().timeIntervalSince(lastAppSwitch ?? Date()) > 60 {
            appSwitchCount = 0
        }
        
        return InputMetrics(
            typingWPM: wpm,
            typingConsistency: min(consistency, 1.0),
            mouseFluidity: min(fluidity, 1.0),
            appSwitchesPerMinute: switchesPerMin,
            timeSinceLastInput: Date().timeIntervalSince(lastInputTime)
        )
    }
}

// MARK: - Flow Optimizer
@MainActor
final class FlowOptimizer {
    static let shared = FlowOptimizer()
    
    func enterFlowMode() {
        // Enable Do Not Disturb
        setDoNotDisturb(true)
        
        // Post notification for other apps
        NotificationCenter.default.post(name: .enteringFlowState, object: nil)
        
        print("🔇 DND enabled, notifications suppressed")
    }
    
    func exitFlowMode() {
        setDoNotDisturb(false)
        NotificationCenter.default.post(name: .exitingFlowState, object: nil)
        print("🔔 DND disabled")
    }
    
    private func setDoNotDisturb(_ enabled: Bool) {
        // Use macOS control center to toggle DND
        // This is a simplified version - real implementation would use private APIs or AppleScript
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = [
            "-e",
            """
            tell application "System Events"
                tell application process "Control Center"
                    click menu bar item "Control Center" of menu bar 1
                    delay 0.5
                    click checkbox "Do Not Disturb" of group 1 of window "Control Center"
                    key code 53 -- Escape key
                end tell
            end tell
            """
        ]
        try? task.run()
    }
}

extension Notification.Name {
    static let enteringFlowState = Notification.Name("FlowStateEntering")
    static let exitingFlowState = Notification.Name("FlowStateExiting")
}

// MARK: - Main
@main
struct FlowStateApp {
    static func main() async {
        let detector = FlowDetector()
        
        print("🌊 FlowState started. Monitoring your flow...")
        print("Press Enter to exit")
        
        // Keep running
        _ = readLine()
        
        detector.endSession()
    }
}
