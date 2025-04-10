import SwiftUI
import UIKit

struct AddCheckView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingSourceOptions = false
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage? = nil
    @State private var isImageReady = false
    @State private var isAnalyzing = false
    
    @State private var imagePickerDelegate: ImagePickerDelegate?
    
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
                        captureImageFromCamera()
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
                        importImageFromGallery()
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
    
    private func captureImageFromCamera() {
        isAnalyzing = true
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        
        self.imagePickerDelegate = ImagePickerDelegate { image in
            isAnalyzing = false
            
            guard let image = image else {
                return
            }
            
            DispatchQueue.main.async {
                let imageCopy = image.copy() as! UIImage
                self.capturedImage = imageCopy
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isImageReady = true
                }
            }
        }
        
        picker.delegate = self.imagePickerDelegate
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(picker, animated: true)
        }
    }
    
    private func importImageFromGallery() {
        isAnalyzing = true
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        
        self.imagePickerDelegate = ImagePickerDelegate { image in
            isAnalyzing = false
            
            guard let image = image else {
                return
            }
            
            DispatchQueue.main.async {
                let imageCopy = image.copy() as! UIImage
                self.capturedImage = imageCopy
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isImageReady = true
                }
            }
        }
        
        picker.delegate = self.imagePickerDelegate
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(picker, animated: true)
        }
    }
}

class ImagePickerDelegate: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    private let onImagePicked: (UIImage?) -> Void
    
    init(onImagePicked: @escaping (UIImage?) -> Void) {
        self.onImagePicked = onImagePicked
        super.init()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            self.onImagePicked(editedImage)
        }
        else if let originalImage = info[.originalImage] as? UIImage {
            self.onImagePicked(originalImage)
        }
        else {
            self.onImagePicked(nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            picker.dismiss(animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.onImagePicked(nil)
        picker.dismiss(animated: true)
    }
}

#Preview {
    AddCheckView()
        .modelContainer(for: Check.self, inMemory: true)
}
