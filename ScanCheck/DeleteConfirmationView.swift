import SwiftUI

struct DeleteConfirmationView: View {
    @Binding var isPresented: Bool
    var onConfirm: () -> Void
    
    @State private var offset: CGFloat = 1000
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            
            Color.black.opacity(0.5)
                .opacity(opacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            
            VStack(spacing: 20) {
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                    .padding(.top, 20)
                    .symbolEffect(.bounce, options: .repeating, value: isPresented)
                
                Text("Supprimer ce chèque ?")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Cette action ne peut pas être annulée et toutes les informations seront définitivement supprimées.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 15) {
                    
                    Button(action: dismiss) {
                        Text("Annuler")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    
                    
                    Button(action: {
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            scale = 0.85
                            opacity = 0
                        }
                        
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onConfirm()
                            isPresented = false
                        }
                    }) {
                        Text("Supprimer")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 25)
            }
            .frame(maxWidth: 320)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .offset(y: offset)
            .scaleEffect(scale)
        }
        .onAppear {
            // Animation d'apparition
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1
                scale = 1
            }
        }
    }
    
    private func dismiss() {
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            offset = 1000
            opacity = 0
        }
        

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}
