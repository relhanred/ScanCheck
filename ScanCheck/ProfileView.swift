import SwiftUI
import SwiftData

struct ProfileView: View {
    @StateObject private var appState = AppState.shared
    @State private var showLoginOptions = false
    @State private var showPremiumOptions = false
    @Query private var checks: [Check]
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage? = nil
    @State private var isImageReady = false
    @State private var isAnalyzing = false
    @State private var showPremiumView = false
    
    private let freeChecksLimit = 5
    
    private var remainingFreeChecks: Int {
        let modelContainer = try? ModelContainer(for: Check.self)
        return CheckLimitManager.shared.remainingChecks(modelContainer: modelContainer)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: appState.isUserLoggedIn ? "person.circle.fill" : "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(appState.isUserLoggedIn ? "Utilisateur" : "Invité")
                                .font(.headline)
                            Text(appState.isUserLoggedIn ? "Connecté" : "Non connecté")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            if appState.isUserLoggedIn {
                                // Se déconnecter
                                appState.isUserLoggedIn = false
                            } else {
                                showLoginOptions = true
                            }
                        } label: {
                            Text(appState.isUserLoggedIn ? "Se déconnecter" : "Se connecter")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Abonnement")) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(appState.isPremium ? "Premium" : "Gratuit")
                                .font(.headline)
                                .foregroundColor(appState.isPremium ? .yellow : .primary)
                            
                            if appState.isPremium {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                            }
                            
                            Spacer()
                            
                            if !appState.isPremium {
                                Button {
                                    showPremiumOptions = true
                                } label: {
                                    Text("Passer Premium")
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        if !appState.isPremium {
                            Text("Chèques restants : \(remainingFreeChecks)/\(freeChecksLimit)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                            
                            ProgressView(value: Double(freeChecksLimit - remainingFreeChecks), total: Double(freeChecksLimit))
                                .tint(Color.blue)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 6)
                    
                    if !appState.isPremium {
                        LimitedFeatureRow(title: "Export PDF et Excel", isPremium: appState.isPremium)
                        LimitedFeatureRow(title: "Chèques illimités", isPremium: appState.isPremium)
                        LimitedFeatureRow(title: "Synchronisation cloud", isPremium: appState.isPremium)
                    } else {
                        PremiumFeatureRow(title: "Export PDF et Excel", isActive: true)
                        PremiumFeatureRow(title: "Chèques illimités", isActive: true)
                        PremiumFeatureRow(title: "Synchronisation cloud", isActive: true)
                    }
                }
                
                Section(header: Text("Application")) {
                    Button {
                        // Action pour les paramètres
                    } label: {
                        SettingsRow(icon: "gear", title: "Paramètres")
                    }
                    
                    Button {
                        // Action pour l'aide
                    } label: {
                        SettingsRow(icon: "questionmark.circle", title: "Aide et support")
                    }
                    
                    Button {
                        // Action pour la politique de confidentialité
                    } label: {
                        SettingsRow(icon: "lock.shield", title: "Confidentialité")
                    }
                    
                    Button {
                        // Action pour les conditions d'utilisation
                    } label: {
                        SettingsRow(icon: "doc.text", title: "Conditions d'utilisation")
                    }
                }
                
                Section {
                    Text("Version 1.0.0")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Profil")
            .sheet(isPresented: $showLoginOptions) {
                LoginOptionsView(onLoginSuccess: {
                    appState.isUserLoggedIn = true
                })
            }
            .sheet(isPresented: $showPremiumOptions) {
                PremiumOptionsView(onPremiumSuccess: {
                    appState.isPremium = true
                })
            }
            .sheet(isPresented: $showingCamera) {
                CameraCaptureView { image in
                    handleCapturedImage(image)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                GalleryPickerView { image in
                    handleCapturedImage(image)
                }
            }
            .sheet(isPresented: $isImageReady) {
                if let image = capturedImage {
                    CheckFormView(image: image)
                }
            }
            .fullScreenCover(isPresented: $showPremiumView) {
                NavigationStack {
                    PremiumBlockView()
                }
            }
            .overlay {
                if isAnalyzing {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        
                        Text("Préparation de l'image...")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 10)
                    }
                    .frame(width: 250, height: 150)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                }
            }
        }
    }
    
    private func handleCapturedImage(_ image: UIImage?) {
        isAnalyzing = true
        
        guard let image = image else {
            isAnalyzing = false
            return
        }
        
        // Vérifier si l'utilisateur peut ajouter un nouveau chèque
        let modelContainer = try? ModelContainer(for: Check.self)
        let canAddMoreChecks = appState.isPremium || CheckLimitManager.shared.canAddMoreChecks(modelContainer: modelContainer)
        
        if !canAddMoreChecks {
            isAnalyzing = false
            showPremiumView = true
            return
        }
        
        DispatchQueue.main.async {
            let imageCopy = image.copy() as! UIImage
            self.capturedImage = imageCopy
            self.isAnalyzing = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isImageReady = true
            }
        }
    }
}

struct LimitedFeatureRow: View {
    let title: String
    let isPremium: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isPremium ? "checkmark.circle.fill" : "lock.fill")
                .foregroundColor(isPremium ? .green : .secondary)
            
            Text(title)
                .foregroundColor(isPremium ? .primary : .secondary)
            
            Spacer()
            
            if !isPremium {
                Text("Premium")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PremiumFeatureRow: View {
    let title: String
    let isActive: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(title)
            
            Spacer()
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: Check.self, inMemory: true)
}
