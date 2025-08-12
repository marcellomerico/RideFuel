import Foundation

// MARK: - API Modelle
struct APINutrition: Codable {
    let kcal: Int?
    let protein: Double?
    let fat: Double?
    let carbs: Double?
}

struct APIRezept: Codable {
    let id: String
    let title: String
    let nutrition: APINutrition?
    let image_urls: [String]?
    let ingredients: [APIIngredient]?
    let instructions: String?
}

struct APIIngredient: Codable {
    let quantity: Double?
    let unit: String?
    let description: String
}

struct APIRezeptDetail: Codable {
    let id: String
    let title: String
    let image_url: String?
    let source_url: String?
    let ingredients: [APIIngredient]
}

// MARK: - Rezept API Service
final class RezeptAPIService {
    @MainActor static let shared = RezeptAPIService()
    private init() {}
    // RapidAPI Key (ersetzen durch deinen echten Key oder aus sicherem Speicher laden)
    private let rapidAPIKey: String = "121d386466msh5156f163bd88aeap1b5974jsn71160b5f25dd"

    func fetchRezepte(suchbegriff: String) async -> [APIRezept] {
        let term = suchbegriff.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return [] }
        
        // Use German API since we have a valid key
        if let germanResults = await fetchFromGermanAPI(term: term), !germanResults.isEmpty {
            return germanResults
        }
        
        // Fallback to Forkify API if German API fails
        return await fetchFromForkifyAPI(term: term)
    }
    
    private func fetchFromGermanAPI(term: String) async -> [APIRezept]? {
        let deutscherSuchbegriff = enhanceGermanSearchTerm(term)
        
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "gustar-io-deutsche-rezepte.p.rapidapi.com"
        comps.path = "/search_api"
        comps.queryItems = [
            URLQueryItem(name: "text", value: deutscherSuchbegriff),
            URLQueryItem(name: "page", value: "0")
        ]
        guard let url = comps.url else { return nil }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("gustar-io-deutsche-rezepte.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        req.setValue(rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            

            // 1) Versuche: reine Array-Antwort
            if let arr = try? JSONDecoder().decode([GustarRecipe].self, from: data) {
                return arr.map { gr in
                    let images = (gr.image_urls?.isEmpty == false) ? gr.image_urls : nil
                    let stableId = gr.id ?? (gr.title + (images?.first ?? ""))
                    
                    // Map German ingredients to our APIIngredient format
                    let apiIngredients = gr.ingredients?.map { gustarIng in
                        
                        // Better quantity processing - handle different formats
                        var finalQuantity: Double? = gustarIng.quantity
                        var finalUnit: String? = gustarIng.unit
                        var finalDescription = gustarIng.name
                        
                        // Enhanced quantity processing from amount string
                        if let amountString = gustarIng.amount, !amountString.isEmpty {
                            if gustarIng.quantity == nil && gustarIng.unit == nil {
                                // Try to parse the amount string first
                                let cleanAmount = amountString.replacingOccurrences(of: ",", with: ".")
                                let scanner = Scanner(string: cleanAmount)
                                if let parsedQuantity = scanner.scanDouble() {
                                    finalQuantity = parsedQuantity
                                    let remaining = String(cleanAmount.dropFirst(scanner.currentIndex.utf16Offset(in: cleanAmount))).trimmingCharacters(in: .whitespaces)
                                    finalUnit = remaining.isEmpty ? nil : remaining
                                } else {
                                    // If parsing fails, use the amount string as-is in description
                                    finalDescription = "\(amountString) \(gustarIng.name)"
                                }
                            } else if gustarIng.quantity == nil {
                                // Better parsing for German quantities like "200g", "2 EL", "1,5 kg"
                                let cleanAmount = amountString.replacingOccurrences(of: ",", with: ".")
                                let scanner = Scanner(string: cleanAmount)
                                if let parsedQuantity = scanner.scanDouble() {
                                    finalQuantity = parsedQuantity
                                    let remaining = String(cleanAmount.dropFirst(scanner.currentIndex.utf16Offset(in: cleanAmount))).trimmingCharacters(in: .whitespaces)
                                    if !remaining.isEmpty {
                                        finalUnit = remaining
                                    }
                                }
                            }
                        }
                        
                        
                        return APIIngredient(
                            quantity: finalQuantity,
                            unit: finalUnit,
                            description: finalDescription
                        )
                    }
                    
                    // Enhanced nutrition data from German API
                    let nutrition = gr.nutrition != nil ? APINutrition(
                        kcal: gr.nutrition?.kcal,
                        protein: gr.nutrition?.protein,
                        fat: gr.nutrition?.fat,
                        carbs: gr.nutrition?.carbs
                    ) : nil
                    
                    return APIRezept(
                        id: stableId,
                        title: gr.title,
                        nutrition: nutrition,
                        image_urls: images,
                        ingredients: apiIngredients,
                        instructions: gr.instructions ?? gr.description
                    )
                }
            }

            // 2) Fallback: Objekt mit results-Feld
            if let list = try? JSONDecoder().decode(GustarListResponse.self, from: data), let arr = list.results {
                return arr.map { gr in
                    let images = (gr.image_urls?.isEmpty == false) ? gr.image_urls : nil
                    let stableId = gr.id ?? (gr.title + (images?.first ?? ""))
                    
                    // Map German ingredients to our APIIngredient format  
                    let apiIngredients = gr.ingredients?.map { gustarIng in
                        print("🔍 Raw German ingredient (results): \(gustarIng.name)")
                        print("   Raw amount: \(gustarIng.amount ?? "nil")")
                        print("   Raw quantity: \(gustarIng.quantity?.description ?? "nil")")
                        print("   Raw unit: \(gustarIng.unit ?? "nil")")
                        
                        // Better quantity processing - handle different formats
                        var finalQuantity: Double? = gustarIng.quantity
                        var finalUnit: String? = gustarIng.unit
                        var finalDescription = gustarIng.name
                        
                        // Enhanced quantity processing from amount string
                        if let amountString = gustarIng.amount, !amountString.isEmpty {
                            if gustarIng.quantity == nil && gustarIng.unit == nil {
                                // Try to parse the amount string first
                                let cleanAmount = amountString.replacingOccurrences(of: ",", with: ".")
                                let scanner = Scanner(string: cleanAmount)
                                if let parsedQuantity = scanner.scanDouble() {
                                    finalQuantity = parsedQuantity
                                    let remaining = String(cleanAmount.dropFirst(scanner.currentIndex.utf16Offset(in: cleanAmount))).trimmingCharacters(in: .whitespaces)
                                    finalUnit = remaining.isEmpty ? nil : remaining
                                } else {
                                    // If parsing fails, use the amount string as-is in description
                                    finalDescription = "\(amountString) \(gustarIng.name)"
                                }
                            } else if gustarIng.quantity == nil {
                                // Better parsing for German quantities like "200g", "2 EL", "1,5 kg"
                                let cleanAmount = amountString.replacingOccurrences(of: ",", with: ".")
                                let scanner = Scanner(string: cleanAmount)
                                if let parsedQuantity = scanner.scanDouble() {
                                    finalQuantity = parsedQuantity
                                    let remaining = String(cleanAmount.dropFirst(scanner.currentIndex.utf16Offset(in: cleanAmount))).trimmingCharacters(in: .whitespaces)
                                    if !remaining.isEmpty {
                                        finalUnit = remaining
                                    }
                                }
                            }
                        }
                        
                        
                        return APIIngredient(
                            quantity: finalQuantity,
                            unit: finalUnit,
                            description: finalDescription
                        )
                    }
                    
                    // Enhanced nutrition data from German API
                    let nutrition = gr.nutrition != nil ? APINutrition(
                        kcal: gr.nutrition?.kcal,
                        protein: gr.nutrition?.protein,
                        fat: gr.nutrition?.fat,
                        carbs: gr.nutrition?.carbs
                    ) : nil
                    
                    return APIRezept(
                        id: stableId,
                        title: gr.title,
                        nutrition: nutrition,
                        image_urls: images,
                        ingredients: apiIngredients,
                        instructions: gr.instructions ?? gr.description
                    )
                }
            }

            return nil
        } catch {
            return nil
        }
    }
    
    private func fetchFromForkifyAPI(term: String) async -> [APIRezept] {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://forkify-api.herokuapp.com/api/v2/recipes?search=\(encoded)") else {
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return []
            }
            let decoded = try JSONDecoder().decode(ForkifyResponse.self, from: data)
            return decoded.data.recipes.map { item in
                APIRezept(
                    id: item.id,
                    title: item.title,
                    nutrition: nil, // Forkify doesn't provide nutrition directly
                    image_urls: item.image_url != nil ? [item.image_url!] : nil,
                    ingredients: nil, // Will be fetched separately for Forkify
                    instructions: nil
                )
            }
        } catch {
            return []
        }
    }

    func fetchRezeptDetail(id: String) async -> APIRezeptDetail? {
        guard let url = URL(string: "https://forkify-api.herokuapp.com/api/v2/recipes/\(id)") else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            let decoded = try JSONDecoder().decode(ForkifyDetailResponse.self, from: data)
            let r = decoded.data.recipe
            let ingredients = r.ingredients.map { APIIngredient(quantity: $0.quantity, unit: $0.unit, description: $0.description) }
            return APIRezeptDetail(id: r.id, title: r.title, image_url: r.image_url, source_url: r.source_url, ingredients: ingredients)
        } catch {
            return nil
        }
    }
    
    // MARK: - German Search Enhancement
    private func enhanceGermanSearchTerm(_ term: String) -> String {
        let lowercased = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only enhance English terms - if it's already German, leave it alone
        let germanWords = ["schnitzel", "sauerbraten", "bratwurst", "spätzle", "gulasch", "sauerkraut", 
                          "kartoffelpuffer", "currywurst", "knödel", "maultaschen", "kassler", "eisbein",
                          "frikadellen", "lebkuchen", "stollen", "apfelstrudel", "schwarzwälder", 
                          "königsberger", "rheinischer", "thüringer", "weißwurst", "himmel", "döppekuchen",
                          "nudel", "nudeln", "hafer", "haferflocken", "brot", "brötchen", "kuchen", "torte",
                          "fleisch", "rindfleisch", "schweinefleisch", "hähnchen", "fisch", "lachs", 
                          "kartoffel", "kartoffeln", "gemüse", "salat", "suppe", "eintopf", "auflauf",
                          "käse", "quark", "joghurt", "milch", "butter", "ei", "eier", "reis", "pasta",
                          "zwiebel", "zwiebeln", "knoblauch", "tomate", "tomaten", "gurke", "möhre", "möhren"]
        
        // If term contains German words, return as-is
        for germanWord in germanWords {
            if lowercased.contains(germanWord) {
                return term
            }
        }
        
        // Map only exact English terms to simple German equivalents
        let exactEnhancements: [String: String] = [
            "beef": "rindfleisch",
            "pork": "schweinefleisch", 
            "chicken": "hähnchen",
            "pasta": "nudeln",
            "soup": "suppe",
            "bread": "brot",
            "cake": "kuchen",
            "sausage": "wurst",
            "potato": "kartoffel",
            "cheese": "käse",
            "fish": "fisch",
            "meat": "fleisch",
            "vegetarian": "vegetarisch",
            "dessert": "nachtisch",
            "salad": "salat"
        ]
        
        // Only enhance exact matches of English terms
        if let enhancement = exactEnhancements[lowercased] {
            return enhancement
        }
        
        // Return original term if no enhancement needed
        return term
    }
}

// MARK: - Forkify DTOs (nur intern für Decoding)
private struct ForkifyResponse: Decodable {
    let data: DataContainer
}

private struct DataContainer: Decodable {
    let recipes: [RecipeItem]
}

private struct RecipeItem: Decodable {
    let id: String
    let title: String
    let image_url: String?
}

private struct ForkifyDetailResponse: Decodable {
    let data: DetailDataContainer
}

private struct DetailDataContainer: Decodable {
    let recipe: RecipeDetail
}

private struct RecipeDetail: Decodable {
    let id: String
    let title: String
    let source_url: String?
    let image_url: String?
    let ingredients: [RecipeIngredient]
}

private struct RecipeIngredient: Decodable {
    let quantity: Double?
    let unit: String?
    let description: String
}




// MARK: - Gustar (German) DTOs
private struct GustarListResponse: Decodable {
    let results: [GustarRecipe]?
}

private struct GustarRecipe: Decodable {
    let id: String?
    let title: String
    let image_urls: [String]?
    let nutrition: GustarNutrition?
    let ingredients: [GustarIngredient]?
    let instructions: String?
    let description: String?
}

private struct GustarNutrition: Decodable {
    let kcal: Int?
    let protein: Double?
    let fat: Double?
    let carbs: Double?
    let fiber: Double?
}

private struct GustarIngredient: Decodable {
    let name: String
    let amount: String?
    let unit: String?
    let quantity: Double?
}
