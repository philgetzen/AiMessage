import Foundation
import NaturalLanguage

@MainActor
class AnalysisService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var analysisStatus = "Ready to analyze"
    
    private let sentimentAnalyzer = NLModel.sentimentAnalyzer
    private let tagger = NLTagger(tagSchemes: [.sentimentScore, .nameType])
    
    struct AnalysisResult {
        let sentiment: SentimentScore
        let entities: [NamedEntity]
        let topics: [String]
        let confidence: Double
    }
    
    struct SentimentScore {
        let polarity: Double // -1.0 (negative) to 1.0 (positive)
        let label: String // "Positive", "Negative", "Neutral"
        let confidence: Double
    }
    
    struct NamedEntity {
        let text: String
        let type: NLTag
        let range: NSRange
    }
    
    func analyzeMessages(_ messages: [Message]) async -> [String: AnalysisResult] {
        isAnalyzing = true
        analysisStatus = "Starting analysis..."
        analysisProgress = 0.0
        
        var results: [String: AnalysisResult] = [:]
        let totalMessages = messages.count
        
        for (index, message) in messages.enumerated() {
            guard !message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                analysisProgress = Double(index + 1) / Double(totalMessages)
                continue
            }
            
            analysisStatus = "Analyzing message \(index + 1) of \(totalMessages)"
            
            let result = await analyzeMessage(message.text)
            results[message.id] = result
            
            analysisProgress = Double(index + 1) / Double(totalMessages)
            
            // Small delay to prevent UI blocking
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        analysisStatus = "Analysis complete"
        isAnalyzing = false
        
        return results
    }
    
    private func analyzeMessage(_ text: String) async -> AnalysisResult {
        return await withCheckedContinuation { continuation in
            Task.detached {
                let sentiment = self.analyzeSentiment(text)
                let entities = self.extractEntities(text)
                let topics = self.extractTopics(text)
                let confidence = sentiment.confidence
                
                let result = AnalysisResult(
                    sentiment: sentiment,
                    entities: entities,
                    topics: topics,
                    confidence: confidence
                )
                
                continuation.resume(returning: result)
            }
        }
    }
    
    private func analyzeSentiment(_ text: String) -> SentimentScore {
        // Use NLModel for sentiment analysis
        if let sentimentModel = sentimentAnalyzer {
            let prediction = sentimentModel.predictedLabel(for: text)
            let confidence = sentimentModel.predictedLabelHypotheses(for: text, maximumCount: 1).first?.value ?? 0.5
            
            var polarity: Double = 0.0
            var label = "Neutral"
            
            if let prediction = prediction {
                switch prediction {
                case .positive:
                    polarity = confidence
                    label = "Positive"
                case .negative:
                    polarity = -confidence
                    label = "Negative"
                default:
                    polarity = 0.0
                    label = "Neutral"
                }
            }
            
            return SentimentScore(polarity: polarity, label: label, confidence: confidence)
        }
        
        // Fallback to NLTagger sentiment score
        tagger.string = text
        let sentiment = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        if let sentimentValue = sentiment.0?.rawValue,
           let score = Double(sentimentValue) {
            let label = score > 0.1 ? "Positive" : (score < -0.1 ? "Negative" : "Neutral")
            return SentimentScore(polarity: score, label: label, confidence: abs(score))
        }
        
        return SentimentScore(polarity: 0.0, label: "Neutral", confidence: 0.0)
    }
    
    private func extractEntities(_ text: String) -> [NamedEntity] {
        var entities: [NamedEntity] = []
        
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag, tag != .other {
                let entityText = String(text[tokenRange])
                let nsRange = NSRange(tokenRange, in: text)
                
                let entity = NamedEntity(text: entityText, type: tag, range: nsRange)
                entities.append(entity)
            }
            return true
        }
        
        return entities
    }
    
    private func extractTopics(_ text: String) -> [String] {
        // Simple topic extraction based on named entities and keywords
        var topics: Set<String> = []
        
        // Extract entities as potential topics
        let entities = extractEntities(text)
        for entity in entities {
            switch entity.type {
            case .organizationName:
                topics.insert("Organizations")
            case .personalName:
                topics.insert("People")
            case .placeName:
                topics.insert("Places")
            default:
                break
            }
        }
        
        // Add some basic keyword-based topics
        let lowercaseText = text.lowercased()
        
        if lowercaseText.contains("work") || lowercaseText.contains("job") || lowercaseText.contains("office") {
            topics.insert("Work")
        }
        if lowercaseText.contains("family") || lowercaseText.contains("mom") || lowercaseText.contains("dad") {
            topics.insert("Family")
        }
        if lowercaseText.contains("food") || lowercaseText.contains("dinner") || lowercaseText.contains("lunch") {
            topics.insert("Food")
        }
        if lowercaseText.contains("travel") || lowercaseText.contains("trip") || lowercaseText.contains("vacation") {
            topics.insert("Travel")
        }
        
        return Array(topics)
    }
    
    func generateSummary(from results: [String: AnalysisResult], messages: [Message]) -> AnalysisSummary {
        let validResults = results.values.filter { $0.confidence > 0.1 }
        
        let positiveCount = validResults.filter { $0.sentiment.polarity > 0.1 }.count
        let negativeCount = validResults.filter { $0.sentiment.polarity < -0.1 }.count
        let neutralCount = validResults.count - positiveCount - negativeCount
        
        let averageSentiment = validResults.isEmpty ? 0.0 :
            validResults.map { $0.sentiment.polarity }.reduce(0, +) / Double(validResults.count)
        
        let allTopics = validResults.flatMap { $0.topics }
        let topicCounts = Dictionary(grouping: allTopics, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        let allEntities = validResults.flatMap { $0.entities }
        let entityCounts = Dictionary(grouping: allEntities, by: { $0.text })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return AnalysisSummary(
            totalAnalyzed: validResults.count,
            averageSentiment: averageSentiment,
            sentimentDistribution: SentimentDistribution(
                positive: positiveCount,
                negative: negativeCount,
                neutral: neutralCount
            ),
            topTopics: Array(topicCounts.prefix(5)),
            topEntities: Array(entityCounts.prefix(10))
        )
    }
}

struct AnalysisSummary {
    let totalAnalyzed: Int
    let averageSentiment: Double
    let sentimentDistribution: SentimentDistribution
    let topTopics: [(key: String, value: Int)]
    let topEntities: [(key: String, value: Int)]
}

struct SentimentDistribution {
    let positive: Int
    let negative: Int
    let neutral: Int
    
    var total: Int { positive + negative + neutral }
    var positivePercentage: Double { total > 0 ? Double(positive) / Double(total) : 0.0 }
    var negativePercentage: Double { total > 0 ? Double(negative) / Double(total) : 0.0 }
    var neutralPercentage: Double { total > 0 ? Double(neutral) / Double(total) : 0.0 }
}