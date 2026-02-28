# Transly

A native macOS menu bar translation app built with SwiftUI.

## Features

### Four Translation Modes

| Mode | Shortcut | Description |
|------|----------|-------------|
| Input Translation | `⌥A` | Type text to translate |
| Selection Translation | `⌥D` | Translate selected text |
| Screenshot Translation (OCR) | `⌥S` | Capture screen region and translate recognized text |
| Clipboard Translation | `⌥V` | Translate clipboard content |

### Core Features

- **Multiple Translation Services** - Compare results from different providers
- **OCR Text Recognition** - Using Apple Vision framework
- **Translation History** - Save and review past translations
- **Auto Language Detection** - Automatically detect source language
- **Always on Top** - Keep translation window above other windows
- **Auto Copy** - Automatically copy translation results

### Supported Translation Services

| Service | Features | Configuration |
|---------|----------|---------------|
| Google Translate | Free, no API key required | None |
| Apple Translation | Native, offline support (macOS 15+) | Download language packs |
| DeepSeek | High-quality AI translation | API Key |
| OpenAI | Advanced language understanding, custom endpoint | API Key + Endpoint + Model |
| Ollama | Fully local, privacy-focused | Endpoint + Model |

### Supported Languages

Auto-detection, Chinese, English, Japanese, Korean, French, German, Spanish, Russian, Portuguese, Italian

## Requirements

- macOS 14.0 or later
- Xcode 16+ (for building from source)

## Installation

### Download Release

Download the latest DMG from [Releases](../../releases).

### Build from Source

```bash
# Clone the repository
git clone https://github.com/icuxika/Transly.git
cd Transly

# Install Tuist (if not installed)
brew install tuist

# Generate Xcode project
tuist generate

# Build release version
./build-release.sh

# Build and install to /Applications
./build-release.sh --install
```

### Create DMG Package

```bash
# Using hdiutil (built-in)
./package.sh

# Using create-dmg (requires: brew install create-dmg)
./package-dmg.sh
```

## Permissions

Transly requires the following system permissions:

1. **Accessibility** - For selection translation to get selected text
2. **Screen Recording** - For OCR translation to capture screen content

Grant permissions in **System Settings → Privacy & Security**.

## Tech Stack

- **Language**: Swift 6.0
- **UI Framework**: SwiftUI + AppKit
- **Build Tool**: [Tuist](https://tuist.io/)
- **No third-party dependencies** - Pure native frameworks

### System Frameworks

- `Vision` - OCR text recognition
- `NaturalLanguage` - Language detection
- `Translation` - Apple system translation (macOS 15+)
- `Carbon` - Global hotkey registration

## Project Structure

```
Transly/
├── Transly/
│   ├── Resources/
│   │   └── Assets.xcassets/
│   └── Sources/
│       ├── Core/                    # Core functionality
│       │   ├── OCR/                 # OCR service & screenshot capture
│       │   ├── Selection/           # Text selection service
│       │   └── HotkeyManager.swift  # Global hotkey management
│       ├── Models/                  # Data models
│       ├── Services/                # Service layer
│       │   └── Providers/           # Translation service providers
│       ├── UI/                      # User interface
│       │   ├── Components/
│       │   └── Views/
│       ├── ViewModels/              # View models
│       └── TranslyApp.swift         # App entry point
├── Project.swift                    # Tuist project configuration
├── build-release.sh                 # Release build script
├── package.sh                       # DMG packaging script (hdiutil)
└── package-dmg.sh                   # DMG packaging script (create-dmg)
```

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
