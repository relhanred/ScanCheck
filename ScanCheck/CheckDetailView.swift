import SwiftUI
import SwiftData

struct CheckDetailView: View {
    let check: Check
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteAnimationTriggered = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let imageData = check.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(8)
                } else {
                    ContentUnavailableView {
                        Label("Pas d'image", systemImage: "photo")
                    } description: {
                        Text("L'image du chèque n'est pas disponible")
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    DetailRow(title: "Montant", value: String(format: "%.2f €", check.amount))
                    
                    if let bank = check.bank, !bank.isEmpty {
                        DetailRow(title: "Banque", value: bank)
                    }
                    
                    if let recipient = check.recipient, !recipient.isEmpty {
                        DetailRow(title: "À l'ordre de", value: recipient)
                    }
                    
                    if let place = check.place, !place.isEmpty {
                        DetailRow(title: "Lieu", value: place)
                    }
                    
                    if let checkDate = check.checkDate {
                        DetailRow(title: "Date du chèque", value: formatDate(checkDate, includeTime: false))
                    }
                    
                    if let checkNumber = check.checkNumber, !checkNumber.isEmpty {
                        DetailRow(title: "N° de chèque", value: checkNumber)
                    }
                    
                    if let notes = check.notes, !notes.isEmpty {
                        Divider()
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .padding(.top, 4)
                    }
                    
                    // Date de création dans un format plus discret à la fin
                    Divider()
                    Text("Scanné le \(formatDate(check.creationDate, includeTime: true))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 1)
                
                // Bouton de suppression moderne
                Button(action: {
                    // Déclencher l'animation avant d'afficher la confirmation
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        deleteAnimationTriggered = true
                    }
                    
                    // Afficher la confirmation après un court délai
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingDeleteConfirmation = true
                        deleteAnimationTriggered = false
                    }
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .imageScale(.medium)
                        Text("Supprimer ce chèque")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .scaleEffect(deleteAnimationTriggered ? 0.95 : 1)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Détails du chèque")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Bouton Retour
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
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditView = true
                }) {
                    Text("Modifier")
                        .foregroundColor(.black)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingEditView) {
            CheckEditView(check: check)
        }
        .overlay {
            if showingDeleteConfirmation {
                DeleteConfirmationView(
                    isPresented: $showingDeleteConfirmation,
                    onConfirm: {
                        deleteCheck()
                    }
                )
                .transition(.opacity)
            }
        }
    }
    
    // Fonction pour formater la date en français
    private func formatDate(_ date: Date, includeTime: Bool) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = includeTime ? .short : .none
        dateFormatter.locale = Locale(identifier: "fr_FR")
        return dateFormatter.string(from: date)
    }
    
    // Fonction pour supprimer le chèque
    private func deleteCheck() {
        withAnimation {
            modelContext.delete(check)
            try? modelContext.save()
            dismiss()
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title + " :")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 130, alignment: .leading) // Augmentation de la largeur pour éviter la troncature
                .fixedSize(horizontal: false, vertical: true) // Permet au texte de s'étendre verticalement si nécessaire
            
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
    }
}
