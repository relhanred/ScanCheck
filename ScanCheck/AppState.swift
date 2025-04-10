import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var showAddSheet = false
    @Published var selectedTab: TabBarView.Tab = .home
    
    private init() {}
}
