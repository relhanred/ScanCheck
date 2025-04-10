import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var checks: [Check]
    @State private var selectedTab = 0
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage? = nil
    @State private var isImageReady = false
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationStack {
            Group {
                if checks.isEmpty {
                    EmptyChecksView(onAddButtonTapped: {
                        showingImagePicker = true
                    })
                } else {
                    VStack {
                        Picker("", selection: $selectedTab) {
                            Text("Résumé").tag(0)
                            Text("Par banque").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        ScrollView {
                            VStack(spacing: 24) {
                                switch selectedTab {
                                case 0:
                                    summaryView
                                case 1:
                                    bankChartView
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
            .sheet(isPresented: $showingCamera) {
                CameraCaptureView { image in
                    handleCapturedImage(image)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                GalleryPickerView { image in
                    handleCapturedImage(image)
                }
            }
            .sheet(isPresented: $isImageReady) {
                if let image = capturedImage {
                    CheckFormView(image: image)
                }
            }
            .overlay {
                if isAnalyzing {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        
                        Text("Préparation de l'image...")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 10)
                    }
                    .frame(width: 250, height: 150)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                }
            }
        }
    }
    
    private var summaryView: some View {
        VStack(spacing: 24) {
            Text("Résumé global")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
            
            HStack(spacing: 16) {
                SummaryCard(
                    title: "Total chèques",
                    value: "\(checks.count)",
                    icon: "doc.text.viewfinder",
                    color: .blue
                )
                
                SummaryCard(
                    title: "Montant total",
                    value: String(format: "%.2f €", checks.reduce(0) { $0 + $1.amount }),
                    icon: "eurosign.circle.fill",
                    color: .green
                )
            }
            
            VStack(spacing: 16) {
                if let maxCheck = checks.max(by: { $0.amount < $1.amount }) {
                    DetailCard(
                        title: "Chèque le plus élevé",
                        value: String(format: "%.2f €", maxCheck.amount),
                        subtitle: maxCheck.recipient ?? maxCheck.bank ?? "Sans détail",
                        icon: "arrow.up.circle.fill",
                        color: .orange
                    )
                }
                
                if let minCheck = checks.min(by: { $0.amount < $1.amount }) {
                    DetailCard(
                        title: "Chèque le plus petit",
                        value: String(format: "%.2f €", minCheck.amount),
                        subtitle: minCheck.recipient ?? minCheck.bank ?? "Sans détail",
                        icon: "arrow.down.circle.fill",
                        color: .purple
                    )
                }
                
                DetailCard(
                    title: "Montant moyen par chèque",
                    value: String(format: "%.2f €", checks.isEmpty ? 0 : checks.reduce(0) { $0 + $1.amount } / Double(checks.count)),
                    subtitle: "Calculé sur \(checks.count) chèque\(checks.count > 1 ? "s" : "")",
                    icon: "number.circle.fill",
                    color: .indigo
                )
            }
            
            Divider()
                .padding(.vertical, 8)
            
            lastChecksView
        }
    }
    
    private var lastChecksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Derniers chèques")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(checks.sorted(by: { $0.creationDate > $1.creationDate }).prefix(3)) { check in
                RecentCheckCard(check: check)
            }
        }
    }
    
    private var bankChartView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Répartition par banque")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let bankData = getBankData()
            
            if bankData.isEmpty {
                ContentUnavailableView {
                    Label("Aucune donnée", systemImage: "chart.bar.xaxis")
                } description: {
                    Text("Ajoutez des banques à vos chèques pour voir des statistiques")
                }
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    Chart(bankData) { item in
                        BarMark(
                            x: .value("Montant", item.amount),
                            y: .value("Banque", item.name)
                        )
                        .foregroundStyle(by: .value("Banque", item.name))
                        .cornerRadius(8)
                    }
                    .frame(height: CGFloat(bankData.count * 60 + 50))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    VStack(spacing: 16) {
                        ForEach(bankData) { item in
                            BankItemCard(bankItem: item)
                        }
                    }
                }
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    private func handleCapturedImage(_ image: UIImage?) {
        isAnalyzing = true
        
        guard let image = image else {
            isAnalyzing = false
            return
        }
        
        DispatchQueue.main.async {
            let imageCopy = image.copy() as! UIImage
            self.capturedImage = imageCopy
            self.isAnalyzing = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isImageReady = true
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(color)
                    .cornerRadius(10)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.leading, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct DetailCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct RecentCheckCard: View {
    let check: Check
    
    var body: some View {
        HStack(spacing: 16) {
            if let imageData = check.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(check.recipient ?? check.bank ?? "Chèque")
                    .font(.headline)
                
                if let checkDate = check.checkDate {
                    Text(formatDate(checkDate: checkDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(String(format: "%.2f €", check.amount))
                .font(.headline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatDate(checkDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: checkDate)
    }
}

struct BankItemCard: View {
    let bankItem: BankData
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(bankItem.name.prefix(1).uppercased()))
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bankItem.name)
                    .font(.headline)
                
                Text("\(bankItem.count) chèque\(bankItem.count > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.2f €", bankItem.amount))
                .font(.headline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
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
