import Foundation

// MARK: - API Modelle
struct APINutrition: Codable {
    let kcal: Int?
}

struct APIRezept: Codable {
    let id: String
    let title: String
    let nutrition: APINutrition?
    let image_urls: [String]?
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

    // Beispiel-Endpoint (Forkify). Für echte Kalorienwerte müsste eine andere Quelle genutzt werden.
    func fetchRezepte(suchbegriff: String) async -> [APIRezept] {
        let trimmed = suchbegriff.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://forkify-api.herokuapp.com/api/v2/recipes?search=\(encoded)") else {
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return []
            }
            let decoded = try JSONDecoder().decode(ForkifyResponse.self, from: data)
            let mapped: [APIRezept] = decoded.data.recipes.map { item in
                APIRezept(
                    id: item.id,
                    title: item.title,
                    nutrition: nil,
                    image_urls: item.image_url != nil ? [item.image_url!].filter { !$0.isEmpty } : []
                )
            }
            return mapped
        } catch {
            // Optional: Fallback auf leeres Array, API-Änderungen craschen nicht die App
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


