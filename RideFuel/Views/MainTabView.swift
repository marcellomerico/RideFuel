//
//  MainTabView.swift
//  RideFuel
//
//  Created by Marcello Merico on 11.08.25.
//

import SwiftUI
import CoreData

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        TabView {
            // Home
            ContentView()
                .tabItem{ Label("Home", systemImage: "house")}
            
            // Rezepte (Liste aus Core Data)
            RezeptListeScreen()
                .tabItem{ Label("Rezepte", systemImage: "book.fill")}
            
            // Rezepte erstellen in Core Data speichern
            RecipeCreateView()
                .tabItem{ Label("Neues Rezept", systemImage: "plus")}
            
            // Profil (mit Admin Zugang)
            UserProfileView()
                .tabItem{ Label("Profil", systemImage: "person.circle")}
        }
    }
}

#Preview {
    MainTabView()
}
