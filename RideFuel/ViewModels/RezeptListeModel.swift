//
//  RezeptListeModel.swift
//  RideFuel
//
//  Created by Marcello Merico on 13.08.25.
//

import Foundation
import CoreData

final class RezeptListeModel: ObservableObject {
    @Published var suchbegriff: String = ""
    
    func gefiltert(_ rezepte: [Rezept]) -> [Rezept] {
        let term = suchbegriff.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else {
            return Array(rezepte)
        }
        return rezepte.filter { ($0.name ?? "").lowercased().contains(term)}
    }
}
