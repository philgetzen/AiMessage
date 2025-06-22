import Foundation

struct Message: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let text: String
    let sender: String
    let isFromMe: Bool
    let chatIdentifier: String
    
    init(timestamp: Date, text: String, sender: String, isFromMe: Bool, chatIdentifier: String) {
        self.timestamp = timestamp
        self.text = text
        self.sender = sender
        self.isFromMe = isFromMe
        self.chatIdentifier = chatIdentifier
    }
    
    // CSV parsing initializer
    init?(csvRow: String) {
        let components = csvRow.parseCSV()
        guard components.count >= 5 else { return nil }
        
        // Parse timestamp
        let timestampString = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let parsedDate = formatter.date(from: timestampString) else { return nil }
        
        self.timestamp = parsedDate
        self.text = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        self.sender = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
        self.isFromMe = components[3].trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
        self.chatIdentifier = components[4].trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// CSV parsing extension
extension String {
    func parseCSV() -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = startIndex
        
        while i < endIndex {
            let char = self[i]
            
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
            
            i = index(after: i)
        }
        
        result.append(current)
        return result.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
    }
}