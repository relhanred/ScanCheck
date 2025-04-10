import SwiftUI
import SwiftData

struct ExportView: View {
    @Query private var checks: [Check]
    @State private var showingPremiumAlert = false
    @State private var selectedFormat: ExportFormat?
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage? = nil
    @State private var isImageReady = false
    @State private var isAnalyzing = false
    
    enum ExportFormat: String {
        case pdf = "PDF"
        case excel = "Excel"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if checks.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun chèque à exporter", systemImage: "square.and.arrow.up")
                    } description: {
                        Text("Ajoutez d'abord des chèques pour pouvoir les exporter")
                    } actions: {
                        Button {
                            showingImagePicker = true
                        } label: {
                            Text("Ajouter un chèque")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.black)
                    }
                } else {
                    List {
                        Section(header: Text("Options d'exportation")) {
                            Button {
                                selectedFormat = .pdf
                                showingPremiumAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "doc.richtext")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Exporter en PDF")
                                            .foregroundColor(.primary)
                                        Text("Tous les chèques avec leurs images")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                            
                            Button {
                                selectedFormat = .excel
                                showingPremiumAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "tablecells")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Exporter en Excel")
                                            .foregroundColor(.primary)
                                        Text("Données tabulaires pour analyse")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        
                        Section(header: Text("Statistiques")) {
                            HStack {
                                Image(systemName: "number")
                                    .foregroundColor(.blue)
                                    .frame(width: 32)
                                Text("Nombre de chèques")
                                Spacer()
                                Text("\(checks.count)")
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Image(systemName: "eurosign")
                                    .foregroundColor(.blue)
                                    .frame(width: 32)
                                Text("Montant total")
                                Spacer()
                                Text(String(format: "%.2f €", checks.reduce(0) { $0 + $1.amount }))
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Export")
            .alert("Fonctionnalité Premium", isPresented: $showingPremiumAlert) {
                Button("S'abonner", role: .none) {
                    // Action pour s'abonner
                }
                Button("Plus tard", role: .cancel) {}
            } message: {
                if selectedFormat == .pdf {
                    Text("L'export PDF est disponible avec l'abonnement ScanCheck Premium.")
                } else {
                    Text("L'export Excel est disponible avec l'abonnement ScanCheck Premium.")
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraCaptureView { image in
                    handleCapturedImage(image)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                GalleryPickerView { image in
                    handleCapturedImage(image)
                }
            }
            .sheet(isPresented: $isImageReady) {
                if let image = capturedImage {
                    CheckFormView(image: image)
                }
            }
            .overlay {
                if isAnalyzing {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        
                        Text("Préparation de l'image...")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 10)
                    }
                    .frame(width: 250, height: 150)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                }
            }
        }
    }
    
    private func handleCapturedImage(_ image: UIImage?) {
        isAnalyzing = true
        
        guard let image = image else {
            isAnalyzing = false
            return
        }
        
        DispatchQueue.main.async {
            let imageCopy = image.copy() as! UIImage
            self.capturedImage = imageCopy
            self.isAnalyzing = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isImageReady = true
            }
        }
    }
}

#Preview {
    ExportView()
        .modelContainer(for: Check.self, inMemory: true)
}
