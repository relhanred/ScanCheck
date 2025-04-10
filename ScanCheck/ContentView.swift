import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var checks: [Check]
    @State private var showingAddSheet = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var isImageReady = false
    @State private var checkToDelete: Check? = nil
    @State private var showingDeleteConfirmation = false
    @State private var deletionInProgress = false
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if checks.isEmpty {
                        EmptyChecksView(onAddButtonTapped: {
                            showingAddSheet = true
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
            .toolbar(content: {
                if !checks.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showingAddSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                                .symbolEffect(.bounce, options: .repeating, value: checks.isEmpty)
                        }
                    }
                }
            })
            .sheet(isPresented: $showingAddSheet) {
                AddCheckView()
                    .environment(\.modelContext, modelContext)
            }
            .sheet(isPresented: $isImageReady) {
                if let image = capturedImage {
                    CheckFormView(image: image)
                        .environment(\.modelContext, modelContext)
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
}

struct CheckRowView: View {
    let check: Check
    
    var body: some View {
        NavigationLink {
            CheckDetailView(check: check)
        } label: {
            HStack {
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
