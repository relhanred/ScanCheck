import SwiftUI
import SwiftData

struct CheckFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let image: UIImage
    
    @State private var issuerName = ""
    @State private var amount = ""
    @State private var checkNumber = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Affichage de l'image capturée
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding()
                    
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
                    .disabled(issuerName.isEmpty || amount.isEmpty)
                    .opacity(issuerName.isEmpty || amount.isEmpty ? 0.6 : 1)
                }
                .padding()
            }
            .navigationTitle("Nouveau chèque")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
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
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            newCheck.imageData = imageData
        }
        
        modelContext.insert(newCheck)
        
        do {
            try modelContext.save()
            print("Check saved successfully")
        } catch {
            print("Failed to save check: \(error)")
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
