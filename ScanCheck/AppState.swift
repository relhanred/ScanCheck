import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var selectedTab: TabBarView.Tab = .home
    
    private init() {}
}
