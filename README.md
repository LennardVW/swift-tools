# Swift macOS Tools - Complete Collection

10 native Swift 6 applications for macOS Tahoe (15.0+) to boost productivity.

## The 10 Projects

### 1. [FocusShield](https://github.com/LennardVW/FocusShield) 🛡️
Complete distraction blocker with website/app blocking and Do Not Disturb
```bash
git clone https://github.com/LennardVW/FocusShield.git
cd FocusShield && swift build && swift run
```

### 2. [AutoGit](https://github.com/LennardVW/AutoGit) 🤖
Automatic commit message generation from git diffs
```bash
git clone https://github.com/LennardVW/AutoGit.git
cd AutoGit && swift build -c release && cp .build/release/autogit /usr/local/bin/
```

### 3. [ScreenMemory](https://github.com/LennardVW/ScreenMemory) 📸
Searchable screenshot history with OCR and context
```bash
git clone https://github.com/LennardVW/ScreenMemory.git
cd ScreenMemory && swift run
```

### 4. [VoiceCoder](https://github.com/LennardVW/VoiceCoder) 🎤
Voice to code using Whisper API - speak, get code
```bash
git clone https://github.com/LennardVW/VoiceCoder.git
cd VoiceCoder && swift run
```

### 5. [SmartDND](https://github.com/LennardVW/SmartDND) 🔕
Context-aware Do Not Disturb (calendar, app, time-based)
```bash
git clone https://github.com/LennardVW/SmartDND.git
cd SmartDND && swift run
```

### 6. [WindowWarden](https://github.com/LennardVW/WindowWarden) 🪟
Automatic window management with presets (coding, writing, meeting)
```bash
git clone https://github.com/LennardVW/WindowWarden.git
cd WindowWarden && swift run
```

### 7. [DeepSearch](https://github.com/LennardVW/DeepSearch) 🔍
Semantic file search - find by meaning, not just filename
```bash
git clone https://github.com/LennardVW/DeepSearch.git
cd DeepSearch && swift run
```

### 8. [CodeSnippetPro](https://github.com/LennardVW/CodeSnippetPro) 💻
Smart code snippet management with search and copy
```bash
git clone https://github.com/LennardVW/CodeSnippetPro.git
cd CodeSnippetPro && swift run
```

### 9. [TodoSniper](https://github.com/LennardVW/TodoSniper) 🎯
Create tasks from any text selection with global hotkey
```bash
git clone https://github.com/LennardVW/TodoSniper.git
cd TodoSniper && swift run
```

### 10. [PDFBrain](https://github.com/LennardVW/PDFBrain) 📚
Searchable PDF collection with AI-powered text extraction
```bash
git clone https://github.com/LennardVW/PDFBrain.git
cd PDFBrain && swift run
```

## Requirements
- macOS 15.0+ (Tahoe)
- Swift 6.0+
- Xcode 16+

## Quick Install All
```bash
mkdir ~/swift-tools && cd ~/swift-tools
for repo in FocusShield AutoGit ScreenMemory VoiceCoder SmartDND WindowWarden DeepSearch CodeSnippetPro TodoSniper PDFBrain; do
  git clone https://github.com/LennardVW/$repo.git
  cd $repo && swift build -c release && cd ..
done
```

## Features
All apps use:
- **Swift 6** with strict concurrency
- **Native macOS APIs** (AppKit, Foundation)
- **No external dependencies** (pure Swift)
- **macOS Tahoe compatibility**
- **CLI interface** for automation

## License
MIT - Use, modify, sell freely.
