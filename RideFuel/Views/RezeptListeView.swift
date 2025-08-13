//
//  RezeptListeView.swift
//  RideFuel
//
//  Created by Marcello Merico on 06.08.25.
//

import SwiftUI
import CoreData

// Bildschirmansicht für gespeicherte Rezepte
// Enthält KEINE Filterlogik, die liegt im RezeptListeModel
struct RezeptListeScreen: View {
    // Core-Data Kontext (für spätere Aktion nützlich)
    @Environment(\.managedObjectContext) private var viewContext
    
    // Holt alle gespeicherten Rezepte aus Core Data (alphabetisch)
    @FetchRequest(entity: Rezept.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Rezept.name, ascending: true)]
    ) private var rezepte: FetchedResults<Rezept>
    
    // ViewModel/Logik (Filter, Suchbegriff)
    @StateObject private var model = RezeptListeModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Hintergrund wie im Dashboard (weicher Verlauf)
                LinearGradient(colors: [AppTheme.bg, .white],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Kopfbereich: Titel + Suchfeld
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rezepte")
                            .padding(.horizontal)
                            .font(.largeTitle.bold())
                            .foregroundStyle(AppTheme.text)
                        
                        // Suchfeld im Chip-Stil
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyiingglass")
                                .foregroundStyle(AppTheme.text.opacity(0.6))
                            
                            // Bindung an das Model: ändert sich live beim Tippen
                            TextField("Suche in gespeicherten Rezepten", text: $model.suchbegriff)
                                .padding(12)
                                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.horizontal)
                        
                        // Rezeptliste als ScrollView + LazyVStack
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Wir reichen ein Array an die Logik und bekommen gefilterte Rezepte zurück
                                ForEach(model.gefiltert(Array(rezepte)), id: \.objectID) { rezept in
                                    // Navigation in die Detailansicht beim tippen
                                    NavigationLink {
                                        RezeptDetailView(rezept: rezept)
                                    } label: {
                                        RezeptCard(rezept: rezept) // unsere Karte
                                            .padding(.horizontal)
                                            .transition(.opacity.combined(with: .scale))
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                        .scrollIndicators(.hidden)
                    }
                    .padding(.top, 16)
                }
                .navigationBarHidden(true)
            }
        }
    }
    
    
    // Einzelne Rezept-Karte im Card Design
    // Zeigt Bild mit HTTPS-Fix, Titel und einfache MAkrozeile
    private struct RezeptCard: View {
        let rezept: Rezept
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                
                // 1) Bild: eine URL bauen mit HTTPS-Fix
                if let url = bildURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            // Platzhalter
                            ProgressView()
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .clipped() // überschüssige Ränder abschneiden
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        
                        case .failure:
                            // Wenn die URL nicht läd -> Platzhalter
                            platzhalter
                            
                            @unknown default:
                            platzhalter
                        }
                    }
                } else {
                    // Wenn es garkeine valide URL gibt -> Platzhalter
                    platzhalter
                }
                
                // 2) Titel
                Text(rezept.name ?? "Unbekanntes Rezept")
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(2)
                
                // Simple Makros
                HStack(spacing: 12) {
                    Label("\(rezept.kcal) kcal", systemImage: "flame.fill")
                    Label("\(String(format: "%.0f", rezept.kohlenhydrate)) g Carbs", systemImage: "leaf")
                }
                .font(.caption)
                .foregroundStyle(AppTheme.text.opacity(0.7))
            }
            .padding(14)
            .background(
                // Helle Card mit runden Ecken
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.95))
            )
            .shadow(color: .black.opacity(0.07), radius: 10, y: 6) // Schatten
        }
        
        // Bildplatzhalter
        private var platzhalter: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(height: 180)
                Image(systemName: "photo")
                    .imageScale(.large)
                foregroundStyle(AppTheme.accent)
            }
        }
        
        // Baut eine URL aus bildURL und erzwingt HTTPS
        private var bildURL: URL? {
            guard let s = rezept.bildURL, !s.isEmpty else { return nil }
            let secure = s.replacingOccurrences(of: "http://", with: "https://")
            return URL(string: secure)
        }
    }
    
    
    
    
    
}

#Preview{
    RezeptListeScreen()
}
