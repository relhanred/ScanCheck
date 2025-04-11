import SwiftUI

struct PremiumOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    var onPremiumSuccess: (() -> Void)? = nil
    
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
                        // Simuler un achat réussi
                        UserDefaults.standard.setValue(true, forKey: "isPremium")
                        onPremiumSuccess?()
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
                        // Simuler un achat réussi
                        UserDefaults.standard.setValue(true, forKey: "isPremium")
                        onPremiumSuccess?()
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
