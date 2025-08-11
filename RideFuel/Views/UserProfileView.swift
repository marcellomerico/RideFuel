//
//  UserProfileView.swift
//  RideFuel
//
//  Created by Marcello Merico on 11.08.25.
//

import SwiftUI

struct UserProfileView: View {
    @AppStorage("isAdminSession") private var isAdminSession: Bool = false
    @State private var showAdmin = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Profil") {
                    Text("Angemeldet als: Gast") // später echter Name wegen Login
                }
                
                Section("Admin") {
                    if isAdminSession {
                        Text("Adminrechte aktiv")
                        NavigationLink("Admin Panel öffnen") { AdminView() }
                    } else {
                        Button("Als Admin anmelden") { showAdmin = true }
                    }
                }
            }
            .navigationTitle("Profil")
        }
        .sheet(isPresented: $showAdmin) {
            AdminUnlockView {
                isAdminSession = true
            }
        }
    }
}


#Preview {UserProfileView()}
