import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var checks: [Check]
    @State private var checkToDelete: Check? = nil
    @State private var showingDeleteConfirmation = false
    @State private var deletionInProgress = false
    @StateObject private var appState = AppState.shared
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage? = nil
    @State private var isImageReady = false
    @State private var isAnalyzing = false
    @State private var showPremiumView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if checks.isEmpty {
                        EmptyChecksView(onAddButtonTapped: {
                            let modelContainer = try? ModelContainer(for: Check.self)
                            let canAddMoreChecks = appState.isPremium || CheckLimitManager.shared.canAddMoreChecks(modelContainer: modelContainer)
                            
                            if canAddMoreChecks {
                                showingImagePicker = true
                            } else {
                                showPremiumView = true
                            }
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
                .blur(radius: showingDeleteConfirmation ? 2 : 0)
                
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
                                
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingDeleteConfirmation = false
                                }
                                
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
            .disabled(deletionInProgress)
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
            .fullScreenCover(isPresented: $showPremiumView) {
                NavigationStack {
                    PremiumBlockView()
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
    
    private func handleCapturedImage(_ image: UIImage?) {
        isAnalyzing = true
        
        guard let image = image else {
            isAnalyzing = false
            return
        }
        
        // Vérifier si l'utilisateur peut ajouter un nouveau chèque
        let modelContainer = try? ModelContainer(for: Check.self)
        let canAddMoreChecks = appState.isPremium || CheckLimitManager.shared.canAddMoreChecks(modelContainer: modelContainer)
        
        if !canAddMoreChecks {
            isAnalyzing = false
            showPremiumView = true
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
    HomeView()
        .modelContainer(for: Check.self, inMemory: true)
}
