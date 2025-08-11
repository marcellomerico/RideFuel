import SwiftUI
import CryptoKit

struct ProfileView: View {
    @AppStorage("isAdminSession") private var isAdminSession: Bool = false
    @State private var showUnlock = false

    var body: some View {
        VStack(spacing: 16) {
            if isAdminSession {
                NavigationLink("Admin Panel öffnen") {
                    AdminView()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Als Admin anmelden") { showUnlock = true }
                    .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Profil")
        .sheet(isPresented: $showUnlock) {
            AdminUnlockView {
                isAdminSession = true
            }
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
}


