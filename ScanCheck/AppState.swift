import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var showAddSheet = false
    @Published var selectedTab: TabBarView.Tab = .home
    @Published var navigatingToCamera = false
    @Published var navigatingToImagePicker = false
    
    private init() {}
}
