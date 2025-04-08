import SwiftUI
import UIKit
import VisionKit
import Vision

struct CheckScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCamera = false
    @State private var scannedImage: UIImage?
    @State private var issuerName = ""
    @State private var amount = ""
    @State private var checkNumber = ""
    @State private var notes = ""
    @State private var recognizedText = ""
    @State private var isProcessing = false
    
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
                                        Image(systemName: "camera")
                                            .font(.system(size: 40))
                                            .foregroundColor(.black)
                                        
                                        Text("Prendre une photo du chèque")
                                            .font(.headline)
                                    }
                                )
                        }
                        
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(10)
                                .frame(width: 60, height: 60)
                        }
                    }
                    .onTapGesture {
                        showingCamera = true
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
            .navigationTitle("Scanner un chèque")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    self.scannedImage = image
                    self.recognizeText(from: image)
                }
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
    
    private func recognizeText(from image: UIImage) {
        isProcessing = true
        
        guard let cgImage = image.cgImage else {
            isProcessing = false
            return
        }
        
        // Préparation de la requête pour Vision
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Erreur de reconnaissance de texte: \(error)")
                isProcessing = false
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                isProcessing = false
                return
            }
            
            // Extraction du texte reconnu
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                self.recognizedText = recognizedStrings.joined(separator: " ")
                self.extractInformation(from: recognizedStrings)
                self.isProcessing = false
            }
        }
        
        // Configuration supplémentaire pour optimiser la reconnaissance
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Exécution de la demande de Vision
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? requestHandler.perform([request])
    }
    
    private func extractInformation(from textLines: [String]) {
        // Fonction pour extraire les informations pertinentes du texte reconnu
        // Cette implémentation est basique et devrait être améliorée selon le format des chèques
        
        // Recherche de montants (format: chiffres avec virgule/point)
        let amountRegex = try? NSRegularExpression(pattern: "(\\d+[,.]\\d{2})|(\\d+ ?€)", options: [])
        
        for line in textLines {
            // Extraction du montant
            if amount.isEmpty, let amountRegex = amountRegex {
                let range = NSRange(location: 0, length: line.utf16.count)
                if let match = amountRegex.firstMatch(in: line, options: [], range: range) {
                    let matchedText = (line as NSString).substring(with: match.range)
                    let cleanAmount = matchedText.replacingOccurrences(of: "€", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    amount = cleanAmount
                }
            }
            
            // Essai de trouver le numéro de chèque (séquence de chiffres)
            if checkNumber.isEmpty && line.contains("N°") {
                let components = line.components(separatedBy: "N°")
                if components.count > 1 {
                    let potential = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let digitsOnly = potential.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    if !digitsOnly.isEmpty {
                        checkNumber = digitsOnly
                    }
                }
            }
        }
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

#Preview {
    CheckScannerView()
        .modelContainer(for: Check.self, inMemory: true)
}
