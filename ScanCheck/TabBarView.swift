import SwiftUI

struct TabBarView: View {
    @State private var selectedTab: Tab = .home
    @Namespace private var tabBarNamespace
    @StateObject private var appState = AppState.shared
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage? = nil
    @State private var isImageReady = false
    @State private var isAnalyzing = false
    
    enum Tab {
        case home, stats, add, export, profile
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                
                StatsView()
                    .tag(Tab.stats)
                
                EmptyView()
                    .tag(Tab.add)
                
                ExportView()
                    .tag(Tab.export)
                
                ProfileView()
                    .tag(Tab.profile)
            }
            .ignoresSafeArea(edges: .bottom)
            
            CustomTabBar(selectedTab: $selectedTab, namespace: tabBarNamespace, showCamera: {
                showingCamera = true
            }, showImagePicker: {
                showingImagePicker = true
            })
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

struct CustomTabBar: View {
    @Binding var selectedTab: TabBarView.Tab
    let namespace: Namespace.ID
    @StateObject private var appState = AppState.shared
    var showCamera: () -> Void
    var showImagePicker: () -> Void
    @State private var showingAddOptions = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([TabBarView.Tab.home, .stats, .add, .export, .profile], id: \.self) { tab in
                Button {
                    if tab == .add {
                        showingAddOptions = true
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == tab && tab != .add {
                                Circle()
                                    .fill(Color.black.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .matchedGeometryEffect(id: "selectedTabBackground", in: namespace)
                            }
                            
                            Group {
                                switch tab {
                                case .home:
                                    Image(systemName: "house.fill")
                                case .stats:
                                    Image(systemName: "chart.bar.fill")
                                case .add:
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 44))
                                        .offset(y: -5)
                                case .export:
                                    Image(systemName: "square.and.arrow.up")
                                case .profile:
                                    Image(systemName: "person")
                                }
                            }
                            .font(tab == .add ? .title : .body)
                            .foregroundColor(tab == .add ? .white : (selectedTab == tab ? .black : .gray))
                            .frame(width: 32, height: 24)
                        }
                        .background(
                            Circle()
                                .fill(Color.black)
                                .frame(width: 56, height: 56)
                                .offset(y: -5)
                                .opacity(tab == .add ? 1 : 0)
                        )
                        
                        if tab != .add {
                            Text(tab == .home ? "Accueil" :
                                 tab == .stats ? "Stats" :
                                 tab == .export ? "Export" : "Profil")
                                .font(.system(size: 10))
                                .foregroundColor(selectedTab == tab ? .black : .gray)
                        } else {
                            Spacer().frame(height: 10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
                .ignoresSafeArea()
        )
        .actionSheet(isPresented: $showingAddOptions) {
            ActionSheet(
                title: Text("Ajouter un chèque"),
                message: Text("Choisissez comment scanner votre chèque"),
                buttons: [
                    .default(Text("Prendre une photo")) {
                        showCamera()
                    },
                    .default(Text("Importer depuis la galerie")) {
                        showImagePicker()
                    },
                    .cancel()
                ]
            )
        }
    }
}

#Preview {
    TabBarView()
        .modelContainer(for: Check.self, inMemory: true)
}
