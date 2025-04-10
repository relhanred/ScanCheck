import SwiftUI

struct EmptyChecksView: View {
    var onAddButtonTapped: () -> Void
    @State private var showingOptions = false
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage? = nil
    @State private var isImageReady = false
    
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
                    showingCamera = true
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
        .sheet(isPresented: $showingCamera) {
            CameraCaptureView { image in
                if let image = image {
                    capturedImage = image
                    isImageReady = true
                }
            }
        }
        .sheet(isPresented: $isImageReady) {
            if let image = capturedImage {
                CheckFormView(image: image)
            }
        }
    }
}

#Preview {
    EmptyChecksView(onAddButtonTapped: {})
}
