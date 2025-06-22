import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FileInputView()
                .tabItem {
                    Image(systemName: "doc.badge.plus")
                    Text("Import")
                }
                .tag(0)
            
            AnalysisView()
                .tabItem {
                    Image(systemName: "brain")
                    Text("Analysis")
                }
                .tag(1)
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Statistics")
                }
                .tag(2)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct FileInputView: View {
    var body: some View {
        VStack {
            Text("File Import")
                .font(.largeTitle)
            Text("Drag and drop your iMessage export file here")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AnalysisView: View {
    var body: some View {
        VStack {
            Text("AI Analysis")
                .font(.largeTitle)
            Text("Local analysis results will appear here")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatsView: View {
    var body: some View {
        VStack {
            Text("Statistics")
                .font(.largeTitle)
            Text("Message statistics and insights")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}