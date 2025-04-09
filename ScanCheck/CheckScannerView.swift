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
    
    // États pour l'analyse du chèque
    @State private var isAnalyzing = true
    @State private var analysisError: String? = nil
    
    // États pour la gestion des erreurs
    @State private var amountError = false
    @State private var amountErrorMessage = ""
    @State private var checkNumberError = false
    @State private var checkNumberErrorMessage = ""
    @State private var showValidationErrors = false // Nouvel état pour contrôler l'affichage des erreurs
    
    // Service d'analyse
    private let analyzerService = CheckAnalyzerService()
    
    init(scannedImage: Binding<UIImage?>) {
        self._scannedImage = scannedImage
    }
    
    var body: some View {
        NavigationStack {
            if scannedImage != nil {
                ZStack {
                    ScrollView {
                        VStack(spacing: 15) { // Réduit l'espacement vertical
                            // Image déjà scannée
                            if let image = scannedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 180) // Légèrement réduit
                                    .cornerRadius(12)
                                    .shadow(radius: 2)
                                    .padding(.horizontal)
                                    .padding(.top, 5)
                            }
                            
                            if let error = analysisError {
                                VStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 30))
                                        .foregroundColor(.orange)
                                    
                                    Text("Erreur d'analyse")
                                        .font(.headline)
                                    
                                    Text(error)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Button("Réessayer") {
                                        if let image = scannedImage {
                                            analyzeCheckImage(image)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .padding(.top, 5)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                            
                            // Formulaire redesigné
                            VStack(spacing: 12) { // Espacement réduit entre les éléments
                                // Première rangée: Montant et Banque
                                HStack(alignment: .top, spacing: 10) {
                                    // Montant (obligatoire mais peut être 0)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Montant (€)*")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        TextField("", text: $amount)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                            .onChange(of: amount) { oldValue, newValue in
                                                validateAmount(newValue)
                                            }
                                        
                                        if showValidationErrors && amountError {
                                            Text(amountErrorMessage)
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    // Banque
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Banque")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        TextField("", text: $bank)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                
                                // Deuxième rangée: Destinataire
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("À l'ordre de")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("", text: $recipient)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                // Troisième rangée: Lieu et N° de chèque
                                HStack(alignment: .top, spacing: 10) {
                                    // Lieu
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Lieu")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        TextField("", text: $place)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    // Numéro du chèque
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("N° chèque (7 chiffres)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        TextField("", text: $checkNumber)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.numberPad)
                                            .onChange(of: checkNumber) { oldValue, newValue in
                                                validateCheckNumber(newValue)
                                            }
                                        
                                        if showValidationErrors && checkNumberError {
                                            Text(checkNumberErrorMessage)
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                
                                // Quatrième rangée: Date du chèque
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Date du chèque")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
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
                                        .padding(8) // Padding réduit
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    
                                    if showDatePicker {
                                        DatePicker("", selection: $checkDate, displayedComponents: .date)
                                            .datePickerStyle(.graphical)
                                            .frame(maxHeight: 370) // Hauteur légèrement réduite
                                            .padding(.vertical, 5) // Padding réduit
                                    }
                                }
                                
                                // Cinquième rangée: Notes
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Notes (optionnel)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextEditor(text: $notes)
                                        .frame(minHeight: 90) // Hauteur légèrement réduite
                                        .padding(4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.horizontal)
                            .disabled(isAnalyzing)
                            .opacity(isAnalyzing ? 0.6 : 1)
                            
                            // Bouton de sauvegarde
                            Button(action: validateAndSaveCheck) {
                                Text("Enregistrer le chèque")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .padding(.top, 5)
                            .disabled(isAnalyzing)
                            .opacity(isAnalyzing ? 0.6 : 1)
                        }
                        .padding(.bottom)
                    }
                    
                    if isAnalyzing {
                        Color.white.opacity(0.7)
                            .ignoresSafeArea()
                        
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            
                            Text("Analyse du chèque en cours...")
                                .font(.headline)
                                .padding()
                        }
                        .frame(width: 250, height: 150)
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(radius: 10)
                    }
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
                        if let image = image {
                            self.scannedImage = image
                            analyzeCheckImage(image)
                        }
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(selectedImage: $scannedImage)
                        .onDisappear {
                            if let image = scannedImage {
                                analyzeCheckImage(image)
                            }
                        }
                }
                .onAppear {
                    if let image = scannedImage {
                        analyzeCheckImage(image)
                    }
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
    
    private func analyzeCheckImage(_ image: UIImage) {
        isAnalyzing = true
        analysisError = nil
        
        analyzerService.analyzeCheckImage(image) { result in
            isAnalyzing = false
            
            switch result {
            case .success(let response):
                if response.status == "success" {
                    // Remplir les champs avec les informations extraites
                    if let amountStr = response.amount_eur, !amountStr.isEmpty {
                        self.amount = amountStr
                    }
                    
                    if let payTo = response.pay_to, !payTo.isEmpty {
                        self.recipient = payTo
                    }
                    
                    if let bankName = response.bank_name, !bankName.isEmpty {
                        self.bank = bankName
                    }
                    
                    if let checkNum = response.cheque_number, !checkNum.isEmpty {
                        self.checkNumber = checkNum
                    }
                    
                    if let location = response.location, !location.isEmpty {
                        self.place = location
                    }
                    
                    // Traiter la date si elle est disponible
                    if let dateStr = response.date, !dateStr.isEmpty {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd/MM/yyyy"
                        if let parsedDate = dateFormatter.date(from: dateStr) {
                            self.checkDate = parsedDate
                        }
                    }
                } else {
                    // Afficher le message d'erreur
                    self.analysisError = response.message ?? "L'image n'a pas pu être reconnue comme un chèque."
                }
                
            case .failure(let error):
                self.analysisError = "Erreur d'analyse: \(error.localizedDescription)\nVeuillez remplir les champs manuellement ou réessayer."
            }
        }
    }
    
    private var isFormValid: Bool {
        // Validation de base pour le bouton d'envoi
        !amountError && !checkNumberError
    }
    
    private func validateAmount(_ value: String) {
        // Vérification si le champ est vide
        if value.isEmpty {
            amountError = true
            amountErrorMessage = "Montant requis"
            return
        }
        
        // Remplacer la virgule par un point pour la conversion
        let normalizedValue = value.replacingOccurrences(of: ",", with: ".")
        
        // Vérifier si c'est un format numérique valide
        if Double(normalizedValue) == nil {
            amountError = true
            amountErrorMessage = "Veuillez entrer un montant valide (par ex. 123.45)"
        } else {
            amountError = false
        }
    }
    
    private func validateCheckNumber(_ value: String) {
        // Le numéro de chèque est optionnel, mais s'il est fourni,
        // il doit contenir exactement 7 chiffres
        if value.isEmpty {
            checkNumberError = false
            return
        }
        
        let isValid = value.count == 7 && value.allSatisfy { $0.isNumber }
        
        checkNumberError = !isValid
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
    
    private func validateAndSaveCheck() {
        // Vérifier le montant (obligatoire)
        validateAmount(amount)
        
        // Vérifier le numéro de chèque si présent
        validateCheckNumber(checkNumber)
        
        // Afficher les erreurs
        showValidationErrors = true
        
        // Si le formulaire est valide, sauvegarder
        if isFormValid {
            saveCheck()
        }
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

// Les structures CameraView et ImagePicker restent inchangées

// Vue pour la caméra utilisant UIImagePickerController
struct CameraView: UIViewControllerRepresentable {
    var onImageCaptured: (UIImage?) -> Void
    
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
        var onImageCaptured: (UIImage?) -> Void
        
        init(onImageCaptured: @escaping (UIImage?) -> Void) {
            self.onImageCaptured = onImageCaptured
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            } else {
                onImageCaptured(nil)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImageCaptured(nil)
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
