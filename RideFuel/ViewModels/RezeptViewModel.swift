//
//  RezeptViewModel.swift
//  RideFuel
//
//  Created by Marcello Merico on 06.08.25.
//
import CoreData
import SwiftUI

@MainActor
class RezeptViewModel: ObservableObject {
    @Published var rezepte: [APIRezept] = []
    
    func ladeRezepte(suchbegriff: String) {
        Task {
            rezepte = await RezeptAPIService.shared.fetchRezepte(suchbegriff: suchbegriff)
        }
    }
}
