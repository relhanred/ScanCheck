import SwiftUI
import SwiftData

struct CheckEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // On passe le check par binding pour permettre la mise à jour
    @Bindable var check: Check
    
    // États du formulaire pré-remplis avec les valeurs existantes
    @State private var bank: String
    @State private var recipient: String
    @State private var amount: String
    @State private var place: String
    @State private var checkDate: Date
    @State private var checkNumber: String
    @State private var notes: String
    @State private var showDatePicker = false
    
    // États pour la gestion des erreurs
    @State private var amountError = false
    @State private var amountErrorMessage = ""
    @State private var checkNumberError = false
    @State private var checkNumberErrorMessage = ""
    @State private var showValidationErrors = false
    
    // Initialisation des champs avec les valeurs existantes
    init(check: Check) {
        self._check = Bindable(check)
        
        // Initialiser les états avec les valeurs actuelles du chèque
        self._bank = State(initialValue: check.bank ?? "")
        self._recipient = State(initialValue: check.recipient ?? "")
        self._amount = State(initialValue: String(format: "%.2f", check.amount))
        self._place = State(initialValue: check.place ?? "")
        self._checkDate = State(initialValue: check.checkDate ?? Date())
        self._checkNumber = State(initialValue: check.checkNumber ?? "")
        self._notes = State(initialValue: check.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    // Affichage de l'image existante (non modifiable)
                    if let imageData = check.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 180)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            .padding(.horizontal)
                            .padding(.top, 5)
                    } else {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 70))
                            .foregroundColor(.gray)
                            .frame(height: 180)
                            .padding(.top, 5)
                    }
                    
                    // Formulaire d'édition
                    VStack(spacing: 12) {
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
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            if showDatePicker {
                                DatePicker("", selection: $checkDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .frame(maxHeight: 370)
                                    .padding(.vertical, 5)
                            }
                        }
                        
                        // Cinquième rangée: Notes
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Notes (optionnel)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 90)
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Bouton de mise à jour
                    Button(action: validateAndUpdateCheck) {
                        Text("Mettre à jour")
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
            .navigationTitle("Modifier le chèque")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Annuler")
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
    
    private func validateAndUpdateCheck() {
        // Vérifier le montant (obligatoire)
        validateAmount(amount)
        
        // Vérifier le numéro de chèque si présent
        validateCheckNumber(checkNumber)
        
        // Afficher les erreurs
        showValidationErrors = true
        
        // Si le formulaire est valide, mettre à jour
        if isFormValid {
            updateCheck()
        }
    }
    
    private func updateCheck() {
        // Convertir le montant
        let normalizedAmount = amount.replacingOccurrences(of: ",", with: ".")
        let amountValue = Double(normalizedAmount) ?? 0.0
        
        // Mettre à jour les propriétés du chèque
        check.amount = amountValue
        check.bank = bank.isEmpty ? nil : bank
        check.recipient = recipient.isEmpty ? nil : recipient
        check.place = place.isEmpty ? nil : place
        check.checkDate = checkDate
        check.checkNumber = checkNumber.isEmpty ? nil : checkNumber
        check.notes = notes.isEmpty ? nil : notes
        
        do {
            try modelContext.save()
            print("Chèque mis à jour avec succès")
        } catch {
            print("Échec de la mise à jour du chèque: \(error)")
        }
        
        // Fermer la vue d'édition
        dismiss()
    }
}

#Preview {
    let previewCheck = Check(amount: 150.00, bank: "Banque Test", recipient: "John Doe")
    return CheckEditView(check: previewCheck)
        .modelContainer(for: Check.self, inMemory: true)
}
