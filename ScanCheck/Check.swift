import Foundation
import SwiftData

@Model
final class Check {
    var id: UUID
    var creationDate: Date
    var amount: Double
    var bank: String?
    var recipient: String?
    var place: String?
    var checkDate: Date?
    var checkNumber: String?
    var imageData: Data?
    var notes: String?
    
    init(amount: Double, bank: String? = nil, recipient: String? = nil, place: String? = nil,
         checkDate: Date? = nil, checkNumber: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.creationDate = Date()
        self.amount = amount
        self.bank = bank
        self.recipient = recipient
        self.place = place
        self.checkDate = checkDate
        self.checkNumber = checkNumber
        self.notes = notes
    }
}
