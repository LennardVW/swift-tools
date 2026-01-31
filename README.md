# Swift Projects for macOS Tahoe

Native Swift 6 Projekte für macOS 15+ (Tahoe).

## Projekte

### 1. MindGroweeMenuBar
Menu Bar App für MindGrowee - Quick Habit Check-In direkt aus der Menu Bar.

```bash
cd MindGroweeMenuBar
swift build
swift run
```

**Features:**
- Menu Bar Icon mit Streak-Anzeige
- Quick Habit Toggle
- Quick Journal Entry
- Öffnet Haupt-App

### 2. DevCLI
Developer CLI Tool für macOS.

```bash
cd DevCLI
swift build -c release
cp .build/release/devcli /usr/local/bin/

# Usage:
devcli json '{"key":"value"}'
devcli base64 encode "Hello"
devcli uuid --count 5
```

**Features:**
- JSON Format/Validate
- Base64 Encode/Decode
- UUID Generator
- Timestamp Converter

## Requirements
- macOS 15.0+ (Tahoe)
- Swift 6.0+
- Xcode 16+

## Installation

```bash
git clone <repo-url>
cd Swift

# Menu Bar App
cd MindGroweeMenuBar
swift build -c release
# .app Bundle erstellen für /Applications

# CLI Tool
cd DevCLI  
swift build -c release
sudo cp .build/release/devcli /usr/local/bin/
```

## Swift 6 Features Used
- `@MainActor` für UI
- `@Observable` (neu in SwiftUI)
- `async/await`
- Strict Concurrency Checking
- `.ultraThinMaterial` für macOS

## Todo
- [ ] iCloud Sync für MindGroweeMenuBar
- [ ] Weitere DevCLI Commands (JWT, Regex, etc.)
- [ ] SwiftData für lokale Speicherung
- [ ] Keyboard Shortcuts
