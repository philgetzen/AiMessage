import Foundation

class FileImporter: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var importStatus: ImportStatus = .idle
    
    enum ImportStatus: Equatable {
        case idle
        case loading
        case success(Int)
        case error(String)
    }
    
    // MARK: - CSV Import (The only method that works reliably)
    
    func importMessages(from url: URL) {
        isLoading = true
        importStatus = .loading
        
        Task {
            do {
                let content = try String(contentsOf: url)
                let parsedMessages = parseCSV(content: content)
                
                await MainActor.run {
                    self.messages = parsedMessages
                    self.isLoading = false
                    self.importStatus = .success(parsedMessages.count)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.importStatus = .error("Failed to read file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func parseCSV(content: String) -> [Message] {
        let lines = content.components(separatedBy: .newlines)
        var messages: [Message] = []
        
        // Check if first line is header
        let hasHeader = lines.first?.lowercased().contains("timestamp") ?? false
        let dataLines = hasHeader ? Array(lines.dropFirst()) : lines
        
        for line in dataLines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                if let message = parseCSVRow(trimmedLine) {
                    messages.append(message)
                }
            }
        }
        
        return messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func parseCSVRow(_ row: String) -> Message? {
        let components = parseCSVComponents(row)
        guard components.count >= 5 else { return nil }
        
        // Clean components
        let timestampString = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let text = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let sender = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let isFromMeString = components[3].trimmingCharacters(in: .whitespacesAndNewlines)
        let chatIdentifier = components[4].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse timestamp with multiple format support
        guard let timestamp = parseTimestamp(timestampString) else { return nil }
        
        // Parse isFromMe
        let isFromMe = isFromMeString.lowercased() == "true" || isFromMeString == "1"
        
        return Message(
            timestamp: timestamp,
            text: text,
            sender: sender,
            isFromMe: isFromMe,
            chatIdentifier: chatIdentifier
        )
    }
    
    private func parseCSVComponents(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = row.startIndex
        
        while i < row.endIndex {
            let char = row[i]
            
            if char == "\"" {
                if inQuotes && i < row.index(before: row.endIndex) && row[row.index(after: i)] == "\"" {
                    // Escaped quote
                    current.append("\"")
                    i = row.index(after: i)
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
            
            i = row.index(after: i)
        }
        
        result.append(current)
        
        // Remove surrounding quotes
        return result.map { component in
            var cleaned = component
            if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
                cleaned = String(cleaned.dropFirst().dropLast())
            }
            return cleaned
        }
    }
    
    private func parseTimestamp(_ string: String) -> Date? {
        // Try multiple date formats
        let formatters: [(String, DateFormatter.Style?, DateFormatter.Style?)] = [
            ("yyyy-MM-dd HH:mm:ss", nil, nil),
            ("yyyy-MM-dd'T'HH:mm:ss.SSSZ", nil, nil),
            ("yyyy-MM-dd'T'HH:mm:ssZ", nil, nil),
            ("yyyy-MM-dd'T'HH:mm:ss", nil, nil),
            ("MM/dd/yyyy HH:mm:ss", nil, nil),
            ("", .short, .short),
            ("", .medium, .medium),
            ("", .long, .long)
        ]
        
        for (format, dateStyle, timeStyle) in formatters {
            let formatter = DateFormatter()
            if !format.isEmpty {
                formatter.dateFormat = format
            } else if let ds = dateStyle, let ts = timeStyle {
                formatter.dateStyle = ds
                formatter.timeStyle = ts
            }
            
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        // Try Unix timestamp
        if let timestamp = Double(string) {
            // Check if it's in seconds or milliseconds
            if timestamp > 1_000_000_000_000 {
                // Milliseconds
                return Date(timeIntervalSince1970: timestamp / 1000)
            } else {
                // Seconds
                return Date(timeIntervalSince1970: timestamp)
            }
        }
        
        return nil
    }
    
    func clearMessages() {
        messages.removeAll()
        importStatus = .idle
    }
}

// MARK: - Convenience Properties
extension FileImporter {
    var totalMessages: Int {
        messages.count
    }
    
    var sentMessages: [Message] {
        messages.filter { $0.isFromMe }
    }
    
    var receivedMessages: [Message] {
        messages.filter { !$0.isFromMe }
    }
    
    var uniqueParticipants: Set<String> {
        Set(messages.map { $0.sender })
    }
    
    var conversationTimespan: (start: Date?, end: Date?) {
        guard !messages.isEmpty else { return (nil, nil) }
        let sorted = messages.sorted { $0.timestamp < $1.timestamp }
        return (sorted.first?.timestamp, sorted.last?.timestamp)
    }
    
    var messagesByParticipant: [String: [Message]] {
        Dictionary(grouping: messages, by: { $0.sender })
    }
    
    var messagesByDay: [Date: [Message]] {
        let calendar = Calendar.current
        return Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.timestamp)
        }
    }
}
