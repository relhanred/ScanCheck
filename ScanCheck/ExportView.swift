import SwiftUI
import SwiftData

struct ExportView: View {
    @Query private var checks: [Check]
    @State private var showingPremiumAlert = false
    @State private var selectedFormat: ExportFormat?
    
    enum ExportFormat: String {
        case pdf = "PDF"
        case excel = "Excel"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if checks.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun chèque à exporter", systemImage: "square.and.arrow.up")
                    } description: {
                        Text("Ajoutez d'abord des chèques pour pouvoir les exporter")
                    } actions: {
                        Button {
                            AppState.shared.showAddSheet = true
                        } label: {
                            Text("Ajouter un chèque")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.black)
                    }
                } else {
                    List {
                        Section(header: Text("Options d'exportation")) {
                            Button {
                                selectedFormat = .pdf
                                showingPremiumAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "doc.richtext")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Exporter en PDF")
                                            .foregroundColor(.primary)
                                        Text("Tous les chèques avec leurs images")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                            
                            Button {
                                selectedFormat = .excel
                                showingPremiumAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "tablecells")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Exporter en Excel")
                                            .foregroundColor(.primary)
                                        Text("Données tabulaires pour analyse")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        
                        Section(header: Text("Statistiques")) {
                            HStack {
                                Image(systemName: "number")
                                    .foregroundColor(.blue)
                                    .frame(width: 32)
                                Text("Nombre de chèques")
                                Spacer()
                                Text("\(checks.count)")
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Image(systemName: "eurosign")
                                    .foregroundColor(.blue)
                                    .frame(width: 32)
                                Text("Montant total")
                                Spacer()
                                Text(String(format: "%.2f €", checks.reduce(0) { $0 + $1.amount }))
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Export")
            .alert("Fonctionnalité Premium", isPresented: $showingPremiumAlert) {
                Button("S'abonner", role: .none) {
                    // Action pour s'abonner
                }
                Button("Plus tard", role: .cancel) {}
            } message: {
                if selectedFormat == .pdf {
                    Text("L'export PDF est disponible avec l'abonnement ScanCheck Premium.")
                } else {
                    Text("L'export Excel est disponible avec l'abonnement ScanCheck Premium.")
                }
            }
        }
    }
}

#Preview {
    ExportView()
        .modelContainer(for: Check.self, inMemory: true)
}
