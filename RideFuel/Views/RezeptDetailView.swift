import SwiftUI
import CoreData

struct RezeptDetailView: View {
    let rezept: Rezept

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
                }
                .foregroundColor(.secondary)

                Divider()

                // Zutaten aus Relation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Zutaten").font(.headline)
                    if let set = rezept.zutaten, let zutaten = Array(set) as? [Zutat], !zutaten.isEmpty {
                        ForEach(zutaten, id: \.self) { z in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(z.menge ?? "").foregroundColor(.secondary)
                                Text(z.name ?? "Unbekannte Zutat")
                            }
                        }
                    } else {
                        Text("Keine Zutaten vorhanden").foregroundColor(.secondary)
                    }
                }

                // Anleitung/Quelle: vorerst aus 'beschreibung' (z. B. Source URL)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Anleitung").font(.headline)
                    if let text = rezept.beschreibung, !text.isEmpty {
                        if let url = URL(string: text), text.hasPrefix("http") {
                            Link("Quelle öffnen", destination: url)
                        } else {
                            Text(text)
                        }
                    } else {
                        Text("Keine Anleitung hinterlegt").foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var formattedCarbs: String {
        String(format: "%.1f", rezept.kohlenhydrate)
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
