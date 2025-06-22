import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var fileImporter = FileImporter()
    
    var hasImportedData: Bool {
        !fileImporter.messages.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                StepFlowView(fileImporter: fileImporter, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "message.badge.filled.fill")
                        Text("Messages")
                    }
                    .tag(0)
                
                AnalysisView(fileImporter: fileImporter)
                    .tabItem {
                        Image(systemName: "brain")
                        Text("Analysis")
                    }
                    .tag(1)
                    .disabled(!hasImportedData)
                
                StatsView(fileImporter: fileImporter)
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Insights")
                    }
                    .tag(2)
                    .disabled(!hasImportedData)
            }
        }
        .frame(minWidth: 900, minHeight: 700)
    }
}

struct StepFlowView: View {
    @ObservedObject var fileImporter: FileImporter
    @Binding var selectedTab: Int
    @State private var currentStep: FlowStep = .importStep
    
    enum FlowStep {
        case importStep, process, analyze
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text("Import Your Messages")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Follow these steps to analyze your conversations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 60)
            
            // Three-card flow
            HStack(spacing: 24) {
                // Step 1: Import
                ImportCard(
                    fileImporter: fileImporter,
                    isActive: currentStep == .importStep || fileImporter.messages.isEmpty,
                    isCompleted: !fileImporter.messages.isEmpty,
                    onFileSelected: { accessMessagesData() },
                    onSelectDatabase: { selectMessagesDatabase() }
                )
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(fileImporter.messages.isEmpty ? .secondary : .accentColor)
                    .scaleEffect(fileImporter.messages.isEmpty ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: fileImporter.messages.isEmpty)
                
                // Step 2: Process
                ProcessCard(
                    fileImporter: fileImporter,
                    isActive: currentStep == .process || (fileImporter.importStatus == .loading),
                    isCompleted: {
                        if case .success = fileImporter.importStatus {
                            return true
                        }
                        return !fileImporter.messages.isEmpty
                    }()
                )
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(!fileImporter.messages.isEmpty ? .accentColor : .secondary)
                    .scaleEffect(!fileImporter.messages.isEmpty ? 1.0 : 0.8)
                    .opacity(!fileImporter.messages.isEmpty ? 1.0 : 0.6)
                    .animation(.easeInOut(duration: 0.3), value: fileImporter.messages.isEmpty)
                
                // Step 3: Analyze
                AnalyzeCard(
                    fileImporter: fileImporter,
                    isActive: currentStep == .analyze,
                    isEnabled: !fileImporter.messages.isEmpty,
                    onAnalyze: { selectedTab = 1 }
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: fileImporter.importStatus) { _, status in
            updateCurrentStep()
        }
        .onChange(of: fileImporter.messages.count) { _, _ in
            updateCurrentStep()
        }
    }
    
    private func updateCurrentStep() {
        switch fileImporter.importStatus {
        case .loading:
            currentStep = .process
        case .success(_):
            currentStep = .analyze
        case .error(_):
            currentStep = .importStep
        case .idle:
            if !fileImporter.messages.isEmpty {
                currentStep = .analyze
            } else {
                currentStep = .importStep
            }
        }
    }
    
    private func accessMessagesData() {
        let workspace = NSWorkspace.shared
        
        // Always open Downloads folder first
        if let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            workspace.open(downloadsURL)
        }
        
        // Always show helpful instructions
        showDirectoryInstructions()
    }
    
    private func showDirectoryInstructions() {
        let alert = NSAlert()
        alert.messageText = "Manual Navigation Required"
        alert.informativeText = """
        To access your Messages data:
        
        1. Open Finder
        2. Press Cmd+Shift+G (Go to Folder)
        3. Paste this path: /Users/\(NSUserName())/Library/Messages
        4. Copy chat.db to your Downloads folder
        5. Return to AiMessage and select the file
        """
        alert.addButton(withTitle: "Copy Path")
        alert.addButton(withTitle: "Done")
        
        repeat {
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Copy path to clipboard and continue showing dialog
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString("/Users/\(NSUserName())/Library/Messages", forType: .string)
                // Don't break - keep the dialog open
            } else {
                // User clicked "Done" - exit the loop
                break
            }
        } while true
    }
    
    private func fallbackDirectoryOpen() {
        let workspace = NSWorkspace.shared
        let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        workspace.open(downloadsPath)
    }
    
    private func selectMessagesDatabase() {
        let openPanel = NSOpenPanel()
        
        // Start in Downloads directory since that's where users should copy the file
        let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        openPanel.directoryURL = downloadsPath
        openPanel.title = "Select Messages Database"
        openPanel.message = "Choose chat.db from your Downloads folder"
        openPanel.prompt = "Select"
        openPanel.allowedContentTypes = [UTType(filenameExtension: "db")!]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowsOtherFileTypes = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            fileImporter.importFromDatabase(url)
        }
    }
}

// MARK: - Step Cards

struct ImportCard: View {
    @ObservedObject var fileImporter: FileImporter
    let isActive: Bool
    let isCompleted: Bool
    let onFileSelected: () -> Void
    let onSelectDatabase: () -> Void
    
    private func selectCSVFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Messages CSV"
        openPanel.message = "Choose an exported messages CSV file"
        openPanel.prompt = "Select"
        openPanel.allowedContentTypes = [UTType(filenameExtension: "csv")!]
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            fileImporter.importMessages(from: url)
        }
    }
    
    // Database conversion removed - direct users to manual export
    
    // Database conversion removed - direct users to manual export
    
    // Conversion progress methods removed
    
    // Conversion success method removed
    
    private func showConversionError() {
        let alert = NSAlert()
        alert.messageText = "Automatic Conversion Not Available"
        alert.informativeText = """
        Due to macOS security restrictions, automatic database conversion isn't reliable.
        
        • The Messages database is protected by system security
        • Sandbox restrictions prevent direct access
        
        SOLUTION: Use the reliable terminal export method instead.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Show Export Instructions")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            showExportInstructions()
        }
    }
    
    private func showExportInstructions() {
        let alert = NSAlert()
        alert.messageText = "Export Your Messages Data"
        alert.informativeText = """
        Follow these simple steps:
        
        ❶ First, quit the Messages app completely
        
        ❷ Open Terminal (press Cmd+Space, type "Terminal")
        
        ❸ Copy and paste this command:
        
        sqlite3 -header -csv ~/Library/Messages/chat.db "SELECT datetime(message.date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime') as timestamp, message.text, CASE WHEN message.is_from_me = 1 THEN 'Me' ELSE COALESCE(handle.id, 'Unknown') END as sender, CASE WHEN message.is_from_me = 1 THEN 'true' ELSE 'false' END as isFromMe, 'direct' as chatIdentifier FROM message LEFT JOIN handle ON message.handle_id = handle.ROWID WHERE message.text IS NOT NULL AND message.text != '' ORDER BY message.date;" > ~/Downloads/messages.csv
        
        ❹ Press Enter and wait for it to complete
        
        ❺ Come back here and click "Import Existing CSV"
        
        Your messages.csv file will be saved to Downloads.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Copy Command & Open Terminal")
        alert.addButton(withTitle: "Just Copy Command")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Copy command and open Terminal
            let command = "sqlite3 -header -csv ~/Library/Messages/chat.db \"SELECT datetime(message.date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime') as timestamp, message.text, CASE WHEN message.is_from_me = 1 THEN 'Me' ELSE COALESCE(handle.id, 'Unknown') END as sender, CASE WHEN message.is_from_me = 1 THEN 'true' ELSE 'false' END as isFromMe, 'direct' as chatIdentifier FROM message LEFT JOIN handle ON message.handle_id = handle.ROWID WHERE message.text IS NOT NULL AND message.text != '' ORDER BY message.date;\" > ~/Downloads/messages.csv"
            
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(command, forType: .string)
            
            // Open Terminal app
            NSWorkspace.shared.launchApplication("Terminal")
        } else if response == .alertSecondButtonReturn {
            // Just copy the command
            let command = "sqlite3 -header -csv ~/Library/Messages/chat.db \"SELECT datetime(message.date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime') as timestamp, message.text, CASE WHEN message.is_from_me = 1 THEN 'Me' ELSE COALESCE(handle.id, 'Unknown') END as sender, CASE WHEN message.is_from_me = 1 THEN 'true' ELSE 'false' END as isFromMe, 'direct' as chatIdentifier FROM message LEFT JOIN handle ON message.handle_id = handle.ROWID WHERE message.text IS NOT NULL AND message.text != '' ORDER BY message.date;\" > ~/Downloads/messages.csv"
            
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(command, forType: .string)
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // Step indicator
                HStack {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Color.green : (isActive ? Color.blue : Color.gray.opacity(0.3)))
                            .frame(width: 36, height: 36)
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .scaleEffect(1.2)
                        } else {
                            Text("1")
                                .foregroundColor(isActive ? .white : .gray)
                                .fontWeight(.bold)
                        }
                    }
                    
                    Spacer()
                }
                
                // Content
                VStack(spacing: 16) {
                    Image(systemName: isCompleted ? "doc.badge.checkmark" : "doc.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(isCompleted ? .green : (isActive ? .blue : .secondary))
                        .symbolEffect(.bounce, value: isCompleted)
                    
                    VStack(spacing: 8) {
                        Text("Import Messages")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isActive ? .primary : .secondary)
                        
                        if isCompleted {
                            Text("\(fileImporter.messages.count) messages loaded")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("Most users need to export first")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    if !isCompleted {
                        VStack(spacing: 12) {
                            // Primary action - Terminal export
                            Button(action: { showExportInstructions() }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "terminal")
                                        .font(.title3)
                                    Text("Export from Terminal")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                            
                            Text("Recommended: Export your Messages data using Terminal (most reliable)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                            
                            // Secondary option - Import existing CSV
                            Button(action: { selectCSVFile() }) {
                                HStack {
                                    Image(systemName: "doc.text")
                                    Text("Import Existing CSV")
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    } else {
                        Button(action: onFileSelected) {
                            Text("Load Different")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .frame(width: 200, height: 300)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
            )
            .animation(.easeInOut(duration: 0.3), value: isActive)
            .animation(.easeInOut(duration: 0.3), value: isCompleted)
            .scaleEffect(isActive ? 1.02 : 1.0)
            .shadow(color: isActive ? .accentColor.opacity(0.2) : .clear, radius: 8)
            
            // Drag & Drop overlay - embedded for now
            DropZoneOverlay(fileImporter: fileImporter)
        }
    }
}

struct ProcessCard: View {
    @ObservedObject var fileImporter: FileImporter
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Step indicator
            HStack {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : (isActive ? Color.blue : Color.gray.opacity(0.3)))
                        .frame(width: 36, height: 36)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .scaleEffect(1.2)
                    } else {
                        Text("2")
                            .foregroundColor(isActive ? .white : .gray)
                            .fontWeight(.bold)
                    }
                }
                
                Spacer()
            }
            
            // Content
            VStack(spacing: 16) {
                if isActive {
                    if case .loading = fileImporter.importStatus {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: isCompleted ? "gearshape.2.fill" : "gearshape.2")
                            .font(.system(size: 48))
                            .foregroundColor(isCompleted ? .green : (isActive ? .blue : .secondary))
                            .symbolEffect(.bounce, value: isCompleted)
                    }
                } else {
                    Image(systemName: isCompleted ? "gearshape.2.fill" : "gearshape.2")
                        .font(.system(size: 48))
                        .foregroundColor(isCompleted ? .green : (isActive ? .blue : .secondary))
                        .symbolEffect(.bounce, value: isCompleted)
                }
                
                VStack(spacing: 8) {
                    Text("Process Data")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isActive ? .primary : .secondary)
                    
                    switch fileImporter.importStatus {
                    case .loading:
                        Text("Processing messages...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    case .success(let count):
                        Text("Loaded \(count) messages")
                            .font(.caption)
                            .foregroundColor(.green)
                    case .error(let message):
                        VStack(spacing: 4) {
                            Text("Import failed")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("Try export method instead")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    case .idle:
                        if fileImporter.messages.isEmpty {
                            Text("Awaiting data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Ready for analysis")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 200, height: 300)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isActive ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut, value: isActive)
        .animation(.easeInOut, value: isCompleted)
    }
}

struct AnalyzeCard: View {
    @ObservedObject var fileImporter: FileImporter
    let isActive: Bool
    let isEnabled: Bool
    let onAnalyze: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Step indicator
            HStack {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                    
                    Text("3")
                        .foregroundColor(isActive ? .white : .gray)
                        .fontWeight(.bold)
                }
                
                Spacer()
            }
            
            // Content
            VStack(spacing: 16) {
                Image(systemName: "brain")
                    .font(.system(size: 48))
                    .foregroundColor(isEnabled ? .blue : .secondary)
                
                VStack(spacing: 8) {
                    Text("AI Analysis")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isEnabled ? .primary : .secondary)
                    
                    Text("Generate insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: onAnalyze) {
                    Text("Analyze")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(!isEnabled)
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 200, height: 300)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isActive ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: isActive)
        .animation(.easeInOut(duration: 0.3), value: isEnabled)
        .scaleEffect(isActive ? 1.02 : 1.0)
        .shadow(color: isActive ? .accentColor.opacity(0.2) : .clear, radius: 8)
    }
}

struct ErrorCard: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Import Error")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Dismiss", action: onDismiss)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}




// Keep existing AnalysisView and StatsView implementations
struct AnalysisView: View {
    @ObservedObject var fileImporter: FileImporter
    
    var body: some View {
        if fileImporter.messages.isEmpty {
            EmptyStateView(
                icon: "brain",
                title: "AI Analysis",
                subtitle: "Import your messages first to begin AI-powered analysis",
                note: "All processing happens locally on your Mac for complete privacy"
            )
        } else {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "brain")
                            .font(.title)
                            .foregroundColor(.accentColor)
                        Text("AI Analysis")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    Text("\(fileImporter.messages.count) messages loaded and ready for analysis")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Analysis Status
                VStack(spacing: 16) {
                    Text("🚧 Analysis Coming Soon")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("Apple Foundation Models integration is in development")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Preview of loaded data
                    GroupBox("Message Preview") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(fileImporter.messages.prefix(3).enumerated()), id: \.offset) { index, message in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(message.isFromMe ? "Me" : message.sender)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(message.isFromMe ? .blue : .green)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    Text(message.text)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                }
                            }
                            
                            if fileImporter.messages.count > 3 {
                                Text("... and \(fileImporter.messages.count - 3) more messages")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: 400)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct StatsView: View {
    @ObservedObject var fileImporter: FileImporter
    
    var body: some View {
        if fileImporter.messages.isEmpty {
            EmptyStateView(
                icon: "chart.bar.xaxis",
                title: "Message Insights",
                subtitle: "Statistics and insights will appear here",
                note: nil
            )
        } else {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.title)
                                .foregroundColor(.accentColor)
                            Text("Message Insights")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        Text("Overview of your imported conversations")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Statistics Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Total Messages",
                            value: "\(fileImporter.totalMessages)",
                            icon: "message.fill",
                            color: .blue
                        )
                        StatCard(
                            title: "Your Messages",
                            value: "\(fileImporter.myMessages.count)",
                            icon: "person.fill",
                            color: .green
                        )
                        StatCard(
                            title: "Others' Messages",
                            value: "\(fileImporter.otherMessages.count)",
                            icon: "person.2.fill",
                            color: .orange
                        )
                        StatCard(
                            title: "Participants",
                            value: "\(fileImporter.uniqueSenders.count)",
                            icon: "person.3.fill",
                            color: .purple
                        )
                    }
                    
                    // Date Range
                    let dateRange = fileImporter.dateRange
                    if let start = dateRange.start,
                       let end = dateRange.end {
                        GroupBox {
                            VStack(spacing: 12) {
                                Label("Conversation Timeline", systemImage: "calendar")
                                    .font(.headline)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("First Message")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(start, style: .date)
                                            .font(.subheadline)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("Last Message")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(end, style: .date)
                                            .font(.subheadline)
                                    }
                                }
                                
                                let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
                                Text("\(days) days of conversation")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Participants List
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Participants", systemImage: "person.3")
                                .font(.headline)
                            
                            ForEach(Array(fileImporter.uniqueSenders.sorted()), id: \.self) { sender in
                                let messageCount = fileImporter.messages.filter { $0.sender == sender }.count
                                HStack {
                                    Image(systemName: sender == "Me" ? "person.fill" : "person")
                                        .foregroundColor(sender == "Me" ? .blue : .secondary)
                                    
                                    Text(sender == "Me" ? "You" : sender)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(messageCount) messages")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Text("📊 Advanced analytics coming soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                }
                .padding()
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let note: String?
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .symbolEffect(.pulse)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let note = note {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Drag & Drop Support

struct DropZoneOverlay: View {
    @ObservedObject var fileImporter: FileImporter
    @State private var isTargeted = false
    
    let supportedTypes: [UTType] = [
        .fileURL,
        .database,
        .commaSeparatedText,
        .json,
        UTType(filenameExtension: "db")!,
        UTType(filenameExtension: "csv")!
    ]
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(
                isTargeted ? Color.accentColor : Color.clear,
                style: StrokeStyle(lineWidth: 3, dash: [10])
            )
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                isTargeted ? 
                VStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                    
                    Text("Drop file to import")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                } : nil
            )
            .onDrop(of: supportedTypes, isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }
            .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        // Handle file URLs
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    print("Failed to get URL from dropped item")
                    return
                }
                
                DispatchQueue.main.async {
                    self.importFile(at: url)
                }
            }
            return true
        }
        
        return false
    }
    
    private func importFile(at url: URL) {
        let fileExtension = url.pathExtension.lowercased()
        
        print("Importing file: \(url.lastPathComponent) with extension: \(fileExtension)")
        
        switch fileExtension {
        case "db", "sqlite", "sqlite3":
            fileImporter.importFromDatabase(url)
        case "csv":
            fileImporter.importMessages(from: url)
        case "json":
            importJSONFile(at: url)
        default:
            // Try to detect file type by content
            detectAndImportFile(at: url)
        }
    }
    
    private func importJSONFile(at url: URL) {
        // Enhanced JSON import with better error handling
        do {
            let data = try Data(contentsOf: url)
            
            // Try to parse as array of messages first
            if let messageArray = try? JSONDecoder().decode([Message].self, from: data) {
                DispatchQueue.main.async {
                    self.fileImporter.messages = messageArray
                    self.fileImporter.importStatus = .success(messageArray.count)
                }
                return
            }
            
            // Try to parse as wrapper object with messages array
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let messagesArray = jsonObject["messages"] as? [[String: Any]] {
                    let messages = parseJSONMessages(messagesArray)
                    DispatchQueue.main.async {
                        self.fileImporter.messages = messages
                        self.fileImporter.importStatus = .success(messages.count)
                    }
                    return
                }
            }
            
            // If direct JSON parsing fails, fall back to CSV parsing
            DispatchQueue.main.async {
                self.fileImporter.importMessages(from: url)
            }
            
        } catch {
            print("JSON import error: \(error)")
            // If JSON import fails, try CSV as fallback
            DispatchQueue.main.async {
                self.fileImporter.importMessages(from: url)
            }
        }
    }
    
    private func parseJSONMessages(_ messageArray: [[String: Any]]) -> [Message] {
        var messages: [Message] = []
        
        for messageDict in messageArray {
            guard let text = messageDict["text"] as? String,
                  let sender = messageDict["sender"] as? String,
                  let isFromMe = messageDict["isFromMe"] as? Bool else {
                continue
            }
            
            // Parse timestamp with multiple format support
            var timestamp = Date()
            if let timestampString = messageDict["timestamp"] as? String {
                let formatters = [
                    { () -> DateFormatter in
                        let f = DateFormatter()
                        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        return f
                    }(),
                    { () -> DateFormatter in
                        let f = DateFormatter()
                        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                        return f
                    }(),
                    { () -> DateFormatter in
                        let f = DateFormatter()
                        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        return f
                    }()
                ]
                
                for formatter in formatters {
                    if let parsedDate = formatter.date(from: timestampString) {
                        timestamp = parsedDate
                        break
                    }
                }
            } else if let timestampDouble = messageDict["timestamp"] as? Double {
                timestamp = Date(timeIntervalSince1970: timestampDouble)
            }
            
            let chatIdentifier = messageDict["chatIdentifier"] as? String ?? "direct"
            
            let message = Message(
                timestamp: timestamp,
                text: text,
                sender: sender,
                isFromMe: isFromMe,
                chatIdentifier: chatIdentifier
            )
            
            messages.append(message)
        }
        
        return messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func detectAndImportFile(at url: URL) {
        // Try to detect the file format by examining content
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedContent.hasPrefix("{") || trimmedContent.hasPrefix("[") {
                // Looks like JSON
                importJSONFile(at: url)
            } else if content.contains(",") && (content.contains("timestamp") || content.contains("text")) {
                // Looks like CSV
                DispatchQueue.main.async {
                    self.fileImporter.importMessages(from: url)
                }
            } else {
                // Default to CSV parsing
                DispatchQueue.main.async {
                    self.fileImporter.importMessages(from: url)
                }
            }
        } catch {
            // If we can't read as text, might be a database
            DispatchQueue.main.async {
                self.fileImporter.importFromDatabase(url)
            }
        }
    }
}

#Preview {
    ContentView()
}
