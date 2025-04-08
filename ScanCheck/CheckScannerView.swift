import SwiftUI
import UIKit

struct CheckScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSourceOptions = false
    @State private var scannedImage: UIImage?
    @State private var issuerName = ""
    @State private var amount = ""
    @State private var checkNumber = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Zone d'image
                    ZStack {
                        if let scannedImage {
                            Image(uiImage: scannedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                                .shadow(radius: 2)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 10) {
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: 40))
                                            .foregroundColor(.black)
                                        
                                        Text("Ajouter une photo du chèque")
                                            .font(.headline)
                                    }
                                )
                        }
                    }
                    .onTapGesture {
                        showingSourceOptions = true
                    }
                    
                    // Formulaire
                    VStack(spacing: 15) {
                        TextField("Nom de l'émetteur", text: $issuerName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Montant (€)", text: $amount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        TextField("Numéro du chèque", text: $checkNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        TextField("Notes (optionnel)", text: $notes)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Bouton de sauvegarde
                    Button(action: saveCheck) {
                        Text("Enregistrer le chèque")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(issuerName.isEmpty || amount.isEmpty || scannedImage == nil)
                    .opacity(issuerName.isEmpty || amount.isEmpty || scannedImage == nil ? 0.6 : 1)
                }
                .padding()
            }
            .navigationTitle("Ajouter un chèque")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    self.scannedImage = image
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $scannedImage)
            }
            .confirmationDialog("Choisir une source", isPresented: $showingSourceOptions) {
                Button("Prendre une photo") {
                    showingCamera = true
                }
                Button("Importer depuis la galerie") {
                    showingImagePicker = true
                }
                Button("Annuler", role: .cancel) {}
            }
        }
    }
    
    private func saveCheck() {
        // Conversion du montant
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return
        }
        
        let newCheck = Check(
            amount: amountValue,
            issuerName: issuerName,
            checkNumber: checkNumber.isEmpty ? nil : checkNumber,
            notes: notes.isEmpty ? nil : notes
        )
        
        // Enregistrement de l'image
        if let image = scannedImage, let imageData = image.jpegData(compressionQuality: 0.7) {
            newCheck.imageData = imageData
        }
        
        modelContext.insert(newCheck)
        dismiss()
    }
}

// Vue pour la caméra utilisant UIImagePickerController
struct CameraView: UIViewControllerRepresentable {
    var onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var onImageCaptured: (UIImage) -> Void
        
        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// Structure simplifiée pour l'importation d'images depuis la photothèque
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    CheckScannerView()
        .modelContainer(for: Check.self, inMemory: true)
}
