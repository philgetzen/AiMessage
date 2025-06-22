import SwiftUI

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
        .frame(minWidth: 900, minHeight: 700)
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

// MARK: - Analysis View
struct AnalysisView: View {
    @ObservedObject var fileImporter: FileImporter
    @State private var analysisProgress: Double = 0
    @State private var isAnalyzing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Privacy badge
            HStack {
                Spacer()
                PrivacyIndicator()
                    .padding(.trailing, 20)
                    .padding(.top, 20)
            }
            
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
                .padding(.top, 20)
                
                if !isAnalyzing {
                    // Pre-analysis view
                    VStack(spacing: 32) {
                        // Icon with animation
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "brain")
                                .font(.system(size: 64))
                                .foregroundColor(.accentColor)
                                .symbolEffect(.pulse)
                        }
                        
                        VStack(spacing: 16) {
                            Text("Ready to analyze your conversations")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            Text("Analysis will include sentiment detection, topic extraction, and conversation patterns")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 400)
                            
                            // Privacy note
                            Label("Powered by Apple's on-device AI", systemImage: "lock.shield")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Button(action: startAnalysis) {
                            Label("Start Analysis", systemImage: "play.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.accentColor)
                                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 4)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        // Quick stats
                        QuickStatsView(fileImporter: fileImporter)
                            .padding(.top)
                    }
                } else {
                    // Analysis in progress
                    VStack(spacing: 24) {
                        // Animated brain icon
                        ZStack {
                            Circle()
                                .stroke(Color.accentColor.opacity(0.2), lineWidth: 4)
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .trim(from: 0, to: analysisProgress)
                                .stroke(Color.accentColor, lineWidth: 4)
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.1), value: analysisProgress)
                            
                            Image(systemName: "brain")
                                .font(.system(size: 48))
                                .foregroundColor(.accentColor)
                                .symbolEffect(.variableColor.iterative)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Analyzing conversations...")
                                .font(.headline)
                            
                            Text("\(Int(analysisProgress * 100))% Complete")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: analysisProgress)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 400)
                        
                        Label("Processing locally on your Mac", systemImage: "cpu")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func startAnalysis() {
        isAnalyzing = true
        analysisProgress = 0 // Reset progress
        
        // Simulate analysis progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if analysisProgress < 1.0 {
                analysisProgress = min(analysisProgress + 0.02, 1.0)
            } else {
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
            VStack(spacing: 0) {
                // Privacy badge
                HStack {
                    Spacer()
                    PrivacyIndicator()
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                }
                
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
                    .padding(.top, 20)
                    
                    // Stats Grid with improved design
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
                    
                    // Participant breakdown with improved styling
                    if !fileImporter.uniqueParticipants.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("Participants", systemImage: "person.3")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(fileImporter.uniqueParticipants.count) people")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(fileImporter.messagesByParticipant.sorted(by: { $0.key < $1.key }), id: \.key) { participant, messages in
                                    ParticipantRow(participant: participant, messages: messages, total: fileImporter.totalMessages)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                            )
                        }
                        .frame(maxWidth: 600)
                        .padding(.horizontal, 40)
                    }
                    
                    // Privacy footer
                    VStack(spacing: 8) {
                        Label("All insights are generated locally", systemImage: "checkmark.shield")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text("Your messages never leave your computer")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
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
        HStack(spacing: 24) {
            QuickStat(
                label: "Messages",
                value: "\(fileImporter.totalMessages)",
                icon: "message.fill",
                color: .blue
            )
            QuickStat(
                label: "Participants",
                value: "\(fileImporter.uniqueParticipants.count)",
                icon: "person.2.fill",
                color: .purple
            )
            
            let timespan = fileImporter.conversationTimespan
            if let start = timespan.start {
                QuickStat(
                    label: "Since",
                    value: start.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

struct QuickStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
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
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Privacy Indicator
struct PrivacyIndicator: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            Text("Local Processing")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.1))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Participant Row
struct ParticipantRow: View {
    let participant: String
    let messages: [Message]
    let total: Int
    
    var body: some View {
        HStack {
            Image(systemName: participant == "Me" ? "person.fill" : "person")
                .font(.system(size: 14))
                .foregroundColor(participant == "Me" ? .accentColor : .secondary)
                .frame(width: 20)
            
            Text(participant)
                .font(.system(size: 14))
                .fontWeight(participant == "Me" ? .medium : .regular)
            
            Spacer()
            
            Text("\(messages.count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
            
            // Bar visualization
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(participant == "Me" ? Color.accentColor : Color.secondary)
                        .opacity(0.5)
                        .frame(width: geometry.size.width * (Double(messages.count) / Double(total)))
                }
            }
            .frame(width: 100, height: 16)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
