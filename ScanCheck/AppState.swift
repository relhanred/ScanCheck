import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var selectedTab: TabBarView.Tab = .home
    @Published var isPremium: Bool {
        didSet {
            UserDefaults.standard.setValue(isPremium, forKey: "isPremium")
        }
    }
    @Published var isUserLoggedIn: Bool {
        didSet {
            UserDefaults.standard.setValue(isUserLoggedIn, forKey: "isUserLoggedIn")
        }
    }
    
    private init() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        isUserLoggedIn = UserDefaults.standard.bool(forKey: "isUserLoggedIn")
    }
}
