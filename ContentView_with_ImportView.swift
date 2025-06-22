import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var fileImporter = FileImporter()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ImportView(fileImporter: fileImporter)
                .tabItem {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .tag(0)
            
            AnalysisView(fileImporter: fileImporter)
                .tabItem {
                    Label("Analysis", systemImage: "brain")
                }
                .tag(1)
                .disabled(fileImporter.messages.isEmpty)
            
            InsightsView(fileImporter: fileImporter)
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
                .disabled(fileImporter.messages.isEmpty)
        }
        .frame(minWidth: 800, minHeight: 600)
        .onChange(of: fileImporter.messages.count) { oldCount, newCount in
            // Auto-switch to analysis tab when messages are imported
            if oldCount == 0 && newCount > 0 {
                withAnimation {
                    selectedTab = 1
                }
            }
        }
    }
}

// MARK: - Analysis View (Placeholder)
struct AnalysisView: View {
    @ObservedObject var fileImporter: FileImporter
    @State private var analysisProgress: Double = 0
    @State private var isAnalyzing = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("Message Analysis")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(fileImporter.messages.count) messages ready for analysis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            if !isAnalyzing {
                // Pre-analysis view
                VStack(spacing: 24) {
                    Image(systemName: "brain")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                        .symbolEffect(.pulse)
                    
                    Text("Ready to analyze your conversations")
                        .font(.title3)
                    
                    Text("Analysis will include sentiment detection, topic extraction, and conversation patterns")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                    
                    Button(action: startAnalysis) {
                        Label("Start Analysis", systemImage: "play.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                    
                    // Quick stats
                    QuickStatsView(fileImporter: fileImporter)
                        .padding(.top)
                }
            } else {
                // Analysis in progress
                VStack(spacing: 24) {
                    ProgressView(value: analysisProgress) {
                        Text("Analyzing conversations...")
                            .font(.headline)
                    }
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 400)
                    
                    Text("Using Apple Foundation Models for on-device processing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func startAnalysis() {
        isAnalyzing = true
        
        // Simulate analysis progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            analysisProgress += 0.02
            if analysisProgress >= 1.0 {
                timer.invalidate()
                // Analysis complete
            }
        }
    }
}

// MARK: - Insights View
struct InsightsView: View {
    @ObservedObject var fileImporter: FileImporter
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Conversation Insights")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Statistical overview of your messages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    StatCard(
                        title: "Total Messages",
                        value: "\(fileImporter.totalMessages)",
                        icon: "message.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Sent by You",
                        value: "\(fileImporter.sentMessages.count)",
                        icon: "arrow.up.message",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Received",
                        value: "\(fileImporter.receivedMessages.count)",
                        icon: "arrow.down.message",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Participants",
                        value: "\(fileImporter.uniqueParticipants.count)",
                        icon: "person.2",
                        color: .purple
                    )
                    
                    let timespan = fileImporter.conversationTimespan
                    if let start = timespan.start, let end = timespan.end {
                        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
                        StatCard(
                            title: "Days Covered",
                            value: "\(days)",
                            icon: "calendar",
                            color: .pink
                        )
                        
                        let avgPerDay = fileImporter.totalMessages / max(days, 1)
                        StatCard(
                            title: "Avg/Day",
                            value: "\(avgPerDay)",
                            icon: "chart.bar",
                            color: .teal
                        )
                    }
                }
                .padding(.horizontal, 40)
                
                // Participant breakdown
                if !fileImporter.uniqueParticipants.isEmpty {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Participants", systemImage: "person.3")
                                .font(.headline)
                            
                            ForEach(Array(fileImporter.messagesByParticipant.keys.sorted()), id: \.self) { participant in
                                if let messages = fileImporter.messagesByParticipant[participant] {
                                    HStack {
                                        Image(systemName: participant == "Me" ? "person.fill" : "person")
                                            .foregroundColor(participant == "Me" ? .accentColor : .secondary)
                                        
                                        Text(participant)
                                            .fontWeight(participant == "Me" ? .medium : .regular)
                                        
                                        Spacer()
                                        
                                        Text("\(messages.count)")
                                            .foregroundColor(.secondary)
                                        
                                        // Simple bar visualization
                                        GeometryReader { geometry in
                                            Rectangle()
                                                .fill(participant == "Me" ? Color.accentColor : Color.secondary)
                                                .opacity(0.3)
                                                .frame(width: geometry.size.width * (Double(messages.count) / Double(fileImporter.totalMessages)))
                                        }
                                        .frame(width: 100, height: 20)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(maxWidth: 600)
                }
                
                Spacer(minLength: 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Supporting Views
struct QuickStatsView: View {
    @ObservedObject var fileImporter: FileImporter
    
    var body: some View {
        HStack(spacing: 32) {
            QuickStat(label: "Messages", value: "\(fileImporter.totalMessages)")
            QuickStat(label: "Participants", value: "\(fileImporter.uniqueParticipants.count)")
            
            let timespan = fileImporter.conversationTimespan
            if let start = timespan.start {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                QuickStat(label: "Since", value: formatter.string(from: start))
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

struct QuickStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - IMPORT VIEW CODE (Temporary - move to separate file later)

// MARK: - Main Import View
struct ImportView: View {
    @ObservedObject var fileImporter: FileImporter
    @State private var currentStep: ImportStep = .export
    @State private var hasExported = false
    @State private var isDragging = false
    
    enum ImportStep {
        case export
        case waitingForFile
        case importing
        case complete
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean header
            VStack(spacing: 8) {
                Text("Import Your Messages")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("A simple two-step process to analyze your conversations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            
            // Main content area
            ZStack {
                // Step 1: Export Instructions
                if currentStep == .export {
                    ExportStepView(
                        onExportStarted: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                hasExported = true
                                currentStep = .waitingForFile
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
                
                // Step 2: Drop Zone
                if currentStep == .waitingForFile {
                    FileDropView(
                        fileImporter: fileImporter,
                        isDragging: $isDragging,
                        onFileImported: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep = .complete
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
                
                // Step 3: Success
                if currentStep == .complete {
                    ImportSuccessView(
                        messageCount: fileImporter.messages.count,
                        onAnalyze: {
                            // Navigate to analysis tab
                        },
                        onImportAnother: {
                            fileImporter.clearMessages()
                            withAnimation {
                                currentStep = .export
                                hasExported = false
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .frame(maxWidth: 600, maxHeight: 400)
            .animation(.easeInOut(duration: 0.3), value: currentStep)
            
            // Progress indicator
            ProgressIndicatorView(
                currentStep: currentStep,
                hasExported: hasExported
            )
            .padding(.top, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Export Step
struct ExportStepView: View {
    let onExportStarted: () -> Void
    @State private var commandCopied = false
    
    private let exportCommand = """
    sqlite3 -header -csv ~/Library/Messages/chat.db "SELECT datetime(message.date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime') as timestamp, message.text, CASE WHEN message.is_from_me = 1 THEN 'Me' ELSE COALESCE(handle.id, 'Unknown') END as sender, CASE WHEN message.is_from_me = 1 THEN 'true' ELSE 'false' END as isFromMe, 'direct' as chatIdentifier FROM message LEFT JOIN handle ON message.handle_id = handle.ROWID WHERE message.text IS NOT NULL AND message.text != '' ORDER BY message.date LIMIT 50000;" > ~/Downloads/messages.csv
    """
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "terminal")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
                .symbolEffect(.pulse)
            
            // Title
            Text("Step 1: Export Your Messages")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Instructions
            VStack(alignment: .leading, spacing: 16) {
                InstructionRow(number: "1", text: "Open Terminal", subtext: "Press ⌘+Space and type 'Terminal'")
                InstructionRow(number: "2", text: "Copy the export command", subtext: "Click the button below")
                InstructionRow(number: "3", text: "Paste and run", subtext: "Press ⌘+V then Enter in Terminal")
                InstructionRow(number: "4", text: "Wait for completion", subtext: "Usually takes 5-30 seconds")
            }
            .frame(maxWidth: 400)
            
            // Copy button
            Button(action: copyCommand) {
                HStack {
                    Image(systemName: commandCopied ? "checkmark.circle.fill" : "doc.on.clipboard")
                    Text(commandCopied ? "Command Copied!" : "Copy Export Command")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(commandCopied ? Color.green : Color.accentColor)
                )
            }
            .scaleEffect(commandCopied ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: commandCopied)
            
            // Continue button
            Button(action: onExportStarted) {
                Text("I've run the command →")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }
    
    private func copyCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(exportCommand, forType: .string)
        
        withAnimation {
            commandCopied = true
        }
        
        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                commandCopied = false
            }
        }
        
        // Open Terminal
        NSWorkspace.shared.launchApplication("Terminal")
    }
}

// MARK: - File Drop View
struct FileDropView: View {
    @ObservedObject var fileImporter: FileImporter
    @Binding var isDragging: Bool
    let onFileImported: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: isDragging ? "doc.badge.plus" : "arrow.down.doc")
                .font(.system(size: 48))
                .foregroundColor(isDragging ? .accentColor : .secondary)
                .scaleEffect(isDragging ? 1.2 : 1.0)
                .animation(.spring(response: 0.3), value: isDragging)
            
            // Title
            Text("Step 2: Import Your Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Drop zone
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isDragging ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: isDragging ? [] : [8])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDragging ? Color.accentColor.opacity(0.1) : Color.clear)
                )
                .frame(width: 400, height: 150)
                .overlay(
                    VStack(spacing: 8) {
                        Text(isDragging ? "Drop your file here" : "Drag messages.csv here")
                            .font(.headline)
                            .foregroundColor(isDragging ? .accentColor : .secondary)
                        
                        if !isDragging {
                            Text("or")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Browse for file") {
                                selectFile()
                            }
                            .buttonStyle(.link)
                        }
                    }
                )
                .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                    handleDrop(providers: providers)
                }
                .animation(.easeInOut(duration: 0.2), value: isDragging)
            
            // Status
            if case .loading = fileImporter.importStatus {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Importing messages...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if case .error(let message) = fileImporter.importStatus {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // Help text
            Text("The file should be in your Downloads folder")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onChange(of: fileImporter.importStatus) { oldStatus, newStatus in
            if case .success = newStatus {
                onFileImported()
            }
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.title = "Select messages.csv"
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            importFile(at: url)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            
            DispatchQueue.main.async {
                importFile(at: url)
            }
        }
        
        return true
    }
    
    private func importFile(at url: URL) {
        fileImporter.importMessages(from: url)
    }
}

// MARK: - Success View
struct ImportSuccessView: View {
    let messageCount: Int
    let onAnalyze: () -> Void
    let onImportAnother: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
                .symbolEffect(.bounce)
            
            // Title
            Text("Import Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            // Stats
            Text("\(messageCount) messages imported successfully")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Action buttons
            HStack(spacing: 16) {
                Button("Import Another") {
                    onImportAnother()
                }
                .buttonStyle(.bordered)
                
                Button("Analyze Messages") {
                    onAnalyze()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

// MARK: - Supporting Views
struct InstructionRow: View {
    let number: String
    let text: String
    let subtext: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Text(number)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 15, weight: .medium))
                
                Text(subtext)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ProgressIndicatorView: View {
    let currentStep: ImportView.ImportStep
    let hasExported: Bool
    
    var body: some View {
        HStack(spacing: 32) {
            ProgressDot(
                isActive: currentStep == .export,
                isCompleted: hasExported,
                label: "Export"
            )
            
            ProgressConnector(isActive: hasExported)
            
            ProgressDot(
                isActive: currentStep == .waitingForFile || currentStep == .importing,
                isCompleted: currentStep == .complete,
                label: "Import"
            )
            
            ProgressConnector(isActive: currentStep == .complete)
            
            ProgressDot(
                isActive: currentStep == .complete,
                isCompleted: false,
                label: "Analyze"
            )
        }
    }
}

struct ProgressDot: View {
    let isActive: Bool
    let isCompleted: Bool
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(dotColor)
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(isActive || isCompleted ? .primary : .secondary)
        }
    }
    
    var dotColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return .accentColor
        } else {
            return Color.secondary.opacity(0.3)
        }
    }
}

struct ProgressConnector: View {
    let isActive: Bool
    
    var body: some View {
        Rectangle()
            .fill(isActive ? Color.green : Color.secondary.opacity(0.3))
            .frame(width: 40, height: 2)
    }
}

#Preview {
    ContentView()
}
