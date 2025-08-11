//
//  RecipeCreateView.swift
//  RideFuel
//
//  Created by Marcello Merico on 11.08.25.
//

import SwiftUI

struct RecipeCreateView: View {
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Rezept erstellen")
                .font(.title2).bold()
            Text("Hier bauen wir später das Formular und/oder den Admin-Import weiter aus.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle(Text("Rezept erstellen"))
    }
}

#Preview {
    RecipeCreateView()
}
