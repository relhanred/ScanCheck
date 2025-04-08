import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var checks: [Check]
    @State private var showingSourceOptions = false
    @State private var showingCheckForm = false
    @State private var capturedImage: UIImage?
    
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
                if let image = capturedImage {
                    CheckFormView(image: image)
                        .environment(\.modelContext, modelContext)
                        .onDisappear {
                            capturedImage = nil
                        }
                } else {
                    // Afficher un message d'erreur ou fermer la sheet
                    VStack {
                        Text("Aucune image disponible")
                            .padding()
                        Button("Fermer") {
                            showingCheckForm = false
                        }
                        .padding()
                    }
                    .onAppear {
                        // Fermer automatiquement la sheet si pas d'image
                        showingCheckForm = false
                    }
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
        }
    }
    
    private func captureImageFromCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        
        // Créer et stocker le délégué
        self.imagePickerDelegate = ImagePickerDelegate { image in
            // S'assurer que l'image est définie avant d'ouvrir la sheet
            self.capturedImage = image
            // Attendre un petit instant pour s'assurer que capturedImage est bien défini
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showingCheckForm = true
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
        
        // Créer et stocker le délégué
        self.imagePickerDelegate = ImagePickerDelegate { image in
            // S'assurer que l'image est définie avant d'ouvrir la sheet
            self.capturedImage = image
            // Attendre un petit instant pour s'assurer que capturedImage est bien défini
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showingCheckForm = true
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
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.onImagePicked(image)
                }
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
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
                VStack(alignment: .leading) {
                    Text(check.issuerName)
                        .font(.headline)
                    Text("N° \(check.checkNumber ?? "Non spécifié")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                    DetailRow(title: "Émetteur", value: check.issuerName)
                    DetailRow(title: "Montant", value: String(format: "%.2f €", check.amount))
                    DetailRow(title: "N° de chèque", value: check.checkNumber ?? "Non spécifié")
                    DetailRow(title: "Date de scan", value: check.scanDate.formatted(date: .long, time: .shortened))
                    
                    if let notes = check.notes, !notes.isEmpty {
                        Divider()
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .padding(.top, 4)
                    }
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
                .frame(width: 100, alignment: .leading)
            
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
