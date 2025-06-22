import SwiftUI
import UniformTypeIdentifiers
import AppKit

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
            // Privacy Header
            PrivacyHeaderView()
                .padding(.top, 20)
                .padding(.bottom, 16)
            
            // Clean header
            VStack(spacing: 8) {
                Text("Import Your Messages")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("A simple two-step process to analyze your conversations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
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
            
            // Privacy Footer
            PrivacyFooterView()
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Privacy Header
struct PrivacyHeaderView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.title2)
                .foregroundColor(.green)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("100% Private & Secure")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("All processing happens locally on your Mac")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: showPrivacyDetails) {
                Label("Learn More", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 40)
    }
    
    private func showPrivacyDetails() {
        NSAlert.showPrivacyInfo()
    }
}

// MARK: - Export Step
struct ExportStepView: View {
    let onExportStarted: () -> Void
    @State private var commandCopied = false
    @State private var showingWhyTerminal = false
    
    private let exportCommand = """
    sqlite3 -header -csv ~/Library/Messages/chat.db "SELECT datetime(message.date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime') as timestamp, message.text, CASE WHEN message.is_from_me = 1 THEN 'Me' ELSE COALESCE(handle.id, 'Unknown') END as sender, CASE WHEN message.is_from_me = 1 THEN 'true' ELSE 'false' END as isFromMe, 'direct' as chatIdentifier FROM message LEFT JOIN handle ON message.handle_id = handle.ROWID WHERE message.text IS NOT NULL AND message.text != '' ORDER BY message.date LIMIT 50000;" > ~/Downloads/messages.csv
    """
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon with badge
            ZStack(alignment: .topTrailing) {
                Image(systemName: "terminal")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .symbolEffect(.pulse)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                    .offset(x: 8, y: -8)
            }
            
            // Title
            VStack(spacing: 4) {
                Text("Step 1: Export Your Messages")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Button(action: { showingWhyTerminal = true }) {
                    Label("Why Terminal?", systemImage: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingWhyTerminal) {
                    WhyTerminalView()
                        .frame(width: 300)
                        .padding()
                }
            }
            
            // Instructions
            VStack(alignment: .leading, spacing: 16) {
                InstructionRow(number: "1", text: "Open Terminal", subtext: "Press ⌘+Space and type 'Terminal'")
                InstructionRow(number: "2", text: "Copy the export command", subtext: "Click the button below")
                InstructionRow(number: "3", text: "Paste and run", subtext: "Press ⌘+V then Enter in Terminal")
                InstructionRow(number: "4", text: "Wait for completion", subtext: "Usually takes 5-30 seconds")
            }
            .frame(maxWidth: 400)
            
            // Copy button
            VStack(spacing: 8) {
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
                
                Text("This creates messages.csv in your Downloads folder")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
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
                        .fill(isDragging ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                )
                .frame(width: 400, height: 150)
                .overlay(
                    VStack(spacing: 8) {
                        Text(isDragging ? "Drop your file here" : "Drag messages.csv here")
                            .font(.headline)
                            .foregroundColor(isDragging ? .accentColor : .primary)
                        
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
            VStack(spacing: 4) {
                Label("The file should be in your Downloads folder", systemImage: "folder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("No data leaves your computer", systemImage: "lock")
                    .font(.caption)
                    .foregroundColor(.green)
            }
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
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce)
            }
            
            // Title
            Text("Import Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            // Stats with privacy note
            VStack(spacing: 8) {
                Text("\(messageCount) messages imported successfully")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Label("Ready for local analysis", systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
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

// MARK: - Privacy Footer
struct PrivacyFooterView: View {
    var body: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.horizontal, 60)
            
            HStack(spacing: 24) {
                PrivacyBadge(icon: "lock.fill", text: "No Internet Required")
                PrivacyBadge(icon: "cpu", text: "On-Device Processing")
                PrivacyBadge(icon: "eye.slash.fill", text: "No Tracking")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
    }
}

struct PrivacyBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        Label(text, systemImage: icon)
    }
}

// MARK: - Why Terminal View
struct WhyTerminalView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Why use Terminal?", systemImage: "terminal")
                .font(.headline)
            
            Text("Apple's security protects your Messages database from direct access by apps. Using Terminal is the official, secure way to export your data.")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Label("100% Safe", systemImage: "checkmark.shield")
                    .foregroundColor(.green)
                Label("Apple Approved Method", systemImage: "apple.logo")
                    .foregroundColor(.blue)
                Label("Your Data Stays Local", systemImage: "lock")
                    .foregroundColor(.orange)
            }
            .font(.caption)
        }
    }
}

// MARK: - Privacy Alert Extension
extension NSAlert {
    static func showPrivacyInfo() {
        let alert = NSAlert()
        alert.messageText = "Your Privacy is Our Priority"
        alert.informativeText = """
        AiMessage is designed with privacy at its core:
        
        • All processing happens locally on your Mac
        • No internet connection required
        • Your messages never leave your computer
        • No analytics or tracking
        • Open source for transparency
        
        We use Apple's Foundation Models for on-device AI analysis, ensuring your conversations remain completely private.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Got It")
        alert.runModal()
    }
}
