# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AiMessage is a macOS application for analyzing iMessage data using local AI processing. The app imports message exports, analyzes them with Apple Foundation Models (privacy-focused), and generates insights including sentiment analysis, topic detection, and conversation statistics.

**Key Privacy Principle**: All data processing happens locally on-device. No data is sent to external services.

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
│   └── Preview Content/        # SwiftUI preview assets
├── CLAUDE.md                   # This file
└── README.md                   # Project documentation
```

## Architecture Overview

### Current Implementation
The project is currently a minimal SwiftUI macOS app with three main tabs:
1. **Import Tab**: File import interface (placeholder)
2. **Analysis Tab**: AI processing display (placeholder)  
3. **Statistics Tab**: Results and charts (placeholder)

### Planned Architecture

**Models Layer** (to be added)
- `Message.swift` - Core message data structure
- `AnalysisResult.swift` - AI analysis results and insights

**Services Layer** (to be added)
- `FileImporter.swift` - JSON/CSV parsing with multiple format support
- `LLMService.swift` - Apple Foundation Models integration
- `AnalyticsEngine.swift` - Analysis pipeline orchestration

**Views Layer** (expand current)
- `FileInputView.swift` - Drag & drop file import with validation
- `AnalysisView.swift` - AI processing progress and results display
- `StatsView.swift` - Charts and statistics dashboard

## Development Next Steps

### Immediate Tasks
1. **Add file import functionality**
   - Implement drag & drop support
   - Add file picker dialog
   - Support JSON and CSV formats

2. **Create data models**
   - Message structure with privacy-safe fields
   - Analysis result models
   - Conversation insights structure

3. **Integrate Apple Foundation Models**
   - Add Foundation Models framework
   - Implement local sentiment analysis
   - Add topic extraction capabilities

4. **Build analysis pipeline**
   - Message processing workflow
   - Progress reporting
   - Result aggregation

5. **Add visualization**
   - Swift Charts integration
   - Statistics dashboard
   - Export capabilities

### File Format Support (Planned)
- **JSON**: Direct `Message` array or wrapper with metadata
- **CSV**: Flexible column mapping (text/message, sender/from, timestamp/date)
- **Timestamp parsing**: Multiple formats including ISO8601, Unix timestamps

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

### Export Documentation & Security

### User Export Guides
- **SECURE_IMESSAGE_EXPORT.md** - Comprehensive manual for exporting iMessage data using native macOS tools only
- **export_scripts/** - Automated shell scripts for common export scenarios  
- **sample_data/** - Example CSV files showing expected data format

### Export Script Usage
```bash
# Make scripts executable (first time only)
chmod +x export_scripts/*.sh

# Export all messages
./export_scripts/export_all_messages.sh

# Export messages with specific contact
./export_scripts/export_contact_messages.sh
```

### Security Principles for Export
- **Native tools only** - Uses macOS built-in SQLite3, no third-party software
- **Local processing** - All data manipulation happens on user's machine
- **Secure cleanup** - Scripts automatically remove temporary database copies
- **Transparent operations** - All commands visible and auditable

### Expected CSV Format
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

1. **Open the project**: `open AiMessage.xcodeproj`
2. **Build and run**: The project should compile immediately
3. **Start development**: Begin by implementing file import functionality
4. **Add features**: Follow the planned architecture to add analysis capabilities

## Dependencies

### System Frameworks
- SwiftUI (UI framework)
- Foundation (Core data structures)
- UniformTypeIdentifiers (File type handling)
- Foundation Models (Apple's local AI - to be added)

### macOS Version Support
- **Minimum**: macOS 14.0
- **Recommended**: macOS 15.0+ (for latest Foundation Models features)

## Common Development Patterns

### Adding New Views
1. Create SwiftUI view in appropriate group
2. Follow existing naming conventions
3. Use proper preview providers for development
4. Integrate with tab navigation if needed

### Error Handling
- Use proper Swift error handling with descriptive messages
- Show user-friendly alerts for file import issues
- Gracefully handle analysis failures
- Provide actionable guidance in error messages