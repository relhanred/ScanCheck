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
    
    @State private var isAnalyzing = true
    @State private var analysisError: String? = nil
    @State private var showInfoTooltip = false
    
    @State private var amountError = false
    @State private var amountErrorMessage = ""
    @State private var checkNumberError = false
    @State private var checkNumberErrorMessage = ""
    @State private var showValidationErrors = false
    
    private let analyzerService = CheckAnalyzerService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 15) {
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 180)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                            .padding(.horizontal)
                            .padding(.top, 5)
                        
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
                                    analyzeCheckImage()
                                }
                                .buttonStyle(.bordered)
                                .padding(.top, 5)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        
                        VStack(spacing: 12) {
                            
                            HStack(alignment: .top, spacing: 10) {
                                
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
                                
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Banque")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("", text: $bank)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                .frame(maxWidth: .infinity)
                            }
                            
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("À l'ordre de")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextField("", text: $recipient)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            
                            HStack(alignment: .top, spacing: 10) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Lieu")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("", text: $place)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                .frame(maxWidth: .infinity)
                                
                                
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
                        .disabled(isAnalyzing)
                        .opacity(isAnalyzing ? 0.6 : 1)
                        
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
                    
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        
                        Text("Analyse du chèque en cours...")
                            .font(.headline)
                        
                        Text("L'IA extrait automatiquement les informations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if showInfoTooltip {
                            Text("Cela peut prendre quelques instants")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 5)
                        }
                    }
                    .frame(width: 280, height: 180)
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showInfoTooltip = true
                            }
                        }
                    }
                }
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
            .onAppear {
                analyzeCheckImage()
            }
        }
    }
    
    private func analyzeCheckImage() {
        isAnalyzing = true
        analysisError = nil
        showInfoTooltip = false
        
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
        !amountError && !checkNumberError
    }
    
    private func validateAmount(_ value: String) {
        if value.isEmpty {
            amountError = true
            amountErrorMessage = "Veuillez entrer un montant"
            return
        }
        
        let normalizedValue = value.replacingOccurrences(of: ",", with: ".")
        
        if Double(normalizedValue) == nil {
            amountError = true
            amountErrorMessage = "Montant invalide"
        } else {
            amountError = false
        }
    }
    
    private func validateCheckNumber(_ value: String) {
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
        validateAmount(amount)
        validateCheckNumber(checkNumber)
        showValidationErrors = true
        
        if isFormValid {
            saveCheck()
        }
    }
    
    private func saveCheck() {
        let normalizedAmount = amount.replacingOccurrences(of: ",", with: ".")
        let amountValue = Double(normalizedAmount) ?? 0.0
        
        let newCheck = Check(
            amount: amountValue,
            bank: bank.isEmpty ? nil : bank,
            recipient: recipient.isEmpty ? nil : recipient,
            place: place.isEmpty ? nil : place,
            checkDate: checkDate,
            checkNumber: checkNumber.isEmpty ? nil : checkNumber,
            notes: notes.isEmpty ? nil : notes
        )
        
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            newCheck.imageData = imageData
        }
        
        modelContext.insert(newCheck)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Échec de l'enregistrement du chèque: \(error)")
        }
    }
}

#Preview {
    CheckFormView(image: UIImage(systemName: "photo")!)
        .modelContainer(for: Check.self, inMemory: true)
}
