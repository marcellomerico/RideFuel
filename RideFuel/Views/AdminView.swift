//
//  AdminView.swift
//  RideFuel
//
//  Created by Marcello Merico on 11.08.25.
//

import SwiftUI
import CoreData

@MainActor
struct AdminView: View {
    @Environment(\.managedObjectContext) private var context

    // Admin-Session nur für die aktuelle App-Sitzung
    @AppStorage("isAdminSession") private var isAdminSession: Bool = false

    // UI-States
    @State private var suchbegriff: String = ""
    @State private var info: String = ""
    @State private var showingSuggestions: Bool = false
    
    // German recipe search suggestions
    private let deutscheRezeptSuggestions = [
        "Nudel", "Hafer", "Sauerbraten", "Schnitzel", "Rouladen", "Spätzle", 
        "Gulasch", "Bratwurst", "Sauerkraut", "Kartoffel", "Fleisch", "Fisch",
        "Brot", "Kuchen", "Suppe", "Eintopf", "Käse", "Gemüse", "Salat",
        "Apfelstrudel", "Lebkuchen", "Stollen", "Kartoffelpuffer", "Currywurst", 
        "Döppekuchen", "Königsberger Klopse", "Schweinshaxe", "Maultaschen",
        "Kassler", "Eisbein", "Frikadellen", "Schwarzwälder Kirschtorte", "Knödel"
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Admin Panel")
                .font(.largeTitle).bold()

            if isAdminSession {
                Text("✅ Adminrechte aktiv")
                    .font(.headline)
                    .foregroundColor(.green)

                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Deutsche Rezepte suchen (z.B. Nudel, Hafer, Schnitzel)", text: $suchbegriff)
                            .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Button("Vorschläge anzeigen") {
                                showingSuggestions.toggle()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            
                            Spacer()
                        }
                        
                        if showingSuggestions {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(deutscheRezeptSuggestions.prefix(10), id: \.self) { suggestion in
                                        Button(suggestion) {
                                            suchbegriff = suggestion
                                            showingSuggestions = false
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                            .frame(maxHeight: 40)
                        }
                    }

                    Button("Deutsche Rezepte von API laden & speichern") {
                        Task { await ladeUndSpeichere() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Alle Rezepte aus Core Data löschen") { loescheAlleRezepte() }
                        .buttonStyle(.bordered)
                        .tint(.red)
                }

                if !info.isEmpty {
                    Text(info)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button("Admin abmelden") { isAdminSession = false }
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Adminbereich")
        // Login passiert nun ausschließlich über die Profil-Ansicht
    }

    // MARK: - Import/Save
    @MainActor private func ladeUndSpeichere() async {
        let term = suchbegriff.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { info = "Bitte einen Suchbegriff eingeben (z.B. Nudel, Hafer, Schnitzel)."; return }

        info = "Suche nach Rezepten für: \(term)..."
        let apiRezepte = await RezeptAPIService.shared.fetchRezepte(suchbegriff: term)

        var hinzugefuegt = 0
        for api in apiRezepte {
            // Duplikate über Namen vermeiden
            let req: NSFetchRequest<Rezept> = Rezept.fetchRequest()
            req.predicate = NSPredicate(format: "name == %@", api.title)
            let vorhandene = (try? context.fetch(req)) ?? []
            if !vorhandene.isEmpty { continue }

            let r = Rezept(context: context)
            r.id = UUID()
            r.name = api.title
            
            // Enhanced nutrition data processing
            let kcalValue = api.nutrition?.kcal ?? 0
            let clampedKcal = max(0, min(kcalValue, Int(Int16.max)))
            r.kcal = Int16(clampedKcal)
            
            // Save additional nutrition data from German API
            r.kohlenhydrate = api.nutrition?.carbs ?? 0.0
            r.eiweis = api.nutrition?.protein ?? 0.0
            r.fett = api.nutrition?.fat ?? 0.0
            
            if let raw = api.image_urls?.first(where: { !$0.isEmpty }) {
                r.bildURL = raw.hasPrefix("http://") ? raw.replacingOccurrences(of: "http://", with: "https://") : raw
            } else {
                r.bildURL = ""
            }

            // Process ingredients and instructions directly from German API
            
            // Save instructions if available
            if let instructions = api.instructions, !instructions.isEmpty {
                r.beschreibung = instructions
            }
            
            // Save ingredients directly from German API
            if let ingredients = api.ingredients {
                ingredients.forEach { ing in
                    let z = Zutat(context: context)
                    z.id = UUID()
                    z.name = ing.description
                    
                    
                    // Format quantity and unit
                    let qty = ing.quantity.map { String(format: "%.2f", $0) } ?? ""
                    let unit = ing.unit ?? ""
                    let menge = [qty, unit].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.joined(separator: " ")
                    z.menge = menge.isEmpty ? nil : menge
                    
                    
                    r.addToZutaten(z)
                }
            } else {
                
                // Fallback: Try to fetch details for Forkify API recipes
                if let detail = await RezeptAPIService.shared.fetchRezeptDetail(id: api.id) {
                    if let src = detail.source_url, !src.isEmpty { r.beschreibung = src }
                    detail.ingredients.forEach { ing in
                        let z = Zutat(context: context)
                        z.id = UUID()
                        z.name = ing.description
                        let qty = ing.quantity.map { String(format: "%.2f", $0) } ?? ""
                        let unit = ing.unit ?? ""
                        let menge = [qty, unit].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.joined(separator: " ")
                        z.menge = menge.isEmpty ? nil : menge
                        r.addToZutaten(z)
                    }
                }
            }
            hinzugefuegt += 1
        }
        do {
            try context.save()
            info = "Import abgeschlossen: \(hinzugefuegt) neue deutsche Rezepte gespeichert."
            suchbegriff = ""
        } catch {
            info = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }

    @MainActor private func loescheAlleRezepte() {
        let fetch: NSFetchRequest<Rezept> = Rezept.fetchRequest()
        do {
            let alle = try context.fetch(fetch)
            for r in alle { context.delete(r) }
            try context.save()
            info = "Alle Rezepte gelöscht."
        } catch {
            info = "Löschen fehlgeschlagen: \(error.localizedDescription)"
        }
    }

}


#Preview {
    NavigationView { AdminView() }
}
