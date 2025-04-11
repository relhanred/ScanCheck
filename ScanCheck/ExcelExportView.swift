import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExcelExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var checks: [Check]
    
    @State private var selectedChecks: Set<UUID> = []
    @State private var isExporting = false
    @State private var exportError: String? = nil
    @State private var showExportSuccess = false
    @State private var exportedFileURL: URL? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("\(selectedChecks.count) chèques sélectionnés")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        if selectedChecks.count == checks.count {
                            selectedChecks.removeAll()
                        } else {
                            selectedChecks = Set(checks.map { $0.id })
                        }
                    }) {
                        Text(selectedChecks.count == checks.count ? "Tout désélectionner" : "Tout sélectionner")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                
                List {
                    ForEach(checks) { check in
                        CheckSelectionRow(
                            check: check,
                            isSelected: selectedChecks.contains(check.id),
                            onToggle: { isSelected in
                                if isSelected {
                                    selectedChecks.insert(check.id)
                                } else {
                                    selectedChecks.remove(check.id)
                                }
                            }
                        )
                    }
                }
                .listStyle(.plain)
                
                Button(action: exportToExcel) {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Exporter en Excel")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedChecks.isEmpty ? Color.gray.opacity(0.3) : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(selectedChecks.isEmpty || isExporting)
                .padding()
            }
            .navigationTitle("Export Excel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Annuler")
                    }
                }
            }
            .alert(isPresented: $showExportSuccess) {
                Alert(
                    title: Text("Export réussi"),
                    message: Text("Le fichier Excel a été créé avec succès"),
                    primaryButton: .default(Text("Partager"), action: {
                        if let url = exportedFileURL {
                            shareFile(url: url)
                        }
                    }),
                    secondaryButton: .default(Text("OK"))
                )
            }
            .alert(item: Binding(
                get: { exportError.map { ErrorWrapper(error: $0) } },
                set: { exportError = $0?.error }
            )) { errorWrapper in
                Alert(
                    title: Text("Erreur d'export"),
                    message: Text(errorWrapper.error),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                selectedChecks = Set(checks.map { $0.id })
            }
        }
    }
    
    private func exportToExcel() {
        isExporting = true
        
        // Préparation des données sur le thread principal
        let selectedChecksArray = checks.filter { selectedChecks.contains($0.id) }
        
        // Création d'un modèle intermédiaire qui contient toutes les données nécessaires
                        let exportData = selectedChecksArray.map { check -> ExportCheckData in
            return ExportCheckData(
                id: check.id.uuidString,
                creationDate: ExportUtils.formatDateForExport(check.creationDate),
                amount: String(format: "%.2f", check.amount),
                bank: check.bank?.replacingOccurrences(of: ",", with: ";") ?? "",
                recipient: check.recipient?.replacingOccurrences(of: ",", with: ";") ?? "",
                place: check.place?.replacingOccurrences(of: ",", with: ";") ?? "",
                checkDate: check.checkDate != nil ? ExportUtils.formatDateForExport(check.checkDate!) : "",
                checkNumber: check.checkNumber ?? "",
                notes: check.notes?.replacingOccurrences(of: ",", with: ";").replacingOccurrences(of: "\n", with: " ") ?? ""
            )
        }
        
        // Export sur un thread en arrière-plan avec les données déjà préparées
        Task {
            do {
                let csvString = createCSV(from: exportData)
                
                let fileManager = FileManager.default
                let tempDirectoryURL = fileManager.temporaryDirectory
                let fileName = "ScanCheck_Export_\(ExportUtils.formatDateForExport(Date())).csv"
                let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
                
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                
                await MainActor.run {
                    isExporting = false
                    exportedFileURL = fileURL
                    showExportSuccess = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                }
            }
        }
    }
    
    private func createCSV(from data: [ExportCheckData]) -> String {
        var csvString = "ID,Date de création,Montant,Banque,Destinataire,Lieu,Date du chèque,Numéro de chèque,Notes\n"
        
        for item in data {
            let row = "\"\(item.id)\",\"\(item.creationDate)\",\"\(item.amount)\",\"\(item.bank)\",\"\(item.recipient)\",\"\(item.place)\",\"\(item.checkDate)\",\"\(item.checkNumber)\",\"\(item.notes)\"\n"
            csvString.append(row)
        }
        
        return csvString
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    private func shareFile(url: URL) {
        ExportUtils.shareFile(url: url)
    }
}

struct CheckSelectionRow: View {
    let check: Check
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.system(size: 20))
                
                if let imageData = check.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "doc.text.viewfinder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(8)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading) {
                    Text(check.recipient ?? check.bank ?? "Chèque")
                        .font(.headline)
                    if let checkDate = check.checkDate {
                        Text(formatDate(checkDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(String(format: "%.2f €", check.amount))
                    .font(.headline)
                    .foregroundColor(.black)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        return formatDateForDisplay(date)
    }
}
