import SwiftUI

struct LoginOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    var onLoginSuccess: (() -> Void)? = nil
    
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
                        // Simuler une connexion réussie
                        UserDefaults.standard.setValue(true, forKey: "isUserLoggedIn")
                        onLoginSuccess?()
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
                        // Simuler une connexion réussie
                        UserDefaults.standard.setValue(true, forKey: "isUserLoggedIn")
                        onLoginSuccess?()
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
