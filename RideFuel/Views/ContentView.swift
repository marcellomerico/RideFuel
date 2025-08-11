//
//  ContentView.swift
//  RideFuel
//
//  Created by Marcello Merico on 06.08.25.
//
import SwiftUI
import CoreData


struct ContentView: View {
    @Environment(\.managedObjectContext) private var context

    var body: some View {
        NavigationStack {
            Text("Herzlich Wilkommen bei \nRideFuel")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Text("Hier befindet sich das Dashboard der App")
                .padding()
            Text("Hier Wird man später begrüßt und bekommt eine Übersicht über die App, News, Rezept des Monats, Woche und Tages. Ein Würfel der zufällig ein Rezept aus der Datenbank auslöst.")
        }
        .navigationTitle(Text("RideFuel"))
    }
        
}

#Preview {
    ContentView()
}
