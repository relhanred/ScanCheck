import SwiftUI

struct TabBarView: View {
    @State private var selectedTab: Tab = .home
    @Namespace private var tabBarNamespace
    
    enum Tab {
        case home, add, export, profile
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                
                EmptyView()
                    .tag(Tab.add)
                
                ExportView()
                    .tag(Tab.export)
                
                ProfileView()
                    .tag(Tab.profile)
            }
            .ignoresSafeArea(edges: .bottom)
            
            CustomTabBar(selectedTab: $selectedTab, namespace: tabBarNamespace)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: TabBarView.Tab
    let namespace: Namespace.ID
    @State private var showAddSheet = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([TabBarView.Tab.home, .add, .export, .profile], id: \.self) { tab in
                Button {
                    if tab == .add {
                        showAddSheet = true
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
                            .foregroundColor(selectedTab == tab ? .black : .gray)
                            .frame(width: 32, height: 24)
                        }
                        
                        if tab != .add {
                            Text(tab == .home ? "Accueil" : tab == .export ? "Export" : "Profil")
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
        .sheet(isPresented: $showAddSheet) {
            AddCheckView()
        }
    }
}

#Preview {
    TabBarView()
        .modelContainer(for: Check.self, inMemory: true)
}
