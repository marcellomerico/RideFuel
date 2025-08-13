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
    
    // Daten holen
    @FetchRequest(
        entity: Rezept.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Rezept.name, ascending: true)]
    ) private var rezepte: FetchedResults<Rezept>
    
    @State private var selected: Rezept?
    @State private var showNoDataAlert = false
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppTheme.bg, Color.white],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                VStack (alignment: .leading, spacing: 20){
                    // Begrüßung
                    Text("\(DashboardLogic.greeting())")
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppTheme.text)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 1), spacing: 14) {
                        
                        FeaturedTile(
                            title: "Rezept des Tages",
                            subtitle: DashboardLogic.pick(.day, from: Array(rezepte))?.name ?? "Noch keins",
                            tint: AppTheme.accent,
                            icon: "fork.knife"
                        ) {
                            openPicked(.day)
                        }
                        
                        FeaturedTile (
                            title: "Rezept der Woche",
                            subtitle: DashboardLogic.pick(.week, from: Array(rezepte))?.name ?? "Noch keins",
                            tint: AppTheme.accent,
                            icon: "fork.knife"
                            
                        ) {
                            openPicked(.week)
                        }
                        
                        FeaturedTile(
                            title: "Rezept des Monats",
                            subtitle: DashboardLogic.pick(.month, from: Array(rezepte))?.name ?? "Noch keins",
                            tint: AppTheme.accent,
                            icon: "fork.knife"
                            
                        ) {
                            openPicked(.month)
                        }
                        
                        FeaturedTile(
                            title: "Würfel",
                            subtitle: "Zufälliges Rezept",
                            tint: AppTheme.cube,
                            icon: "die.face.5.fill",
                            action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                guard let r = Array(rezepte).randomElement() else {
                                    showNoDataAlert = true; return
                                }
                                selected = r
                            }
                        )
                        
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 0)
                }
                .padding(.top, 24)
            }
            .navigationDestination(item: $selected) { rezept in
                RezeptDetailView(rezept: rezept) // oder RezeptListeView()
            }
            .alert("Keine Rezepte vorhanden", isPresented: $showNoDataAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Importiere erst Rezepte im Admin-Bereich.")
            }
            .navigationBarHidden(true)
        }
    }
    
    private func openPicked(_ period: DashboardLogic.Period) {
        if let r = DashboardLogic.pick(period, from: Array(rezepte)) {
            selected = r
        } else {
            showNoDataAlert = true
        }
    }
    
    
    // MARK: UI Baustein
    private struct FeaturedTile: View {
        let title: String
        let subtitle: String?
        let tint: Color
        let icon: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(tint.opacity(0.18))
                        Image(systemName: icon)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(tint)
                    }
                    .frame(width: 64, height: 64)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(1)
                        Text(subtitle ?? "-")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.text.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(AppTheme.text.opacity(0.4))
                }
                .padding(16)
                .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.07), radius: 10, y: 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    
}

#Preview {
    ContentView()
}
