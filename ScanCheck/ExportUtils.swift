import Foundation
import UIKit

struct ExportUtils {
    static func formatDateForExport(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }

    static func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }

    static func shareFile(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true, completion: nil)
        }
    }
}

struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: String
}

struct ExportCheckData {
    let id: String
    let creationDate: String
    let amount: String
    let bank: String
    let recipient: String
    let place: String
    let checkDate: String
    let checkNumber: String
    let notes: String
}

struct PDFCheckData {
    let id: UUID
    let creationDate: Date
    let amount: Double
    let bank: String?
    let recipient: String?
    let place: String?
    let checkDate: Date?
    let checkNumber: String?
    let notes: String?
    let imageData: Data?
}
