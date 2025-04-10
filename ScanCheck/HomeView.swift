import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var checks: [Check]
    @State private var checkToDelete: Check? = nil
    @State private var showingDeleteConfirmation = false
    @State private var deletionInProgress = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if checks.isEmpty {
                        EmptyChecksView(onAddButtonTapped: {
                            AppState.shared.showAddSheet = true
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



#Preview {
    HomeView()
        .modelContainer(for: Check.self, inMemory: true)
}
