//
//  AdminView.swift
//  RideFuel
//
//  Created by Marcello Merico on 11.08.25.
//

import SwiftUI
import CoreData
import CryptoKit

@MainActor
struct AdminView: View {
    @Environment(\.managedObjectContext) private var context

    // Admin-Session nur für die aktuelle App-Sitzung
    @AppStorage("isAdminSession") private var isAdminSession: Bool = false

    // UI-States
    @State private var suchbegriff: String = ""
    @State private var info: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Admin Panel")
                .font(.largeTitle).bold()

            if isAdminSession {
                Text("✅ Adminrechte aktiv")
                    .font(.headline)
                    .foregroundColor(.green)

                VStack(spacing: 12) {
                    TextField("Suchbegriff (z. B. Nudeln)", text: $suchbegriff)
                        .textFieldStyle(.roundedBorder)

                    Button("Rezepte von API laden & speichern") {
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
        guard !term.isEmpty else { info = "Bitte einen Suchbegriff eingeben."; return }

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
            // kcal sicher in Int16-Bereich clampen
            let kcalValue = api.nutrition?.kcal ?? 0
            let clampedKcal = max(0, min(kcalValue, Int(Int16.max)))
            r.kcal = Int16(clampedKcal)
            // Pflichtwerte setzen (Core Data Double sind non-optional)
            r.kohlenhydrate = 0
            r.eiweis = 0
            r.fett = 0
            if let raw = api.image_urls?.first(where: { !$0.isEmpty }) {
                r.bildURL = raw.hasPrefix("http://") ? raw.replacingOccurrences(of: "http://", with: "https://") : raw
            } else {
                r.bildURL = ""
            }

            // Details (Zutaten/Quelle) nachladen
            if let detail = await RezeptAPIService.shared.fetchRezeptDetail(id: api.id) {
                // Quelle als Beschreibung ablegen, falls keine eigene Anleitung vorhanden ist
                if let src = detail.source_url, !src.isEmpty { r.beschreibung = src }
                // Zutaten speichern
                detail.ingredients.forEach { ing in
                    let z = Zutat(context: context)
                    z.id = UUID()
                    z.name = ing.description
                    let qty = ing.quantity.map { String(format: "%.2f", $0) } ?? ""
                    let unit = ing.unit ?? ""
                    let menge = [qty, unit].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.joined(separator: " ")
                    z.menge = menge
                    r.addToZutaten(z)
                }
            }
            hinzugefuegt += 1
        }
        do {
            try context.save()
            info = "Import abgeschlossen: \(hinzugefuegt) neue Rezepte gespeichert."
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

    // MARK: - PIN / Hash
    private func validatePin(_ pin: String) -> Bool {
        let storedHash = "ee4d6820ef342fc99f5160fe49fd507c4c98b91e1c0eb07ae58edb3e2d3514a6"
        return sha256(pin) == storedHash
    }

    private func sha256(_ s: String) -> String {
        let data = Data(s.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - PIN Sheet
@MainActor
private struct AdminPinSheet: View {
    @Binding var pin: String
    var onConfirm: @MainActor () -> Void
    var onCancel: @MainActor () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                SecureField("Admin-PIN", text: $pin)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                Button("Freischalten", action: onConfirm)
                    .buttonStyle(.borderedProminent)

                Button("Abbrechen", role: .cancel, action: onCancel)
                    .padding(.top, 8)

                Spacer()
            }
            .padding()
            .navigationTitle("Admin freischalten")
        }
    }
}

#Preview {
    NavigationView { AdminView() }
}
