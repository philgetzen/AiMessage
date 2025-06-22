# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AiMessage is a macOS application for analyzing iMessage data using local AI processing. The app imports message exports, analyzes them with Apple Foundation Models (privacy-focused), and generates insights including sentiment analysis, topic detection, and conversation statistics.

**Key Privacy Principle**: All data processing happens locally on-device. No data is sent to external services.

## Git Repository

**Repository**: https://github.com/philgetzen/AiMessage (private)
- Initialized with all project files
- Ready for collaborative development

## Development Commands

### Building and Running
```bash
# Open project in Xcode
open AiMessage.xcodeproj

# Build from command line
xcodebuild -project AiMessage.xcodeproj -scheme AiMessage build

# Run the app
xcodebuild -project AiMessage.xcodeproj -scheme AiMessage -destination 'platform=macOS' run
```

### Project Structure

```
AiMessage/
├── AiMessage.xcodeproj/         # Xcode project file
├── AiMessage/                   # Main app source
│   ├── AiMessageApp.swift      # App entry point
│   ├── ContentView.swift       # Main UI with tab navigation
│   ├── Assets.xcassets/        # App icons and colors
│   ├── AiMessage.entitlements  # Sandbox permissions
│   ├── Models/                 # Data models
│   │   ├── Message.swift       # Core message structure
│   │   └── AiMessageDocument.swift # Document handling
│   ├── Services/               # Business logic
│   │   └── FileImporter.swift  # File import handling
│   ├── Views/                  # UI components
│   │   ├── DropZoneView.swift  # File drop interface
│   │   └── ExportInstructionsView.swift # Help content
│   └── Preview Content/        # SwiftUI preview assets
├── export_scripts/             # User data export tools
│   ├── export_all_messages.sh
│   ├── export_contact_messages.sh
│   └── chat_db_to_csv.sh
├── sample_data/                # Example data formats
├── CLAUDE.md                   # This file
├── README.md                   # Project documentation
├── SECURE_IMESSAGE_EXPORT.md   # Export guide
└── Package.swift               # Swift package (dual structure)
```

## Architecture Overview

### Current Implementation
The project uses a simplified, user-friendly approach:
1. **Import Tab**: Two-step Terminal export → CSV import flow
2. **Analysis Tab**: AI processing display (placeholder ready for implementation)
3. **Insights Tab**: Statistical overview and participant breakdown (implemented)

### Implemented Components

**Models Layer** ✅
- `Message.swift` - Core message data structure with privacy-safe fields
- `AiMessageDocument.swift` - Document-based app support

**Services Layer** ✅ (simplified)
- `FileImporter.swift` - CSV parsing only (removed unreliable database import)
- LLM integration - planned for Apple Foundation Models

**Views Layer** ✅ (simplified)
- `ImportView.swift` - Two-step export/import flow with clear guidance
- `ExportInstructionsView.swift` - User guidance for data export
- `AnalysisView.swift` - Placeholder for AI analysis
- `InsightsView.swift` - Statistical overview and visualizations

## Development Next Steps

### Priority Tasks
1. **Complete analysis pipeline**
   - Integrate Apple Foundation Models framework
   - Implement local sentiment analysis and topic extraction
   - Add message processing workflow with progress reporting

2. **Build visualization dashboard**
   - Implement Swift Charts for statistics display
   - Create interactive data views
   - Add export capabilities for analysis results

3. **Enhance analysis capabilities**
   - Focus on Apple Foundation Models integration
   - Build out the analysis pipeline
   - Create meaningful visualizations from analyzed data

### File Format Support
- **CSV**: ✅ Implemented with flexible column mapping
  - Supports text/message, sender/from, timestamp/date columns
  - Handles various timestamp formats including ISO8601, Unix timestamps
- **JSON**: 🔲 Planned - Direct `Message` array or wrapper with metadata

## Technical Decisions

### Privacy & Security
- Sandboxed app with minimal file access permissions
- All AI processing local using Apple Foundation Models
- No network permissions or external service calls
- User-selected file access only

### UI/UX Patterns
- Tab-based navigation for clear workflow progression
- Native macOS design with SwiftUI
- Hidden title bar for modern appearance
- Minimum window size: 800x600

### Data Export System ✅

**Complete export documentation and tooling for secure iMessage data extraction:**

- **SECURE_IMESSAGE_EXPORT.md** - Comprehensive manual using native macOS tools only
- **export_scripts/** - Automated shell scripts for common scenarios
- **sample_data/** - Example CSV files showing expected formats

#### Export Script Usage
```bash
# Make scripts executable (first time only)
chmod +x export_scripts/*.sh

# Export all messages
./export_scripts/export_all_messages.sh

# Export messages with specific contact
./export_scripts/export_contact_messages.sh

# Direct database conversion
./export_scripts/chat_db_to_csv.sh
```

#### Security Principles for Export ✅
- **Native tools only** - Uses macOS built-in SQLite3, no third-party software
- **Local processing** - All data manipulation happens on user's machine
- **Secure cleanup** - Scripts automatically remove temporary database copies
- **Transparent operations** - All commands visible and auditable

#### Supported CSV Format ✅
```csv
timestamp,text,sender,isFromMe,chatIdentifier
"2024-06-19 14:30:15","Hello!","Me",true,"direct"
"2024-06-19 14:32:42","Hi there!","+1234567890",false,"direct"
```

## Development Guidelines
- Use SwiftUI for all interface elements
- Follow Apple Human Interface Guidelines
- Implement proper error handling with user-friendly messages
- Use async/await for long-running operations
- Maintain separation of concerns (Models/Views/Services)
- **Privacy First**: Never add features that could compromise local-only processing

## Getting Started

1. **Clone repository**: `git clone https://github.com/philgetzen/AiMessage.git`
2. **Open project**: `open AiMessage.xcodeproj`
3. **Build and run**: The project compiles immediately with working file import
4. **Test with sample data**: Use files in `sample_data/` directory

## Dependencies

### System Frameworks ✅
- SwiftUI (UI framework) - implemented
- Foundation (Core data structures) - implemented  
- UniformTypeIdentifiers (File type handling) - implemented
- SQLite3 (Data parsing) - implemented
- Foundation Models (Apple's local AI) - to be added

### macOS Version Support
- **Minimum**: macOS 14.0 (verified working)
- **Recommended**: macOS 15.0+ (for latest Foundation Models features)
- **Current Development**: macOS 15.5

## Development Status Summary

### ✅ Completed
- **Project setup**: Xcode project with proper structure and build configuration
- **Git repository**: Private GitHub repo with all files committed
- **File import system**: CSV parsing with drag & drop interface
- **Data models**: Message structure with privacy-safe fields
- **Export tooling**: Complete shell scripts and documentation for secure data extraction
- **UI foundation**: Tab-based navigation with working import interface

### 🔲 Next Priorities
- **Apple Foundation Models integration**: Local AI processing pipeline
- **Analysis views**: Progress display and results presentation
- **Statistics dashboard**: Charts and insights visualization
- **JSON format support**: Additional file import capability

### 📁 Key Files for Development
- `AiMessage/Models/Message.swift` - Core data structure
- `AiMessage/Services/FileImporter.swift` - Simplified CSV import logic
- `AiMessage/Views/ImportView.swift` - Two-step import flow interface
- `AiMessage/ContentView.swift` - Main app navigation with auto-advance

The project is well-structured and ready for the next development phase focusing on AI analysis capabilities.