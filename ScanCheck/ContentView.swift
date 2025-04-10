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
    @State private var checkToDelete: Check? = nil
    @State private var showingDeleteConfirmation = false
    @State private var deletionInProgress = false
    @State private var isAnalyzing = false
    @State private var analysisError: String? = nil
    
    // On conserve une référence forte au délégué pour éviter sa déallocation
    @State private var imagePickerDelegate: ImagePickerDelegate?
    
    // Service d'analyse
    private let analyzerService = CheckAnalyzerService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if checks.isEmpty {
                        EmptyChecksView(onAddButtonTapped: {
                            showingSourceOptions = true
                        })
                    } else {
                        List {
                            ForEach(checks) { check in
                                CheckRowView(check: check)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            checkToDelete = check
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Supprimer", systemImage: "trash.fill")
                                        }
                                        .tint(.red)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            checkToDelete = check
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Supprimer", systemImage: "trash.fill")
                                        }
                                    }
                            }
                            .onDelete(perform: deleteChecks)
                        }
                        .animation(.default, value: checks.count)
                    }
                }
                .onAppear {
                        if let image = UIImage(named: "check") {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            print("Image enregistrée dans la photothèque.")
                        } else {
                            print("Image 'test' non trouvée.")
                        }
                    }
                .onAppear {
                        if let image = UIImage(named: "cqk-credit-agricole") {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            print("Image enregistrée dans la photothèque.")
                        } else {
                            print("Image 'test' non trouvée.")
                        }
                    }
                .onAppear {
                        if let image = UIImage(named: "chk-bp") {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            print("Image enregistrée dans la photothèque.")
                        } else {
                            print("Image 'test' non trouvée.")
                        }
                    }
                .onAppear {
                        if let image = UIImage(named: "chq") {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            print("Image enregistrée dans la photothèque.")
                        } else {
                            print("Image 'test' non trouvée.")
                        }
                    }
                .onAppear {
                        if let image = UIImage(named: "lcl") {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            print("Image enregistrée dans la photothèque.")
                        } else {
                            print("Image 'test' non trouvée.")
                        }
                    }
                .blur(radius: showingDeleteConfirmation ? 2 : 0)
                
                // Overlay de confirmation de suppression
                if showingDeleteConfirmation, let check = checkToDelete {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingDeleteConfirmation = false
                            }
                        }
                    
                    VStack {
                        Spacer()
                        
                        ContextualDeleteConfirmation(
                            isVisible: $showingDeleteConfirmation,
                            checkInfo: check.bank ?? check.recipient ?? "Chèque",
                            amount: check.amount,
                            onConfirm: {
                                deletionInProgress = true
                                
                                // Animation de disparition
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingDeleteConfirmation = false
                                }
                                
                                // Suppression après la fin de l'animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        deleteCheck(check)
                                        checkToDelete = nil
                                        deletionInProgress = false
                                    }
                                }
                            },
                            onCancel: {
                                showingDeleteConfirmation = false
                                checkToDelete = nil
                            }
                        )
                        .transition(.move(edge: .bottom))
                        
                        Spacer().frame(height: 30)
                    }
                    .transition(.opacity)
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
                                .symbolEffect(.bounce, options: .repeating, value: checks.isEmpty)
                        }
                    }
                }
            })
            .sheet(isPresented: $showingCheckForm) {
                if let image = capturedImage, isImageReady {
                    CheckFormView(image: image)
                        .environment(\.modelContext, modelContext)
                        .onDisappear {
                            // Réinitialiser l'état
                            capturedImage = nil
                            isImageReady = false
                            try? modelContext.save()
                        }
                } else {
                    // Afficher un message d'erreur si l'image n'est pas disponible
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
        .disabled(deletionInProgress || isAnalyzing)
        .overlay {
            if isAnalyzing {
                ZStack {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        
                        Text("Préparation de l'image...")
                            .font(.headline)
                            .padding(.top, 10)
                    }
                    .frame(width: 250, height: 150)
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
            }
        }
    }
    
    private func captureImageFromCamera() {
        isAnalyzing = true
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        
        // Créer et stocker le délégué avec une logique plus robuste
        self.imagePickerDelegate = ImagePickerDelegate { image in
            isAnalyzing = false
            
            guard let image = image else {
                print("Aucune image capturée")
                return
            }
            
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
        isAnalyzing = true
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        
        // Créer et stocker le délégué avec une logique plus robuste
        self.imagePickerDelegate = ImagePickerDelegate { image in
            isAnalyzing = false
            
            guard let image = image else {
                print("Aucune image sélectionnée")
                return
            }
            
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
        withAnimation(.easeInOut(duration: 0.3)) {
            for index in offsets {
                modelContext.delete(checks[index])
            }
            try? modelContext.save()
        }
    }
    
    private func deleteCheck(_ check: Check) {
        withAnimation(.easeInOut(duration: 0.3)) {
            modelContext.delete(check)
            try? modelContext.save()
        }
    }
    
    class ImagePickerDelegate: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onImagePicked: (UIImage?) -> Void
        
        init(onImagePicked: @escaping (UIImage?) -> Void) {
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
                self.onImagePicked(nil)
            }
            
            // Attendre un court instant avant de fermer le picker
            // pour s'assurer que les callbacks sont complétés
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                picker.dismiss(animated: true)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("Sélection d'image annulée")
            self.onImagePicked(nil)
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
        .swipeActions(edge: .leading) {
            NavigationLink(destination: CheckEditView(check: check)) {
                Label("Modifier", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Check.self, inMemory: true)
}
