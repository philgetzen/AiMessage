# AiMessage

A privacy-focused macOS application for analyzing iMessage data using local AI processing.

## Features

- **🔒 Local AI Processing** - All analysis happens on-device using Apple Foundation Models
- **📁 Secure Message Import** - Support for CSV exports from native macOS tools only
- **🧠 Sentiment Analysis** - Understand the emotional tone of conversations
- **🏷️ Topic Detection** - Identify key themes and subjects
- **📊 Statistical Insights** - Comprehensive conversation analytics
- **📈 Interactive Charts** - Visual data representation using Swift Charts
- **💾 Export Capabilities** - Save analysis results and generate reports
- **🛡️ Privacy First** - No external dependencies, no data transmission

## Privacy & Security

AiMessage is designed with privacy as the core principle:
- ✅ **100% Local Processing** - Your data never leaves your Mac
- ✅ **No External Services** - No APIs, no cloud processing, no data transmission
- ✅ **Native Tools Only** - Uses Apple's built-in frameworks and Foundation Models
- ✅ **Sandboxed Application** - Minimal permissions, maximum security
- ✅ **Secure Export Process** - Instructions use only native macOS command-line tools

## Getting Started

### Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for development)
- Apple Silicon or Intel Mac

### Installation

1. Clone this repository
2. Open `AiMessage.xcodeproj` in Xcode
3. Build and run the project

## Exporting Your iMessage Data

**Important**: AiMessage requires you to export your iMessage data first. We provide secure, native-only methods to do this.

### 🔒 Secure Export Methods

We provide two comprehensive guides for exporting your iMessage data using **only native macOS tools**:

#### Option 1: Detailed Manual Guide
See **[SECURE_IMESSAGE_EXPORT.md](SECURE_IMESSAGE_EXPORT.md)** for complete step-by-step instructions using SQLite3 command line.

#### Option 2: Automated Scripts
Use our pre-built shell scripts in the `export_scripts/` directory:

```bash
# Export all messages
./export_scripts/export_all_messages.sh

# Export messages with specific contact
./export_scripts/export_contact_messages.sh
```

### Why Native Tools Only?

- **🛡️ Maximum Security** - No third-party software with unknown data practices
- **🔍 Full Transparency** - You can see exactly what commands are executed
- **⚡ Apple Optimized** - Uses Apple's own SQLite implementation
- **🚫 Zero Dependencies** - No external downloads or installations required

### Supported Export Formats

#### CSV Format (Recommended)
```csv
timestamp,text,sender,isFromMe,chatIdentifier
"2024-06-19 14:30:15","Hello!","Me",true,"direct"
"2024-06-19 14:32:42","Hi there!","+1234567890",false,"direct"
```

See `sample_data/` directory for example files.

## Using AiMessage

### 1. Import Messages
1. Export your iMessage data using our secure guides
2. Open AiMessage
3. Drag and drop your CSV file into the Import tab

### 2. Start Analysis
The app will process your messages using local AI to generate:
- Sentiment analysis for each message
- Topic extraction and categorization  
- Conversation pattern insights
- Statistical summaries

### 3. View Results
Explore your analysis in the Statistics tab with:
- Interactive charts and visualizations
- Participant statistics
- Timeline analysis
- Topic frequency charts

### 4. Export Insights
Save your analysis results for future reference or sharing.

## Development

See [CLAUDE.md](CLAUDE.md) for detailed development information including:
- Project architecture
- Build commands
- Testing procedures
- Contributing guidelines

## Technical Stack

- **SwiftUI** - Modern macOS interface
- **Apple Foundation Models** - Local AI processing (coming soon)
- **Swift Charts** - Data visualization
- **NaturalLanguage** - Text processing (transitional)
- **Core ML** - Machine learning framework
- **SQLite3** - For export processing (user-side)

## Project Status

- [x] Basic project structure and UI
- [x] Secure export documentation and scripts
- [x] File import system design
- [x] Message data models
- [x] SwiftUI interface with tab navigation
- [ ] Apple Foundation Models integration
- [ ] Complete file import functionality
- [ ] Local sentiment analysis implementation
- [ ] Topic detection and categorization
- [ ] Statistics dashboard with charts
- [ ] Export and reporting features

## Security & Privacy Details

### What We DON'T Do
- ❌ Connect to the internet for processing
- ❌ Send data to external APIs or services
- ❌ Store data in cloud services
- ❌ Use third-party analytics or tracking
- ❌ Require account creation or authentication

### What We DO
- ✅ Process everything locally on your Mac
- ✅ Use Apple's own AI frameworks
- ✅ Provide transparent, auditable export process
- ✅ Minimize app permissions to essential only
- ✅ Open source codebase for full transparency

## Contributing

We welcome contributions that maintain our privacy-first approach:

1. Fork the repository
2. Create a feature branch
3. Ensure all processing remains local
4. Test thoroughly with the provided sample data
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

- **Export Issues**: See [SECURE_IMESSAGE_EXPORT.md](SECURE_IMESSAGE_EXPORT.md) troubleshooting section
- **App Issues**: Open an issue on GitHub
- **Privacy Questions**: Review our privacy commitments above

## Acknowledgments

- Apple for providing Foundation Models and privacy-focused AI frameworks
- The open-source community for privacy-first development practices
- Users who prioritize digital privacy and local data processing