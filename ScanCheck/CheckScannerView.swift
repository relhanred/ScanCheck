import SwiftUI
import UIKit

struct CheckScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var scannedImage: UIImage?
    @State private var showingSourceOptions = false
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    
    // Champs du formulaire
    @State private var bank = ""
    @State private var recipient = ""
    @State private var amount = ""
    @State private var place = ""
    @State private var checkDate = Date()
    @State private var checkNumber = ""
    @State private var notes = ""
    @State private var showDatePicker = false
    
    // États pour la gestion des erreurs
    @State private var showAmountError = false
    @State private var amountErrorMessage = ""
    @State private var showCheckNumberError = false
    @State private var checkNumberErrorMessage = ""
    
    init(scannedImage: Binding<UIImage?>) {
        self._scannedImage = scannedImage
    }
    
    var body: some View {
        NavigationStack {
            if scannedImage != nil {
                ScrollView {
                    VStack(spacing: 20) {
                        // Image déjà scannée
                        if let image = scannedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                                .shadow(radius: 2)
                                .padding()
                        }
                        
                        // Formulaire
                        VStack(spacing: 15) {
                            // Montant (obligatoire mais peut être 0)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Montant (€)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 5)
                                
                                TextField("", text: $amount)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .onChange(of: amount) { oldValue, newValue in
                                        validateAmount(newValue)
                                    }
                                
                                if showAmountError {
                                    Text(amountErrorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading, 5)
                                }
                            }
                            
                            // Banque
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Banque")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 5)
                                
                                TextField("", text: $bank)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Ordre/Destinataire
                            VStack(alignment: .leading, spacing: 5) {
                                Text("À l'ordre de")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 5)
                                
                                TextField("", text: $recipient)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Lieu
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Lieu")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 5)
                                
                                TextField("", text: $place)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Date du chèque
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Date du chèque")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 5)
                                
                                Button(action: {
                                    withAnimation {
                                        showDatePicker.toggle()
                                    }
                                }) {
                                    HStack {
                                        Text(formatDate(checkDate))
                                        Spacer()
                                        Image(systemName: "calendar")
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                if showDatePicker {
                                    DatePicker("", selection: $checkDate, displayedComponents: .date)
                                        .datePickerStyle(.graphical)
                                        .frame(maxHeight: 400)
                                        .padding(.vertical)
                                }
                            }
                            
                            // Numéro du chèque
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Numéro du chèque (7 chiffres)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 5)
                                
                                TextField("", text: $checkNumber)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .onChange(of: checkNumber) { oldValue, newValue in
                                        validateCheckNumber(newValue)
                                    }
                                
                                if showCheckNumberError {
                                    Text(checkNumberErrorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading, 5)
                                }
                            }
                            
                            // Notes
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Notes (optionnel)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 5)
                                
                                TextEditor(text: $notes)
                                    .frame(minHeight: 100)
                                    .padding(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Bouton de sauvegarde
                        Button(action: saveCheck) {
                            Text("Enregistrer le chèque")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFormValid ? Color.black : Color.gray)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .disabled(!isFormValid)
                    }
                    .padding()
                }
                .navigationTitle("Nouveau chèque")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            scannedImage = nil
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Retour")
                            }
                            .foregroundColor(.black)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Changer d'image") {
                            showingSourceOptions = true
                        }
                        .foregroundColor(.black)
                    }
                }
                .navigationBarBackButtonHidden(true)
                .confirmationDialog("Choisir une source", isPresented: $showingSourceOptions) {
                    Button("Prendre une photo") {
                        showingCamera = true
                    }
                    Button("Importer depuis la galerie") {
                        showingImagePicker = true
                    }
                    Button("Annuler", role: .cancel) {}
                }
                .sheet(isPresented: $showingCamera) {
                    CameraView { image in
                        self.scannedImage = image
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(selectedImage: $scannedImage)
                }
            } else {
                // Nous ne devrions jamais arriver ici car la vue ne devrait être présentée qu'avec une image
                Text("Aucune image disponible")
                    .onAppear {
                        dismiss()
                    }
            }
        }
    }
    
    private var isFormValid: Bool {
        // Validation de base pour le bouton d'envoi
        !showAmountError && !showCheckNumberError
    }
    
    private func validateAmount(_ value: String) {
        // Vérification si le champ est vide
        if value.isEmpty {
            showAmountError = false
            return
        }
        
        // Remplacer la virgule par un point pour la conversion
        let normalizedValue = value.replacingOccurrences(of: ",", with: ".")
        
        // Vérifier si c'est un format numérique valide
        if Double(normalizedValue) == nil {
            showAmountError = true
            amountErrorMessage = "Veuillez entrer un montant valide (par ex. 123.45)"
        } else {
            showAmountError = false
        }
    }
    
    private func validateCheckNumber(_ value: String) {
        // Le numéro de chèque est optionnel, mais s'il est fourni,
        // il doit contenir exactement 7 chiffres
        if value.isEmpty {
            showCheckNumberError = false
            return
        }
        
        let isValid = value.count == 7 && value.allSatisfy { $0.isNumber }
        
        showCheckNumberError = !isValid
        if !isValid {
            checkNumberErrorMessage = "Le numéro doit contenir exactement 7 chiffres"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "fr_FR")
        return dateFormatter.string(from: date)
    }
    
    private func saveCheck() {
        // Convertir le montant
        let normalizedAmount = amount.replacingOccurrences(of: ",", with: ".")
        let amountValue = Double(normalizedAmount) ?? 0.0
        
        // Créer le nouveau chèque
        let newCheck = Check(
            amount: amountValue,
            bank: bank.isEmpty ? nil : bank,
            recipient: recipient.isEmpty ? nil : recipient,
            place: place.isEmpty ? nil : place,
            checkDate: checkDate,
            checkNumber: checkNumber.isEmpty ? nil : checkNumber,
            notes: notes.isEmpty ? nil : notes
        )
        
        // Enregistrement de l'image
        if let image = scannedImage, let imageData = image.jpegData(compressionQuality: 0.7) {
            newCheck.imageData = imageData
        }
        
        modelContext.insert(newCheck)
        scannedImage = nil
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
    CheckScannerView(scannedImage: .constant(UIImage(systemName: "photo")))
        .modelContainer(for: Check.self, inMemory: true)
}
