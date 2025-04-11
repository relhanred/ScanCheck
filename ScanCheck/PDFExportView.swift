import SwiftUI
import SwiftData
import PDFKit
import UIKit

struct PDFExportView: View {
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
                
                Button(action: exportToPDF) {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Exporter en PDF")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedChecks.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(selectedChecks.isEmpty || isExporting)
                .padding()
            }
            .navigationTitle("Export PDF")
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
                    message: Text("Le fichier PDF a été créé avec succès"),
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
    
    private func exportToPDF() {
        isExporting = true
        
        // Préparation des données sur le thread principal
        let selectedChecksArray = checks.filter { selectedChecks.contains($0.id) }
        
        // Création d'un modèle intermédiaire qui contient toutes les données nécessaires
        let exportData = selectedChecksArray.map { check -> PDFCheckData in
            let imageData = check.imageData
            return PDFCheckData(
                id: check.id,
                creationDate: check.creationDate,
                amount: check.amount,
                bank: check.bank,
                recipient: check.recipient,
                place: check.place,
                checkDate: check.checkDate,
                checkNumber: check.checkNumber,
                notes: check.notes,
                imageData: imageData
            )
        }
        
        // Export sur un thread en arrière-plan avec les données déjà préparées
        Task {
            do {
                let pdfData = createPDF(for: exportData)
                
                let fileManager = FileManager.default
                let tempDirectoryURL = fileManager.temporaryDirectory
                let fileName = "ScanCheck_Export_\(ExportUtils.formatDateForExport(Date())).pdf"
                let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
                
                try pdfData.write(to: fileURL)
                
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
    
    private func createPDF(for checks: [PDFCheckData]) -> Data {
        let pageWidth = 595.2
        let pageHeight = 841.8
        let margin: CGFloat = 40
        
        let pdfMetaData = [
            kCGPDFContextCreator: "ScanCheck",
            kCGPDFContextAuthor: "Utilisateur ScanCheck",
            kCGPDFContextTitle: "Export ScanCheck"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )
        
        let data = renderer.pdfData { context in
            for (index, check) in checks.enumerated() {
                context.beginPage()
                
                let titleFont = UIFont.boldSystemFont(ofSize: 24)
                let headerFont = UIFont.boldSystemFont(ofSize: 16)
                let normalFont = UIFont.systemFont(ofSize: 14)
                let smallFont = UIFont.systemFont(ofSize: 12)
                
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .foregroundColor: UIColor.black
                ]
                
                let headerAttributes: [NSAttributedString.Key: Any] = [
                    .font: headerFont,
                    .foregroundColor: UIColor.black
                ]
                
                let normalAttributes: [NSAttributedString.Key: Any] = [
                    .font: normalFont,
                    .foregroundColor: UIColor.black
                ]
                
                let smallAttributes: [NSAttributedString.Key: Any] = [
                    .font: smallFont,
                    .foregroundColor: UIColor.darkGray
                ]
                
                let title = "Détails du chèque \(index + 1)/\(checks.count)"
                let titleString = NSAttributedString(string: title, attributes: titleAttributes)
                titleString.draw(at: CGPoint(x: margin, y: margin))
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                dateFormatter.timeStyle = .none
                dateFormatter.locale = Locale(identifier: "fr_FR")
                
                // Draw check image if available
                if let imageData = check.imageData, let image = UIImage(data: imageData) {
                    let maxHeight: CGFloat = 200
                    let aspectRatio = image.size.width / image.size.height
                    let width = min(pageWidth - 2 * margin, image.size.width)
                    let height = min(maxHeight, width / aspectRatio)
                    
                    let rect = CGRect(x: margin, y: margin + 40, width: width, height: height)
                    image.draw(in: rect)
                    
                    // Information section
                    let infoY = margin + 50 + height
                    
                    // Montant
                    let amountHeader = NSAttributedString(string: "Montant:", attributes: headerAttributes)
                    amountHeader.draw(at: CGPoint(x: margin, y: infoY))
                    
                    let amount = String(format: "%.2f €", check.amount)
                    let amountText = NSAttributedString(string: amount, attributes: normalAttributes)
                    amountText.draw(at: CGPoint(x: margin + 100, y: infoY))
                    
                    // Banque
                    if let bank = check.bank, !bank.isEmpty {
                        let bankHeader = NSAttributedString(string: "Banque:", attributes: headerAttributes)
                        bankHeader.draw(at: CGPoint(x: margin, y: infoY + 25))
                        
                        let bankText = NSAttributedString(string: bank, attributes: normalAttributes)
                        bankText.draw(at: CGPoint(x: margin + 100, y: infoY + 25))
                    }
                    
                    // Destinataire
                    if let recipient = check.recipient, !recipient.isEmpty {
                        let recipientHeader = NSAttributedString(string: "À l'ordre de:", attributes: headerAttributes)
                        recipientHeader.draw(at: CGPoint(x: margin, y: infoY + 50))
                        
                        let recipientText = NSAttributedString(string: recipient, attributes: normalAttributes)
                        recipientText.draw(at: CGPoint(x: margin + 100, y: infoY + 50))
                    }
                    
                    // Lieu
                    if let place = check.place, !place.isEmpty {
                        let placeHeader = NSAttributedString(string: "Lieu:", attributes: headerAttributes)
                        placeHeader.draw(at: CGPoint(x: margin, y: infoY + 75))
                        
                        let placeText = NSAttributedString(string: place, attributes: normalAttributes)
                        placeText.draw(at: CGPoint(x: margin + 100, y: infoY + 75))
                    }
                    
                    // Date du chèque
                    if let checkDate = check.checkDate {
                        let dateHeader = NSAttributedString(string: "Date du chèque:", attributes: headerAttributes)
                        dateHeader.draw(at: CGPoint(x: margin, y: infoY + 100))
                        
                        let dateText = NSAttributedString(string: dateFormatter.string(from: checkDate), attributes: normalAttributes)
                        dateText.draw(at: CGPoint(x: margin + 100, y: infoY + 100))
                    }
                    
                    // Numéro de chèque
                    if let checkNumber = check.checkNumber, !checkNumber.isEmpty {
                        let numberHeader = NSAttributedString(string: "N° de chèque:", attributes: headerAttributes)
                        numberHeader.draw(at: CGPoint(x: margin, y: infoY + 125))
                        
                        let numberText = NSAttributedString(string: checkNumber, attributes: normalAttributes)
                        numberText.draw(at: CGPoint(x: margin + 100, y: infoY + 125))
                    }
                    
                    // Notes
                    if let notes = check.notes, !notes.isEmpty {
                        let notesHeader = NSAttributedString(string: "Notes:", attributes: headerAttributes)
                        notesHeader.draw(at: CGPoint(x: margin, y: infoY + 150))
                        
                        let notesText = NSAttributedString(string: notes, attributes: normalAttributes)
                        
                        // Draw multi-line notes
                        let textRect = CGRect(x: margin, y: infoY + 175, width: pageWidth - 2 * margin, height: 100)
                        notesText.draw(in: textRect)
                    }
                    
                    // Date de scan
                    let scanDateText = "Scanné le " + dateFormatter.string(from: check.creationDate)
                    let scanDateString = NSAttributedString(string: scanDateText, attributes: smallAttributes)
                    scanDateString.draw(at: CGPoint(x: margin, y: pageHeight - margin - 20))
                } else {
                    // No image, adjust the layout
                    let infoY = margin + 60
                    
                    let noImageText = NSAttributedString(string: "Image non disponible", attributes: headerAttributes)
                    noImageText.draw(at: CGPoint(x: margin, y: infoY - 30))
                    
                    // Montant
                    let amountHeader = NSAttributedString(string: "Montant:", attributes: headerAttributes)
                    amountHeader.draw(at: CGPoint(x: margin, y: infoY))
                    
                    let amount = String(format: "%.2f €", check.amount)
                    let amountText = NSAttributedString(string: amount, attributes: normalAttributes)
                    amountText.draw(at: CGPoint(x: margin + 100, y: infoY))
                    
                    // Banque
                    if let bank = check.bank, !bank.isEmpty {
                        let bankHeader = NSAttributedString(string: "Banque:", attributes: headerAttributes)
                        bankHeader.draw(at: CGPoint(x: margin, y: infoY + 25))
                        
                        let bankText = NSAttributedString(string: bank, attributes: normalAttributes)
                        bankText.draw(at: CGPoint(x: margin + 100, y: infoY + 25))
                    }
                    
                    // Destinataire
                    if let recipient = check.recipient, !recipient.isEmpty {
                        let recipientHeader = NSAttributedString(string: "À l'ordre de:", attributes: headerAttributes)
                        recipientHeader.draw(at: CGPoint(x: margin, y: infoY + 50))
                        
                        let recipientText = NSAttributedString(string: recipient, attributes: normalAttributes)
                        recipientText.draw(at: CGPoint(x: margin + 100, y: infoY + 50))
                    }
                    
                    // Lieu
                    if let place = check.place, !place.isEmpty {
                        let placeHeader = NSAttributedString(string: "Lieu:", attributes: headerAttributes)
                        placeHeader.draw(at: CGPoint(x: margin, y: infoY + 75))
                        
                        let placeText = NSAttributedString(string: place, attributes: normalAttributes)
                        placeText.draw(at: CGPoint(x: margin + 100, y: infoY + 75))
                    }
                    
                    // Date du chèque
                    if let checkDate = check.checkDate {
                        let dateHeader = NSAttributedString(string: "Date du chèque:", attributes: headerAttributes)
                        dateHeader.draw(at: CGPoint(x: margin, y: infoY + 100))
                        
                        let dateText = NSAttributedString(string: dateFormatter.string(from: checkDate), attributes: normalAttributes)
                        dateText.draw(at: CGPoint(x: margin + 100, y: infoY + 100))
                    }
                    
                    // Numéro de chèque
                    if let checkNumber = check.checkNumber, !checkNumber.isEmpty {
                        let numberHeader = NSAttributedString(string: "N° de chèque:", attributes: headerAttributes)
                        numberHeader.draw(at: CGPoint(x: margin, y: infoY + 125))
                        
                        let numberText = NSAttributedString(string: checkNumber, attributes: normalAttributes)
                        numberText.draw(at: CGPoint(x: margin + 100, y: infoY + 125))
                    }
                    
                    // Notes
                    if let notes = check.notes, !notes.isEmpty {
                        let notesHeader = NSAttributedString(string: "Notes:", attributes: headerAttributes)
                        notesHeader.draw(at: CGPoint(x: margin, y: infoY + 150))
                        
                        let notesText = NSAttributedString(string: notes, attributes: normalAttributes)
                        
                        // Draw multi-line notes
                        let textRect = CGRect(x: margin, y: infoY + 175, width: pageWidth - 2 * margin, height: 100)
                        notesText.draw(in: textRect)
                    }
                    
                    // Date de scan
                    let scanDateText = "Scanné le " + dateFormatter.string(from: check.creationDate)
                    let scanDateString = NSAttributedString(string: scanDateText, attributes: smallAttributes)
                    scanDateString.draw(at: CGPoint(x: margin, y: pageHeight - margin - 20))
                }
                
                // Page number
                let pageText = "Page \(index + 1) sur \(checks.count)"
                let pageString = NSAttributedString(string: pageText, attributes: smallAttributes)
                let pageStringSize = pageString.size()
                pageString.draw(at: CGPoint(x: pageWidth - margin - pageStringSize.width, y: pageHeight - margin - 20))
            }
        }
        
        return data
    }
    
    private func shareFile(url: URL) {
        ExportUtils.shareFile(url: url)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}
//
