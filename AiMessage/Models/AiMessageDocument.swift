import Cocoa
import SwiftUI
import UniformTypeIdentifiers

class AiMessageDocument: NSDocument, ObservableObject {
    
    // Document data
    var messages: [Message] = []
    var importError: Error?
    
    // File importer for processing - make it public for SwiftUI
    let fileImporter = FileImporter()
    
    override init() {
        super.init()
        // Add your document initialization code here
    }

    override class var autosavesInPlace: Bool {
        return false // We don't need autosaving for import-only documents
    }
    
    override func makeWindowControllers() {
        // Create the SwiftUI view and wrap it in a hosting controller
        let contentView = ContentView()
            .environmentObject(fileImporter)
        
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hostingController)
        
        window.setContentSize(NSSize(width: 1000, height: 700))
        window.title = "AiMessage"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        
        let windowController = NSWindowController(window: window)
        self.addWindowController(windowController)
    }

    override func data(ofType typeName: String) throws -> Data {
        // We don't support saving documents, only opening them
        throw NSError(domain: "AiMessageDocument", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "AiMessage does not support saving documents."
        ])
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // This method is called when a document is opened
        
        // Create a temporary file from the data
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(self.fileExtension(for: typeName))
        
        try data.write(to: tempURL)
        
        // Import the file based on its type
        DispatchQueue.main.async {
            self.importFile(at: tempURL, ofType: typeName)
        }
    }
    
    private func fileExtension(for typeName: String) -> String {
        switch typeName {
        case "com.aimessage.document":
            return "aimessage"
        case "public.comma-separated-values-text":
            return "csv"
        case "public.json":
            return "json"
        case "public.database":
            return "db"
        default:
            return "txt"
        }
    }
    
    private func importFile(at url: URL, ofType typeName: String) {
        switch typeName {
        case "com.aimessage.document":
            // Custom AiMessage format - could be JSON or CSV
            detectAndImportAiMessageFile(at: url)
        case "public.comma-separated-values-text":
            fileImporter.importMessages(from: url)
        case "public.json":
            importJSONFile(at: url)
        case "public.database":
            // Database import not supported - show error
            showDatabaseError()
        default:
            // Try to detect format automatically
            detectAndImportAiMessageFile(at: url)
        }
    }
    
    private func detectAndImportAiMessageFile(at url: URL) {
        // Try to detect the file format by examining content
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            
            if content.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") ||
               content.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[") {
                // Looks like JSON
                importJSONFile(at: url)
            } else if content.contains(",") && (content.contains("timestamp") || content.contains("text")) {
                // Looks like CSV
                fileImporter.importMessages(from: url)
            } else {
                // Default to CSV parsing
                fileImporter.importMessages(from: url)
            }
        } catch {
            // If we can't read as text, show error
            showDatabaseError()
        }
    }
    
    private func importJSONFile(at url: URL) {
        // Basic JSON import - extend this based on your JSON format needs
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
            
            // Try to parse as wrapper object
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let messagesArray = jsonObject["messages"] as? [[String: Any]] {
                    let messages = self.parseJSONMessages(messagesArray)
                    DispatchQueue.main.async {
                        self.fileImporter.messages = messages
                        self.fileImporter.importStatus = .success(messages.count)
                    }
                    return
                }
            }
            
            // If JSON parsing fails, fall back to treating as text
            fileImporter.importMessages(from: url)
            
        } catch {
            // If JSON import fails, try CSV as fallback
            fileImporter.importMessages(from: url)
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
            
            // Parse timestamp
            var timestamp = Date()
            if let timestampString = messageDict["timestamp"] as? String {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                timestamp = formatter.date(from: timestampString) ?? Date()
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
    
    private func showDatabaseError() {
        DispatchQueue.main.async {
            self.fileImporter.importStatus = .error("Direct database import is not supported. Please use Terminal export method instead.")
        }
    }
}

// UTType extensions for our custom type
extension UTType {
    static let aiMessageDocument = UTType(exportedAs: "com.aimessage.document")
}
