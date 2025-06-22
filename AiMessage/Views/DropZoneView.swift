import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var fileImporter: FileImporter
    @State private var isTargeted = false
    
    let supportedTypes: [UTType] = [
        .fileURL,
        .database,
        .commaSeparatedText,
        .json,
        UTType(filenameExtension: "db")!,
        UTType(filenameExtension: "csv")!,
        UTType(filenameExtension: "aimessage")!
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
        case "aimessage":
            detectAndImportAiMessageFile(at: url)
        default:
            // Try to detect file type by content
            detectAndImportAiMessageFile(at: url)
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
    
    private func detectAndImportAiMessageFile(at url: URL) {
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