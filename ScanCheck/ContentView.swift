import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var checks: [Check]
    @State private var showingSourceOptions = false
    @State private var showingCheckForm = false
    @State private var capturedImage: UIImage?
    @State private var isImageReady = false
    
    // On conserve une référence forte au délégué pour éviter sa déallocation
    @State private var imagePickerDelegate: ImagePickerDelegate?
    
    var body: some View {
        NavigationStack {
            VStack {
                if checks.isEmpty {
                    EmptyChecksView(onAddButtonTapped: {
                        showingSourceOptions = true
                    })
                } else {
                    List {
                        ForEach(checks) { check in
                            CheckRowView(check: check)
                        }
                        .onDelete(perform: deleteChecks)
                    }
                }
            }
            .navigationTitle("Mes Chèques")
            .toolbar(content: {
                // Afficher un bouton plus élégant dans la barre d'outils lorsque des chèques existent
                if !checks.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showingSourceOptions = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                    }
                }
            })
            .sheet(isPresented: $showingCheckForm) {
                if let image = capturedImage, isImageReady {
                    CheckFormView(image: image)
                        .environment(\.modelContext, modelContext)
                        .onDisappear {
                            // Réinitialiser les états après fermeture de la sheet
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                capturedImage = nil
                                isImageReady = false
                            }
                        }
                } else {
                    // Afficher un message d'erreur avec des détails et des options de récupération
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Aucune image disponible")
                            .font(.headline)
                            .padding()
                        
                        Text("L'image n'a pas pu être chargée correctement.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Réessayer") {
                            // Fermer la sheet actuelle
                            showingCheckForm = false
                            
                            // Attendre un instant puis réafficher les options
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showingSourceOptions = true
                            }
                        }
                        .padding()
                        .buttonStyle(.bordered)
                        
                        Button("Fermer") {
                            showingCheckForm = false
                        }
                        .padding()
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .confirmationDialog("Choisir une source", isPresented: $showingSourceOptions) {
                Button("Prendre une photo") {
                    captureImageFromCamera()
                }
                Button("Importer depuis la galerie") {
                    importImageFromGallery()
                }
                Button("Annuler", role: .cancel) {}
            }
            // Surveillons le changement d'état de isImageReady pour montrer la sheet
            .onChange(of: isImageReady) { oldValue, newValue in
                if newValue && capturedImage != nil {
                    showingCheckForm = true
                }
            }
            // Ajout d'un onChange pour forcer la mise à jour du modelContext
            .onChange(of: showingCheckForm) { oldValue, newValue in
                if oldValue == true && newValue == false {
                    // Force ModelContext to update
                    modelContext.processPendingChanges()
                }
            }
        }
    }
    
    private func captureImageFromCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        
        // Créer et stocker le délégué avec une logique plus robuste
        self.imagePickerDelegate = ImagePickerDelegate { image in
            print("Image capturée, taille: \(image.size.width)x\(image.size.height)")
            
            // Assurer que l'image est valide
            guard image.size.width > 0, image.size.height > 0 else {
                print("Image invalide détectée")
                return
            }
            
            // Définir l'image capturée sur le thread principal
            DispatchQueue.main.async { [self] in
                // S'assurer que l'image est bien copiée/retenue
                let imageCopy = image.copy() as! UIImage
                self.capturedImage = imageCopy
                
                // Indiquer que l'image est prête avec un léger délai pour s'assurer que tout est bien traité
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isImageReady = true
                    print("Image prête: \(self.isImageReady), image: \(self.capturedImage != nil)")
                }
            }
        }
        
        // Assigner le délégué
        picker.delegate = self.imagePickerDelegate
        
        // Présenter le picker de caméra
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(picker, animated: true)
        }
    }
    
    private func importImageFromGallery() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        
        // Créer et stocker le délégué avec une logique plus robuste
        self.imagePickerDelegate = ImagePickerDelegate { image in
            print("Image sélectionnée, taille: \(image.size.width)x\(image.size.height)")
            
            // Assurer que l'image est valide
            guard image.size.width > 0, image.size.height > 0 else {
                print("Image invalide détectée")
                return
            }
            
            // Définir l'image capturée sur le thread principal
            DispatchQueue.main.async { [self] in
                // S'assurer que l'image est bien copiée/retenue
                let imageCopy = image.copy() as! UIImage
                self.capturedImage = imageCopy
                
                // Indiquer que l'image est prête avec un léger délai pour s'assurer que tout est bien traité
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isImageReady = true
                    print("Image prête: \(self.isImageReady), image: \(self.capturedImage != nil)")
                }
            }
        }
        
        // Assigner le délégué
        picker.delegate = self.imagePickerDelegate
        
        // Présenter le picker de photos
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(picker, animated: true)
        }
    }
    
    private func deleteChecks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(checks[index])
            }
        }
    }
    
    class ImagePickerDelegate: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onImagePicked: (UIImage) -> Void
        
        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
            super.init()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("Délégué: image sélectionnée")
            
            // Essayer d'abord avec l'image éditée si disponible
            if let editedImage = info[.editedImage] as? UIImage {
                print("Utilisation de l'image éditée")
                self.onImagePicked(editedImage)
            }
            // Sinon utiliser l'image originale
            else if let originalImage = info[.originalImage] as? UIImage {
                print("Utilisation de l'image originale")
                self.onImagePicked(originalImage)
            }
            else {
                print("Aucune image trouvée dans info")
            }
            
            // Attendre un court instant avant de fermer le picker
            // pour s'assurer que les callbacks sont complétés
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                picker.dismiss(animated: true)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("Sélection d'image annulée")
            picker.dismiss(animated: true)
        }
    }
}
struct CheckRowView: View {
    let check: Check
    
    var body: some View {
        NavigationLink {
            CheckDetailView(check: check)
        } label: {
            HStack {
                // Ajout de l'image miniature
                if let imageData = check.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "doc.text.viewfinder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(10)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading) {
                    // Afficher soit la banque, soit le destinataire, soit "Chèque" par défaut
                    Text(check.bank ?? check.recipient ?? "Chèque")
                        .font(.headline)
                    if let checkNumber = check.checkNumber {
                        Text("N° \(checkNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(String(format: "%.2f €", check.amount))
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .padding(.vertical, 4)
        }
    }
}
struct CheckDetailView: View {
    let check: Check
    @Environment(\.dismiss) private var dismiss
    
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
            }
            .padding()
        }
        .navigationTitle("Détails du chèque")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Ajout d'un bouton Retour en français
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
    
    // Fonction pour formater la date en français
    private func formatDate(_ date: Date, includeTime: Bool) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = includeTime ? .short : .none
        dateFormatter.locale = Locale(identifier: "fr_FR")
        return dateFormatter.string(from: date)
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

#Preview {
    ContentView()
        .modelContainer(for: Check.self, inMemory: true)
}
