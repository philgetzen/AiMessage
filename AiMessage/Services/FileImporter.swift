import Foundation
import SQLite3

// SQLite flags that might not be defined
let SQLITE_OPEN_NOMUTEX: Int32 = 0x00008000

class FileImporter: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var importStatus: ImportStatus = .idle
    @Published var errorMessage: String = ""
    
    enum ImportStatus: Equatable {
        case idle
        case loading
        case success(Int)
        case error(String)
    }
    
    enum ImportError: LocalizedError {
        case notMessagesDatabase
        case databaseLocked
        case queryFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .notMessagesDatabase:
                return "Cannot access Messages database. Use 'Convert DB → CSV' button instead."
            case .databaseLocked:
                return "Database is protected. Use 'Convert DB → CSV' button instead."
            case .queryFailed(let message):
                return "Database read failed. Use 'Convert DB → CSV' button instead."
            }
        }
    }
    
    // MARK: - Direct Database Import
    
    func importFromDatabase(_ databaseURL: URL) {
        isLoading = true
        importStatus = .loading
        
        Task {
            do {
                // Validate it's a Messages database
                let isValid = try await validateMessagesDatabase(at: databaseURL)
                guard isValid else {
                    throw ImportError.notMessagesDatabase
                }
                
                // Query messages directly
                let messages = try await queryMessagesFromDatabase(at: databaseURL)
                
                await MainActor.run {
                    self.messages = messages
                    self.importStatus = .success(messages.count)
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.importStatus = .error(error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func validateMessagesDatabase(at url: URL) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            var db: OpaquePointer?
            
            print("Attempting to open database at: \(url.path)")
            
            // Try multiple opening strategies
            var openResult: Int32 = -1
            
            // Strategy 1: Standard readonly with NOMUTEX
            let flags1 = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
            openResult = sqlite3_open_v2(url.path, &db, flags1, nil)
            
            if openResult != SQLITE_OK {
                print("Strategy 1 failed: \(String(cString: sqlite3_errmsg(db)))")
                sqlite3_close(db)
                db = nil
                
                // Strategy 2: Just readonly
                let flags2 = SQLITE_OPEN_READONLY
                openResult = sqlite3_open_v2(url.path, &db, flags2, nil)
                
                if openResult != SQLITE_OK {
                    print("Strategy 2 failed: \(String(cString: sqlite3_errmsg(db)))")
                    sqlite3_close(db)
                    db = nil
                    
                    // Strategy 3: Default flags
                    openResult = sqlite3_open(url.path, &db)
                    
                    if openResult != SQLITE_OK {
                        let errorMessage = String(cString: sqlite3_errmsg(db))
                        print("All strategies failed. Final error: \(errorMessage)")
                        sqlite3_close(db)
                        continuation.resume(throwing: ImportError.databaseLocked)
                        return
                    } else {
                        print("Strategy 3 (default) succeeded")
                    }
                } else {
                    print("Strategy 2 (readonly) succeeded")
                }
            } else {
                print("Strategy 1 (readonly + nomutex) succeeded")
            }
            
            defer { sqlite3_close(db) }
            
            // Try to access the database schema
            print("Attempting to read database schema...")
            
            // Enable WAL mode checkpoint to ensure we see all data
            let walResult = sqlite3_exec(db, "PRAGMA wal_checkpoint(FULL);", nil, nil, nil)
            if walResult != SQLITE_OK {
                print("WAL checkpoint failed, continuing anyway...")
            }
            
            // Check if message table exists (try both lowercase and uppercase)
            let queries = [
                "SELECT name FROM sqlite_master WHERE type='table' AND name='message';",
                "SELECT name FROM sqlite_master WHERE type='table' AND name='MESSAGE';",
                "SELECT name FROM sqlite_master WHERE type='table' AND lower(name)='message';"
            ]
            
            var found = false
            for (index, query) in queries.enumerated() {
                print("Trying query \(index + 1): \(query)")
                var statement: OpaquePointer?
                
                let prepareResult = sqlite3_prepare_v2(db, query, -1, &statement, nil)
                if prepareResult == SQLITE_OK {
                    defer { sqlite3_finalize(statement) }
                    
                    let stepResult = sqlite3_step(statement)
                    if stepResult == SQLITE_ROW {
                        print("Found message table!")
                        found = true
                        break
                    } else {
                        print("Query \(index + 1) returned no results (step result: \(stepResult))")
                    }
                } else {
                    let errorMsg = String(cString: sqlite3_errmsg(db))
                    print("Query \(index + 1) prepare failed: \(errorMsg)")
                }
            }
            
            if found {
                continuation.resume(returning: true)
            } else {
                // Try to list all tables to debug
                print("Message table not found. Checking database structure...")
                
                // Try a simpler approach - just check if we can read anything
                var tableCount = 0
                var foundMessageRelated = false
                
                // First try to get table count
                let countQuery = "SELECT COUNT(*) FROM sqlite_master WHERE type='table';"
                var countStatement: OpaquePointer?
                
                if sqlite3_prepare_v2(db, countQuery, -1, &countStatement, nil) == SQLITE_OK {
                    defer { sqlite3_finalize(countStatement) }
                    
                    if sqlite3_step(countStatement) == SQLITE_ROW {
                        tableCount = Int(sqlite3_column_int(countStatement, 0))
                        print("Database contains \(tableCount) tables")
                    }
                }
                
                // If we can't even count tables, this might be a permission issue
                if tableCount == 0 {
                    print("Cannot access database schema - likely a permission/security issue")
                    print("This is probably the actual Messages database, but macOS security prevents access")
                    print("Suggesting CSV export as alternative...")
                }
                
                // Even if we can't read the schema, this is likely the right database
                // The authorization error suggests it's protected, not that it's wrong
                continuation.resume(returning: false)
            }
        }
    }
    
    private func queryMessagesFromDatabase(at url: URL) async throws -> [Message] {
        return try await withCheckedThrowingContinuation { continuation in
            var db: OpaquePointer?
            var messages: [Message] = []
            
            print("Opening database for message query...")
            
            // Use the same opening strategy as validation
            var openResult: Int32 = -1
            
            // Try the same strategies as validation
            let flags1 = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
            openResult = sqlite3_open_v2(url.path, &db, flags1, nil)
            
            if openResult != SQLITE_OK {
                sqlite3_close(db)
                db = nil
                
                let flags2 = SQLITE_OPEN_READONLY
                openResult = sqlite3_open_v2(url.path, &db, flags2, nil)
                
                if openResult != SQLITE_OK {
                    sqlite3_close(db)
                    db = nil
                    
                    openResult = sqlite3_open(url.path, &db)
                    
                    if openResult != SQLITE_OK {
                        let errorMessage = String(cString: sqlite3_errmsg(db))
                        print("Failed to open database for query: \(errorMessage)")
                        sqlite3_close(db)
                        continuation.resume(throwing: ImportError.databaseLocked)
                        return
                    }
                }
            }
            
            defer { sqlite3_close(db) }
            
            print("Database opened successfully for query")
            
            // Enable WAL mode checkpoint
            let walResult = sqlite3_exec(db, "PRAGMA wal_checkpoint(FULL);", nil, nil, nil)
            if walResult != SQLITE_OK {
                print("WAL checkpoint failed during query, continuing...")
            }
            
            // Query messages using article's proven approach
            let query = """
                SELECT 
                    datetime(message.date/1000000000 + strftime('%s', '2001-01-01'), 'unixepoch', 'localtime') as timestamp,
                    message.text,
                    CASE WHEN message.is_from_me = 1 THEN 'Me' ELSE COALESCE(handle.id, 'Unknown') END as sender,
                    message.is_from_me,
                    'direct' as chatIdentifier
                FROM message
                LEFT JOIN handle ON message.handle_id = handle.ROWID
                WHERE message.text IS NOT NULL AND message.text != ''
                ORDER BY message.date
                LIMIT 10000;
            """
            
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                defer { sqlite3_finalize(statement) }
                
                while sqlite3_step(statement) == SQLITE_ROW {
                    // Parse each row
                    guard let timestampCString = sqlite3_column_text(statement, 0),
                          let textCString = sqlite3_column_text(statement, 1),
                          let senderCString = sqlite3_column_text(statement, 2),
                          let chatIdCString = sqlite3_column_text(statement, 4) else {
                        continue
                    }
                    
                    let timestampString = String(cString: timestampCString)
                    let text = String(cString: textCString)
                    let sender = String(cString: senderCString)
                    let isFromMe = sqlite3_column_int(statement, 3) == 1
                    let chatIdentifier = String(cString: chatIdCString)
                    
                    // Parse date
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    guard let date = formatter.date(from: timestampString) else { continue }
                    
                    let message = Message(
                        timestamp: date,
                        text: text,
                        sender: sender,
                        isFromMe: isFromMe,
                        chatIdentifier: chatIdentifier
                    )
                    
                    messages.append(message)
                }
                
                continuation.resume(returning: messages.sorted { $0.timestamp < $1.timestamp })
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                continuation.resume(throwing: ImportError.queryFailed(errorMessage))
            }
        }
    }
    
    // MARK: - Database to CSV Conversion (Removed - Use Manual Export Instead)
    
    func convertDatabaseToCsv(dbUrl: URL, csvUrl: URL, completion: @escaping (Bool) -> Void) {
        // Always direct users to manual export since automatic conversion fails due to sandbox restrictions
        DispatchQueue.main.async {
            completion(false)
        }
    }
    
    // Complex database conversion removed - use manual export instead
    
    // Shell script conversion removed - use manual export instead
    
    // Alternative conversion removed - use manual export instead
    
    // MARK: - CSV Import (kept as fallback)
    
    func importMessages(from url: URL) {
        isLoading = true
        importStatus = .loading
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let content = try String(contentsOf: url)
                let parsedMessages = self.parseCSV(content: content)
                
                DispatchQueue.main.async {
                    self.messages = parsedMessages
                    self.isLoading = false
                    self.importStatus = .success(parsedMessages.count)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.importStatus = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func parseCSV(content: String) -> [Message] {
        let lines = content.components(separatedBy: .newlines)
        var messages: [Message] = []
        
        // Skip header row if present
        let dataLines = lines.count > 1 && lines[0].lowercased().contains("timestamp") ? 
            Array(lines.dropFirst()) : lines
        
        for line in dataLines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                if let message = Message(csvRow: trimmedLine) {
                    messages.append(message)
                }
            }
        }
        
        return messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    func clearMessages() {
        messages.removeAll()
        importStatus = .idle
        errorMessage = ""
    }
}

// Convenience methods for statistics
extension FileImporter {
    var totalMessages: Int {
        messages.count
    }
    
    var myMessages: [Message] {
        messages.filter { $0.isFromMe }
    }
    
    var otherMessages: [Message] {
        messages.filter { !$0.isFromMe }
    }
    
    var uniqueSenders: Set<String> {
        Set(messages.map { $0.sender })
    }
    
    var dateRange: (start: Date?, end: Date?) {
        let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
        return (start: sortedMessages.first?.timestamp, end: sortedMessages.last?.timestamp)
    }
}