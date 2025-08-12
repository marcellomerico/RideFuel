import SwiftUI
import CoreData

struct RezeptDetailView: View {
    let rezept: Rezept
    @State private var ingredientCheckStates: [UUID: Bool] = [:]
    
    // UserDefaults key for persistent storage
    private var checkStateKey: String {
        "ingredient_check_states_\(rezept.id?.uuidString ?? "unknown")"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Bild
                RezeptDetailImage(urlString: rezept.bildURL)

                // Titel
                Text(rezept.name ?? "Unbekanntes Rezept")
                    .font(.title)
                    .bold()

                // Makros/Angaben
                HStack(spacing: 12) {
                    Label("\(rezept.kcal) kcal", systemImage: "flame")
                    Label("\(formattedCarbs) g Carbs", systemImage: "leaf")
                    Label("\(formattedProtein) g Protein", systemImage: "dumbbell")
                    Label("\(formattedFat) g Fett", systemImage: "drop")
                }
                .foregroundColor(.secondary)
                .font(.caption)

                Divider()

                // Zutaten mit Checkboxen
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Zutaten")
                            .font(.headline)
                        Spacer()
                        Button(action: toggleAllIngredients) {
                            Text(allIngredientsChecked ? "Alle abwählen" : "Alle auswählen")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let set = rezept.zutaten, let zutaten = Array(set) as? [Zutat], !zutaten.isEmpty {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(zutaten, id: \.self) { zutat in
                                IngredientCheckboxRow(
                                    zutat: zutat,
                                    isChecked: Binding(
                                        get: { ingredientCheckStates[zutat.id ?? UUID()] ?? false },
                                        set: { newValue in
                                            ingredientCheckStates[zutat.id ?? UUID()] = newValue
                                            saveCheckStates() // Save immediately when checkbox changes
                                        }
                                    )
                                )
                            }
                        }
                        
                        // Shopping Summary
                        if !uncheckedIngredients.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Divider()
                                Text("Einkaufsliste (\(uncheckedIngredients.count) Artikel)")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.orange)
                                
                                ForEach(uncheckedIngredients, id: \.self) { zutat in
                                    HStack {
                                        Image(systemName: "cart")
                                            .foregroundColor(.orange)
                                        Text(zutat.menge ?? "")
                                            .foregroundColor(.secondary)
                                        Text(zutat.name ?? "")
                                    }
                                    .font(.caption)
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                    } else {
                        Text("Keine Zutaten vorhanden")
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Anleitung/Zubereitung
                VStack(alignment: .leading, spacing: 8) {
                    Text("Zubereitung")
                        .font(.headline)
                    
                    if let text = rezept.beschreibung, !text.isEmpty {
                        if let url = URL(string: text), text.hasPrefix("http") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Für die vollständige Anleitung besuchen Sie:")
                                    .foregroundColor(.secondary)
                                Link("Rezept öffnen", destination: url)
                                    .buttonStyle(.borderedProminent)
                            }
                        } else {
                            Text(text)
                                .lineLimit(nil)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Keine detaillierte Anleitung verfügbar")
                                .foregroundColor(.secondary)
                            Text("Tipp: Verwenden Sie die Zutaten-Checkliste oben für eine bessere Übersicht beim Kochen!")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }

            }
            .padding()
        }
        .navigationTitle("Rezept Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            initializeCheckStates()
        }
    }
    
    // MARK: - Computed Properties
    private var formattedCarbs: String {
        String(format: "%.1f", rezept.kohlenhydrate)
    }
    
    private var formattedProtein: String {
        String(format: "%.1f", rezept.eiweis)
    }
    
    private var formattedFat: String {
        String(format: "%.1f", rezept.fett)
    }
    
    private var allIngredientsChecked: Bool {
        guard let set = rezept.zutaten, set.count > 0 else { return false }
        let zutaten = Array(set) as? [Zutat] ?? []
        return zutaten.allSatisfy { ingredientCheckStates[$0.id ?? UUID()] == true }
    }
    
    private var uncheckedIngredients: [Zutat] {
        guard let set = rezept.zutaten, let zutaten = Array(set) as? [Zutat] else { return [] }
        return zutaten.filter { ingredientCheckStates[$0.id ?? UUID()] != true }
    }
    
    
    
    // MARK: - Functions
    private func initializeCheckStates() {
        guard let set = rezept.zutaten, let zutaten = Array(set) as? [Zutat] else { return }
        
        // Load saved states from UserDefaults
        if let savedStates = UserDefaults.standard.object(forKey: checkStateKey) as? [String: Bool] {
            for zutat in zutaten {
                let key = zutat.id?.uuidString ?? UUID().uuidString
                ingredientCheckStates[zutat.id ?? UUID()] = savedStates[key] ?? false
            }
        } else {
            // Initialize all to false if no saved states
            for zutat in zutaten {
                ingredientCheckStates[zutat.id ?? UUID()] = false
            }
        }
    }
    
    private func saveCheckStates() {
        guard let set = rezept.zutaten, let zutaten = Array(set) as? [Zutat] else { return }
        
        var statesToSave: [String: Bool] = [:]
        for zutat in zutaten {
            let key = zutat.id?.uuidString ?? UUID().uuidString
            statesToSave[key] = ingredientCheckStates[zutat.id ?? UUID()] ?? false
        }
        
        UserDefaults.standard.set(statesToSave, forKey: checkStateKey)
    }
    
    private func toggleAllIngredients() {
        guard let set = rezept.zutaten, let zutaten = Array(set) as? [Zutat] else { return }
        let newValue = !allIngredientsChecked
        for zutat in zutaten {
            ingredientCheckStates[zutat.id ?? UUID()] = newValue
        }
        saveCheckStates() // Save after bulk change
    }
}

// MARK: - Ingredient Checkbox Row
private struct IngredientCheckboxRow: View {
    let zutat: Zutat
    @Binding var isChecked: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: { isChecked.toggle() }) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let menge = zutat.menge, !menge.isEmpty {
                        Text(menge)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Text(zutat.name ?? "Unbekannte Zutat")
                        .font(.body)
                        .strikethrough(isChecked)
                        .foregroundColor(isChecked ? .secondary : .primary)
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isChecked.toggle()
        }
    }
}

// MARK: - Image helper
private struct RezeptDetailImage: View {
    let urlString: String?

    var body: some View {
        Group {
            if let s = urlString, !s.isEmpty, let url = URL(string: secureURLString(s)) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 240)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(height: 240)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .frame(height: 240)
            .frame(maxWidth: .infinity)
            .foregroundColor(.gray)
    }

    // erzwinge https, damit AsyncImage lädt
    private func secureURLString(_ s: String) -> String {
        s.replacingOccurrences(of: "http://", with: "https://")
    }
}

#Preview {
    // Versucht ein Beispielrezept aus dem Preview-Container zu laden
    let context = PersistenceController.preview.container.viewContext
    let fetch: NSFetchRequest<Rezept> = Rezept.fetchRequest()
    let rezepte = (try? context.fetch(fetch)) ?? []
    return NavigationView {
        if let r = rezepte.first {
            RezeptDetailView(rezept: r)
        } else {
            Text("Kein Beispielrezept im Preview verfügbar")
                .padding()
        }
    }
}