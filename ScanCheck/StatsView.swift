import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var checks: [Check]
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            Group {
                if checks.isEmpty {
                    EmptyChecksView(onAddButtonTapped: {
                        AppState.shared.showAddSheet = true
                    })
                } else {
                    VStack {
                        Picker("", selection: $selectedTab) {
                            Text("Résumé").tag(0)
                            Text("Par banque").tag(1)
                            Text("Dans le temps").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        ScrollView {
                            VStack(spacing: 20) {
                                switch selectedTab {
                                case 0:
                                    summaryView
                                case 1:
                                    bankChartView
                                case 2:
                                    timeChartView
                                default:
                                    summaryView
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Statistiques")
        }
    }
    
    private var summaryView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Résumé global")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                HStack {
                    StatCard(
                        title: "Total chèques",
                        value: "\(checks.count)",
                        icon: "doc.text.viewfinder",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Montant total",
                        value: String(format: "%.2f €", checks.reduce(0) { $0 + $1.amount }),
                        icon: "eurosign.circle.fill",
                        color: .green
                    )
                }
                
                if let maxCheck = checks.max(by: { $0.amount < $1.amount }) {
                    StatCard(
                        title: "Chèque le plus élevé",
                        value: String(format: "%.2f €", maxCheck.amount),
                        icon: "arrow.up.circle.fill",
                        color: .orange,
                        fullWidth: true
                    )
                }
                
                if let minCheck = checks.min(by: { $0.amount < $1.amount }) {
                    StatCard(
                        title: "Chèque le plus petit",
                        value: String(format: "%.2f €", minCheck.amount),
                        icon: "arrow.down.circle.fill",
                        color: .purple,
                        fullWidth: true
                    )
                }
                
                StatCard(
                    title: "Montant moyen",
                    value: String(format: "%.2f €", checks.isEmpty ? 0 : checks.reduce(0) { $0 + $1.amount } / Double(checks.count)),
                    icon: "number.circle.fill",
                    color: .indigo,
                    fullWidth: true
                )
            }
            
            Divider()
            
            lastChecksView
        }
    }
    
    private var lastChecksView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Derniers chèques")
                .font(.headline)
            
            ForEach(checks.sorted(by: { $0.creationDate > $1.creationDate }).prefix(3)) { check in
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "eurosign")
                                .foregroundColor(.blue)
                        )
                    
                    VStack(alignment: .leading) {
                        Text(check.recipient ?? check.bank ?? "Chèque")
                            .fontWeight(.medium)
                        
                        if let checkDate = check.checkDate {
                            Text(formatDate(checkDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(String(format: "%.2f €", check.amount))
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    private var bankChartView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Répartition par banque")
                .font(.headline)
            
            let bankData = getBankData()
            
            if bankData.isEmpty {
                ContentUnavailableView {
                    Label("Aucune donnée", systemImage: "chart.bar.xaxis")
                } description: {
                    Text("Ajoutez des banques à vos chèques pour voir des statistiques")
                }
            } else {
                Chart(bankData) { item in
                    BarMark(
                        x: .value("Montant", item.amount),
                        y: .value("Banque", item.name)
                    )
                    .foregroundStyle(by: .value("Banque", item.name))
                }
                .frame(height: CGFloat(bankData.count * 50 + 50))
                
                Divider()
                
                ForEach(bankData) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("\(item.count) chèque\(item.count > 1 ? "s" : "")")
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f €", item.amount))
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }
    
    private var timeChartView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Évolution dans le temps")
                .font(.headline)
            
            let timeData = getTimeData()
            
            if timeData.isEmpty {
                ContentUnavailableView {
                    Label("Données insuffisantes", systemImage: "chart.line.uptrend.xyaxis")
                } description: {
                    Text("Ajoutez plus de chèques pour voir des tendances")
                }
            } else {
                Chart(timeData) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Montant", item.amount)
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Montant", item.amount)
                    )
                }
                .frame(height: 250)
                .chartYScale(domain: 0...timeData.map { $0.amount }.max()! * 1.1)
            }
        }
    }
    
    private func getBankData() -> [BankData] {
        let grouped = Dictionary(grouping: checks) { check in
            check.bank ?? "Non spécifié"
        }
        
        return grouped.map { bank, bankChecks in
            BankData(
                id: UUID(),
                name: bank,
                amount: bankChecks.reduce(0) { $0 + $1.amount },
                count: bankChecks.count
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    private func getTimeData() -> [TimeData] {
        let dateChecks = checks.filter { $0.checkDate != nil }
        
        guard dateChecks.count > 1 else { return [] }
        
        let sorted = dateChecks.sorted { $0.checkDate! < $1.checkDate! }
        
        return sorted.map { check in
            TimeData(
                id: check.id,
                date: check.checkDate!,
                amount: check.amount
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var fullWidth: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct BankData: Identifiable {
    let id: UUID
    let name: String
    let amount: Double
    let count: Int
}

struct TimeData: Identifiable {
    let id: UUID
    let date: Date
    let amount: Double
}

#Preview {
    StatsView()
        .modelContainer(for: Check.self, inMemory: true)
}
