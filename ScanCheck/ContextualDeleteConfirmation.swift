import SwiftUI

struct ContextualDeleteConfirmation: View {
    @Binding var isVisible: Bool
    let checkInfo: String
    let amount: Double
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    @State private var offset: CGFloat = 100
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.red)
                .frame(height: 4)
                .offset(x: isVisible ? 0 : -UIScreen.main.bounds.width)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: isVisible)
            
            VStack(spacing: 15) {
                HStack(spacing: 15) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.red)
                        .symbolEffect(.pulse, options: .repeating, value: isVisible)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Supprimer le chèque")
                            .font(.headline)
                        
                        Text("\(checkInfo) - \(String(format: "%.2f €", amount))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation {
                            onCancel()
                        }
                    }) {
                        Text("Annuler")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.15))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }
                
                    Button(action: {
                        withAnimation {
                            onConfirm()
                        }
                    }) {
                        Text("Supprimer")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
            .offset(y: offset)
            .opacity(opacity)
        }
        .onChange(of: isVisible) { oldValue, newValue in
            if newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    offset = 0
                    opacity = 1
                }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = 100
                    opacity = 0
                }
            }
        }
    }
}
