import SwiftUI
import SwiftData

struct CheckFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let image: UIImage
    
    @State private var bank = ""
    @State private var recipient = ""
    @State private var amount = ""
    @State private var place = ""
    @State private var checkDate = Date()
    @State private var checkNumber = ""
    @State private var notes = ""
    @State private var showDatePicker = false
    
    // États pour la gestion des erreurs
    @State private var amountError = false
    @State private var amountErrorMessage = ""
    @State private var checkNumberError = false
    @State private var checkNumberErrorMessage = ""
    @State private var showValidationErrors = false // Nouvel état pour contrôler l'affichage des erreurs
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) { // Réduit l'espacement vertical
                    // Affichage de l'image capturée
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180) // Légèrement réduit
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    
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
                }
                .padding(.bottom)
            }
            .navigationTitle("Nouveau chèque")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Retour")
                        }
                        .foregroundColor(.black)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
    
    private var isFormValid: Bool {
        // Validation de base:
        // - Le montant doit être valide
        // - Pas d'autres erreurs de validation
        !amountError && !checkNumberError
    }
    
    private func validateAmount(_ value: String) {
        // Vérification si le champ est vide
        if value.isEmpty {
            amountError = true
            amountErrorMessage = "Veuillez entrer un montant"
            return
        }
        
        // Remplacer la virgule par un point pour la conversion
        let normalizedValue = value.replacingOccurrences(of: ",", with: ".")
        
        // Vérifier si c'est un format numérique valide
        if Double(normalizedValue) == nil {
            amountError = true
            amountErrorMessage = "Montant invalide"
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
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            newCheck.imageData = imageData
        }
        
        modelContext.insert(newCheck)
        
        do {
            try modelContext.save()
            print("Chèque enregistré avec succès")
        } catch {
            print("Échec de l'enregistrement du chèque: \(error)")
        }
        
        // Assurer que la fermeture se fait correctement
        DispatchQueue.main.async {
            dismiss()
        }
    }
}

#Preview {
    CheckFormView(image: UIImage(systemName: "photo")!)
        .modelContainer(for: Check.self, inMemory: true)
}
