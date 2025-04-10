import SwiftUI

struct EmptyChecksView: View {
    var onAddButtonTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
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
            
            VStack(spacing: 16) {
                Button {
                    onAddButtonTapped()
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title3)
                        
                        Text("Prendre une photo")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button {
                    onAddButtonTapped()
                } label: {
                    HStack {
                        Image(systemName: "photo.fill")
                            .font(.title3)
                        
                        Text("Importer depuis la galerie")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 30)
        }
        .padding()
    }
}

#Preview {
    EmptyChecksView(onAddButtonTapped: {})
}
