import Foundation
import SwiftData

class CheckLimitManager {
    static let shared = CheckLimitManager()
    
    private let freeChecksLimit = 5
    
    private init() {}
    
    @MainActor
    func canAddMoreChecks(modelContainer: ModelContainer?) -> Bool {
        let count = getChecksCount(modelContainer: modelContainer)
        return count < freeChecksLimit
    }
    
    @MainActor
    func remainingChecks(modelContainer: ModelContainer?) -> Int {
        let count = getChecksCount(modelContainer: modelContainer)
        return max(0, freeChecksLimit - count)
    }
    
    @MainActor
    private func getChecksCount(modelContainer: ModelContainer?) -> Int {
        guard let modelContainer = modelContainer else { return 0 }
        
        let descriptor = FetchDescriptor<Check>()
        do {
            return try modelContainer.mainContext.fetchCount(descriptor)
        } catch {
            print("Error fetching checks count: \(error)")
            return 0
        }
    }
}
