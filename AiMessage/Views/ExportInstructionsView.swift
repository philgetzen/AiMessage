import SwiftUI

struct ExportInstructionsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var exportCommand = """
sqlite3 ~/Library/Messages/chat.db "
SELECT 
    datetime(date/1000000000 + 978307200, 'unixepoch', 'localtime') as timestamp,
    text,
    CASE is_from_me WHEN 1 THEN 'Me' ELSE COALESCE(handle.id, 'Unknown') END as sender,
    is_from_me,
    COALESCE(chat.chat_identifier, 'direct') as chatIdentifier
FROM message
LEFT JOIN handle ON message.handle_id = handle.ROWID
LEFT JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
LEFT JOIN chat ON chat_message_join.chat_id = chat.ROWID
WHERE text IS NOT NULL AND text != ''
ORDER BY date DESC;" > ~/Desktop/messages_export.csv
"""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export Your Messages")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("macOS security prevents direct access. Export your messages first.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Step 1
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Step 1: Open Terminal", systemImage: "1.circle.fill")
                            .font(.headline)
                        
                        Text("Open Terminal from Applications → Utilities → Terminal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Step 2
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Step 2: Copy Export Command", systemImage: "2.circle.fill")
                            .font(.headline)
                        
                        GroupBox {
                            HStack {
                                Text(exportCommand)
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(3)
                                    .truncationMode(.tail)
                                
                                Spacer()
                                
                                Button(action: copyCommand) {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        
                        Text("Click the copy button to copy the command")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Step 3
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Step 3: Run the Command", systemImage: "3.circle.fill")
                            .font(.headline)
                        
                        Text("Paste the command in Terminal and press Enter")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("This will create 'messages_export.csv' on your Desktop")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Step 4
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Step 4: Import the CSV", systemImage: "4.circle.fill")
                            .font(.headline)
                        
                        Text("Click 'Import CSV Instead' and select the exported file")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Note
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Why is this necessary?", systemImage: "info.circle")
                                .font(.headline)
                            
                            Text("macOS protects your Messages database with system-level security. Even when you grant permission through file selection, third-party apps cannot read the database directly. Exporting to CSV is the recommended workaround.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private func copyCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(exportCommand, forType: .string)
    }
}

#Preview {
    ExportInstructionsView()
}