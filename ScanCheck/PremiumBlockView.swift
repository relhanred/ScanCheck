import SwiftUI
import SwiftData

struct PremiumBlockView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isPremium = false // En réalité, cette valeur viendrait d'un UserDefaults ou autre source de données
    @State private var showLoginOptions = false
    @State private var showPremiumOptions = false
    @State private var isUserLoggedIn = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 70))
                .foregroundColor(.yellow)
                .symbolEffect(.pulse, options: .repeating)
            
            Text("Limite de chèques atteinte")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Vous avez atteint la limite de 5 chèques dans la version gratuite. Passez à la version Premium pour scanner un nombre illimité de chèques.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                Button(action: {
                    if isUserLoggedIn {
                        showPremiumOptions = true
                    } else {
                        showLoginOptions = true
                    }
                }) {
                    HStack {
                        Image(systemName: isUserLoggedIn ? "crown.fill" : "person.fill")
                            .font(.title3)
                        
                        Text(isUserLoggedIn ? "Passer à la version Premium" : "Se connecter d'abord")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Revenir aux chèques")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding(.top, 60)
        .navigationTitle("Limite atteinte")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLoginOptions) {
            LoginOptionsView(onLoginSuccess: {
                isUserLoggedIn = true
                showLoginOptions = false
                showPremiumOptions = true
            })
        }
        .sheet(isPresented: $showPremiumOptions) {
            PremiumOptionsView(onPremiumSuccess: {
                isPremium = true
                dismiss()
            })
        }
    }
}

#Preview {
    NavigationStack {
        PremiumBlockView()
    }
    .modelContainer(for: Check.self, inMemory: true)
}
