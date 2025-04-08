//
//  Check.swift
//  ScanCheck
//
//  Created by El hanti Redha on 08/04/2025.
//

import Foundation
import SwiftData

@Model
final class Check {
    var id: UUID
    var scanDate: Date
    var amount: Double
    var issuerName: String
    var checkNumber: String?
    var imageData: Data?
    var notes: String?
    
    init(amount: Double, issuerName: String, scanDate: Date = Date(), checkNumber: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.scanDate = scanDate
        self.amount = amount
        self.issuerName = issuerName
        self.checkNumber = checkNumber
        self.notes = notes
    }
}
