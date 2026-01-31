import SwiftUI
import AppKit

// MARK: - App Entry Point
@main
struct MindGroweeMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let viewModel = MenuBarViewModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else { return }
        
        button.image = NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "MindGrowee")
        button.action = #selector(togglePopover)
        button.target = self
        
        // Create popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView(viewModel: viewModel))
        self.popover = popover
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button,
              let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}

// MARK: - View Model
@MainActor
@Observable
final class MenuBarViewModel {
    var todayHabits: [Habit] = []
    var completedCount: Int = 0
    var currentStreak: Int = 0
    var isLoading = false
    
    init() {
        loadData()
    }
    
    func loadData() {
        isLoading = true
        
        // TODO: Load from iCloud / local storage
        // Mock data for now
        todayHabits = [
            Habit(id: "1", name: "Meditation", icon: "🧘", isCompleted: true),
            Habit(id: "2", name: "Exercise", icon: "💪", isCompleted: false),
            Habit(id: "3", name: "Read", icon: "📚", isCompleted: false),
        ]
        completedCount = 1
        currentStreak = 12
        
        isLoading = false
    }
    
    func toggleHabit(_ habit: Habit) {
        if let index = todayHabits.firstIndex(where: { $0.id == habit.id }) {
            todayHabits[index].isCompleted.toggle()
            completedCount = todayHabits.filter(\.isCompleted).count
            
            // TODO: Sync to iCloud
        }
    }
    
    func quickJournalEntry() {
        // TODO: Open quick journal modal
        print("Quick journal entry requested")
    }
}

// MARK: - Models
struct Habit: Identifiable {
    let id: String
    let name: String
    let icon: String
    var isCompleted: Bool
}

// MARK: - Views
struct MenuBarView: View {
    let viewModel: MenuBarViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(streak: viewModel.currentStreak)
            
            Divider()
            
            // Habits List
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.todayHabits) { habit in
                        HabitRowView(habit: habit) {
                            viewModel.toggleHabit(habit)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 200)
            
            Divider()
            
            // Actions
            ActionButtonsView(
                onJournal: { viewModel.quickJournalEntry() },
                completed: viewModel.completedCount,
                total: viewModel.todayHabits.count
            )
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
    }
}

struct HeaderView: View {
    let streak: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("MindGrowee")
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(streak) day streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                // Open main app
                NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/Applications/MindGrowee.app"), configuration: NSWorkspace.OpenConfiguration())
            }) {
                Image(systemName: "arrow.up.forward.app")
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }
}

struct HabitRowView: View {
    let habit: Habit
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(habit.icon)
                    .font(.title3)
                
                Text(habit.name)
                    .foregroundStyle(habit.isCompleted ? .secondary : .primary)
                    .strikethrough(habit.isCompleted)
                
                Spacer()
                
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(habit.isCompleted ? .green : .secondary)
                    .imageScale(.large)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(habit.isCompleted ? Color.green.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ActionButtonsView: View {
    let onJournal: () -> Void
    let completed: Int
    let total: Int
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(.linear)
            
            HStack {
                Button(action: onJournal) {
                    Label("Quick Journal", systemImage: "pencil")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Spacer()
                
                Text("\(completed)/\(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
