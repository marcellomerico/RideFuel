//
//  RezeptListeView.swift
//  RideFuel
//
//  Created by Marcello Merico on 06.08.25.
//

import SwiftUI
import CoreData

struct RezeptListeScreen: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Rezept.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Rezept.name, ascending: true)]
    ) private var rezepte: FetchedResults<Rezept>
    
    @State private var suchbegriff = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Suchbegriff", text: $suchbegriff)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(gefilterteRezepte, id: \.self) { rezept in
                            NavigationLink {
                                RezeptDetailView(rezept: rezept)
                            } label: {
                                RezeptCard(rezept: rezept)
                                    .padding(.horizontal)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Rezepte")
        }
    }
    
    private var gefilterteRezepte: [Rezept] {
        let term = suchbegriff.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else { return Array(rezepte) }
        return rezepte.filter { ($0.name ?? "").lowercased().contains(term) }
    }
    
}

private struct RezeptCard: View {
    let rezept: Rezept

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let urlString = rezept.bildURL,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(12)
                    case .failure(_):
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
            }

            Text(rezept.name ?? "Unbekanntes Rezept")
                .font(.headline)

            Text("\(rezept.kcal) kcal – \(String(format: "%.1f", rezept.kohlenhydrate)) g Carbs")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
}

#Preview{
    RezeptListeScreen()
}
