import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabBarView()
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
