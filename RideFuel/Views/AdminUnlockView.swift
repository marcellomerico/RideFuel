//
//  AdminUnlockView.swift
//  RideFuel
//
//  Created by Marcello Merico on 11.08.25.
//

import SwiftUI
import CryptoKit

struct AdminUnlockView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pin: String = ""
    var onSuccess: () -> Void
    
    // Demo Pin = 2468
    private let storedHash = "ee4d6820ef342fc99f5160fe49fd507c4c98b91e1c0eb07ae58edb3e2d3514a6"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                SecureField("Admin-PIN", text: $pin)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                
                Button("Freischalten") {
                    if sha256(pin) == storedHash {
                        onSuccess()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Abbrechen") { dismiss() }
                    .padding(.top, 8)
            }
            .padding()
            .navigationTitle(Text("Admin freischalten"))
        }
    }
    
    private func sha256(_ s: String) -> String {
        let data = Data(s.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map {String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    AdminUnlockView(){}
    }

