import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var checks: [Check]
    @State private var showingScannerSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if checks.isEmpty {
                    EmptyChecksView(onScanButtonTapped: {
                        showingScannerSheet = true
                    })
                } else {
                    List {
                        ForEach(checks) { check in
                            CheckRowView(check: check)
                        }
                        .onDelete(perform: deleteChecks)
                    }
                }
            }
            .navigationTitle("Mes Chèques")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingScannerSheet = true
                    }) {
                        Label("Scanner un chèque", systemImage: "camera")
                    }
                }
            }
            .sheet(isPresented: $showingScannerSheet) {
                CheckScannerView()
            }
        }
    }
    
    private func deleteChecks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(checks[index])
            }
        }
    }
}

struct EmptyChecksView: View {
    var onScanButtonTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 70))
                .foregroundColor(.blue)
            
            Text("Aucun chèque enregistré")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Scannez votre premier chèque pour commencer")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onScanButtonTapped) {
                HStack {
                    Image(systemName: "camera")
                    Text("Scanner un chèque")
                }
                .font(.headline)
                .padding()
                .frame(minWidth: 200)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

struct CheckRowView: View {
    let check: Check
    
    var body: some View {
        NavigationLink {
            CheckDetailView(check: check)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(check.issuerName)
                        .font(.headline)
                    Text("N° \(check.checkNumber ?? "Non spécifié")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(String(format: "%.2f €", check.amount))
                    .font(.headline)
                    .foregroundColor(check.amount > 0 ? .green : .primary)
            }
            .padding(.vertical, 4)
        }
    }
}

struct CheckDetailView: View {
    let check: Check
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let imageData = check.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(8)
                } else {
                    ContentUnavailableView {
                        Label("Pas d'image", systemImage: "photo")
                    } description: {
                        Text("L'image du chèque n'est pas disponible")
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    DetailRow(title: "Émetteur", value: check.issuerName)
                    DetailRow(title: "Montant", value: String(format: "%.2f €", check.amount))
                    DetailRow(title: "N° de chèque", value: check.checkNumber ?? "Non spécifié")
                    DetailRow(title: "Date de scan", value: check.scanDate.formatted(date: .long, time: .shortened))
                    
                    if let notes = check.notes, !notes.isEmpty {
                        Divider()
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 1)
            }
            .padding()
        }
        .navigationTitle("Détails du chèque")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title + " :")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Check.self, inMemory: true)
}
