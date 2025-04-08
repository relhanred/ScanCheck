import SwiftUI

struct EmptyChecksView: View {
    var onScanButtonTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 70))
                .foregroundColor(.black)
            
            Text("Aucun chèque enregistré")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Ajoutez votre premier chèque pour commencer")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onScanButtonTapped) {
                HStack {
                    Image(systemName: "plus")
                    Text("Ajouter un chèque")
                }
                .font(.headline)
                .padding()
                .frame(minWidth: 200)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

#Preview {
    EmptyChecksView(onScanButtonTapped: {})
}
