import SwiftUI
import SwiftData

struct ProfileView: View {
    @State private var showLoginOptions = false
    @State private var isPremium = false
    @State private var showPremiumOptions = false
    @Query private var checks: [Check]
    
    private let freeChecksLimit = 5
    private let remainingFreeChecks: Int
    
    init() {
        let modelContainer = try? ModelContainer(for: Check.self)
        let descriptor = FetchDescriptor<Check>()
        let count = try? modelContainer?.mainContext.fetchCount(descriptor) ?? 0
        remainingFreeChecks = max(0, freeChecksLimit - (count ?? 0))
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
                                Image(systemName: "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            )
                        
                        VStack(alignment: .leading) {
                            Text("Invité")
                                .font(.headline)
                            Text("Non connecté")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            showLoginOptions = true
                        } label: {
                            Text("Se connecter")
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
                            Text(isPremium ? "Premium" : "Gratuit")
                                .font(.headline)
                                .foregroundColor(isPremium ? .yellow : .primary)
                            
                            if isPremium {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                            }
                            
                            Spacer()
                            
                            if !isPremium {
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
                        
                        if !isPremium {
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
                    
                    if !isPremium {
                        LimitedFeatureRow(title: "Export PDF et Excel", isPremium: isPremium)
                        LimitedFeatureRow(title: "Chèques illimités", isPremium: isPremium)
                        LimitedFeatureRow(title: "Synchronisation cloud", isPremium: isPremium)
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
                LoginOptionsView()
            }
            .sheet(isPresented: $showPremiumOptions) {
                PremiumOptionsView()
            }
        }
    }
}

struct LoginOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Connectez-vous pour synchroniser vos chèques")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.title3)
                            Text("Continuer avec Apple")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                            Text("Continuer avec Google")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationTitle("Connexion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PremiumOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .padding(.top, 40)
                
                Text("ScanCheck Premium")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Accédez à toutes les fonctionnalités")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 16) {
                    PremiumFeatureItem(icon: "infinity", title: "Chèques illimités", description: "Numérisez et stockez autant de chèques que vous le souhaitez")
                    
                    PremiumFeatureItem(icon: "square.and.arrow.up", title: "Exportation", description: "Exportez vos données au format PDF et Excel")
                    
                    PremiumFeatureItem(icon: "icloud", title: "Synchronisation", description: "Synchronisez vos chèques sur tous vos appareils")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                VStack(spacing: 16) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Text("Abonnement mensuel")
                                .font(.headline)
                            Spacer()
                            Text("4,99 €/mois")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Text("Abonnement annuel")
                                .font(.headline)
                            Spacer()
                            Text("39,99 €/an")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Text("Paiement unique. Vous pouvez annuler à tout moment.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
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

struct PremiumFeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 24)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
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
