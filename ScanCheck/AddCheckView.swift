import SwiftUI
import UIKit

struct AddCheckView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage? = nil
    @State private var isImageReady = false
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 70))
                    .foregroundColor(.black)
                
                Text("Ajouter un nouveau chèque")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Choisissez comment scanner votre chèque")
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
                        showingImagePicker = true
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
                
                Spacer()
            }
            .padding(.top, 50)
            .navigationTitle("Nouveau chèque")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Fermer")
                            .foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $isImageReady) {
                if let image = capturedImage {
                    CheckFormView(image: image)
                }
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

struct CameraCaptureView: UIViewControllerRepresentable {
    var onImageCaptured: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var onImageCaptured: (UIImage?) -> Void
        
        init(onImageCaptured: @escaping (UIImage?) -> Void) {
            self.onImageCaptured = onImageCaptured
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            onImageCaptured(image)
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImageCaptured(nil)
            picker.dismiss(animated: true)
        }
    }
}

struct GalleryPickerView: UIViewControllerRepresentable {
    var onImageSelected: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var onImageSelected: (UIImage?) -> Void
        
        init(onImageSelected: @escaping (UIImage?) -> Void) {
            self.onImageSelected = onImageSelected
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            onImageSelected(image)
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImageSelected(nil)
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    AddCheckView()
        .modelContainer(for: Check.self, inMemory: true)
}
