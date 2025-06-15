//
//  APIService.swift
//  Story Spinner
//
//  Created by Joseph Tabora on 6/14/25.
//

import Foundation
import Alamofire

class APIService: ObservableObject {
    static let shared = APIService()
    
    // Replace with your actual OpenRouter API key
    private let apiKey = "<api-key>"
    private let baseURL = "https://openrouter.ai/api/v1"
    
    private init() {}
    
    // MARK: - Story Generation
    func generateStory(preferences: UserPreferences) async throws -> String {
        let prompt = createStoryPrompt(preferences: preferences)
        
        let request = OpenRouterRequest(
            model: "google/gemma-3-27b-it:free",
            messages: [
                Message(role: "system", content: "You are a creative children's story writer. Create engaging, age-appropriate stories with vivid descriptions. Always end each page with [PAGE BREAK] exactly as shown."),
                Message(role: "user", content: prompt)
            ],
            maxTokens: 2000
        )
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://your-app-name.com",
            "X-Title": "Story Spinner"
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request("\(baseURL)/chat/completions",
                      method: .post,
                      parameters: request,
                      encoder: JSONParameterEncoder.default,
                      headers: headers)
                .validate()
                .responseDecodable(of: OpenRouterResponse.self) { response in
                    switch response.result {
                    case .success(let openRouterResponse):
                        if let content = openRouterResponse.choices.first?.message.content {
                            continuation.resume(returning: content)
                        } else {
                            continuation.resume(throwing: APIError.noContent)
                        }
                    case .failure(let error):
                        print("Story generation error: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    // MARK: - Image Generation
    func generateImage(prompt: String, preferences: UserPreferences) async throws -> String {
        let enhancedPrompt = enhanceImagePrompt(prompt: prompt, preferences: preferences)
        
        // Using a different model that works with OpenRouter for image generation
        let request = ImageGenerationRequest(
            model: "black-forest-labs/flux-1.1-pro",
            prompt: enhancedPrompt,
            size: "1024x1024",
            quality: "standard",
            n: 1
        )
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://your-app-name.com",
            "X-Title": "Story Spinner"
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request("\(baseURL)/images/generations",
                      method: .post,
                      parameters: request,
                      encoder: JSONParameterEncoder.default,
                      headers: headers)
                .validate()
                .responseDecodable(of: ImageGenerationResponse.self) { response in
                    switch response.result {
                    case .success(let imageResponse):
                        if let imageURL = imageResponse.data.first?.url {
                            continuation.resume(returning: imageURL)
                        } else {
                            continuation.resume(throwing: APIError.noImageURL)
                        }
                    case .failure(let error):
                        print("Image generation error: \(error)")
                        // Try alternative approach or return placeholder
                        continuation.resume(throwing: APIError.imageGenerationFailed(error.localizedDescription))
                    }
                }
        }
    }
    
    // Alternative image generation method using different service
    func generateImageAlternative(prompt: String, preferences: UserPreferences) async throws -> String {
        // This is a fallback method that could use a different service
        // For now, we'll simulate image generation with a placeholder
        let enhancedPrompt = enhanceImagePrompt(prompt: prompt, preferences: preferences)
        
        // You could implement Stable Diffusion or other image generation APIs here
        // For demo purposes, returning a placeholder URL
        throw APIError.imageGenerationNotAvailable
    }
    
    // MARK: - Download Image Data
    func downloadImageData(from url: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            AF.download(url)
                .validate()
                .response { response in
                    switch response.result {
                    case .success(let fileURL):
                        if let fileURL = fileURL {
                            do {
                                let data = try Data(contentsOf: fileURL)
                                continuation.resume(returning: data)
                            } catch {
                                continuation.resume(throwing: APIError.downloadFailed)
                            }
                        } else {
                            continuation.resume(throwing: APIError.downloadFailed)
                        }
                    case .failure(let error):
                        print("Image download error: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    // MARK: - Placeholder Image Generation
    func generatePlaceholderImage(for pageText: String, preferences: UserPreferences) -> Data? {
        // Generate a simple placeholder image with text
        let size = CGSize(width: 1024, height: 1024)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Background gradient
            let colors = getColorsForSeason(preferences.favoriteSeason)
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [colors.0.cgColor, colors.1.cgColor] as CFArray,
                                    locations: [0.0, 1.0])!
            
            context.cgContext.drawLinearGradient(gradient,
                                               start: CGPoint(x: 0, y: 0),
                                               end: CGPoint(x: size.width, y: size.height),
                                               options: [])
            
            // Add some decorative elements based on genre
            drawGenreElements(context: context.cgContext, size: size, genre: preferences.genre)
            
            // Add text overlay
            let name = preferences.nickname.isEmpty ? preferences.childName : preferences.nickname
            let text = "\(name)'s Adventure"
            let font = UIFont.boldSystemFont(ofSize: 48)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -2
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        return image.pngData()
    }
    
    // MARK: - Private Helper Methods
    private func createStoryPrompt(preferences: UserPreferences) -> String {
        let name = preferences.nickname.isEmpty ? preferences.childName : preferences.nickname
        
        return """
        Create a captivating children's story with the following specifications:
        
        - Main character name: \(name)
        - Character age: \(preferences.childAge)
        - Gender: \(preferences.gender.rawValue)
        - Genre: \(preferences.genre.rawValue)
        - Setting season: \(preferences.favoriteSeason.rawValue)
        - Video game reference: \(preferences.favoriteVideoGame)
        - Fashion style: \(preferences.fashionStyle.rawValue)
        
        Requirements:
        - Write exactly 5 pages of story content (not 10)
        - Each page should be 4-6 sentences long
        - Include unique supporting character names
        - Make it suspenseful and engaging
        - Age-appropriate content for a \(preferences.childAge) year old
        - Include vivid visual descriptions for illustration
        - End each page with exactly "[PAGE BREAK]" on a new line
        - Make \(name) the hero of the adventure
        - Incorporate elements from \(preferences.favoriteVideoGame) naturally into the story
        
        The story should be original and exciting, perfect for a young reader who loves \(preferences.genre.rawValue) adventures!
        """
    }
    
    private func enhanceImagePrompt(prompt: String, preferences: UserPreferences) -> String {
        let name = preferences.nickname.isEmpty ? preferences.childName : preferences.nickname
        let age = preferences.childAge
        
        return """
        Children's book illustration, high quality digital art. 
        Scene: \(prompt)
        Main character: \(name), age \(age), \(preferences.gender.rawValue.lowercased()), wearing \(preferences.fashionStyle.rawValue.lowercased()) style clothing.
        Setting: \(preferences.favoriteSeason.rawValue) atmosphere and mood.
        Style: Warm, colorful, friendly cartoon illustration suitable for children's books.
        Elements: Include subtle references to \(preferences.favoriteVideoGame) in the background or details.
        Quality: Professional children's book illustration, vibrant colors, engaging composition.
        Avoid: Dark themes, scary elements, inappropriate content.
        """
    }
    
    private func getColorsForSeason(_ season: Season) -> (UIColor, UIColor) {
        switch season {
        case .spring:
            return (UIColor.systemGreen.withAlphaComponent(0.7), UIColor.systemYellow.withAlphaComponent(0.5))
        case .summer:
            return (UIColor.systemBlue.withAlphaComponent(0.7), UIColor.systemYellow.withAlphaComponent(0.8))
        case .fall:
            return (UIColor.systemOrange.withAlphaComponent(0.7), UIColor.systemRed.withAlphaComponent(0.5))
        case .winter:
            return (UIColor.systemBlue.withAlphaComponent(0.5), UIColor.white.withAlphaComponent(0.8))
        }
    }
    
    private func drawGenreElements(context: CGContext, size: CGSize, genre: Genre) {
        context.saveGState()
        
        switch genre {
        case .fantasy:
            // Draw stars
            for _ in 0..<20 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                drawStar(context: context, center: CGPoint(x: x, y: y), radius: CGFloat.random(in: 8...16))
            }
        case .sciFi:
            // Draw geometric shapes
            context.setFillColor(UIColor.cyan.withAlphaComponent(0.3).cgColor)
            for _ in 0..<10 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let rect = CGRect(x: x, y: y, width: 30, height: 30)
                context.fillEllipse(in: rect)
            }
        default:
            break
        }
        
        context.restoreGState()
    }
    
    private func drawStar(context: CGContext, center: CGPoint, radius: CGFloat) {
        let points = 5
        let innerRadius = radius * 0.4
        
        context.saveGState()
        context.setFillColor(UIColor.yellow.withAlphaComponent(0.6).cgColor)
        context.move(to: CGPoint(x: center.x, y: center.y - radius))
        
        for i in 1..<points * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(points)
            let currentRadius = i % 2 == 0 ? radius : innerRadius
            let x = center.x + currentRadius * sin(angle)
            let y = center.y - currentRadius * cos(angle)
            context.addLine(to: CGPoint(x: x, y: y))
        }
        
        context.closePath()
        context.fillPath()
        context.restoreGState()
    }
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case noContent
    case noImageURL
    case downloadFailed
    case invalidResponse
    case imageGenerationFailed(String)
    case imageGenerationNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .noContent:
            return "No story content received"
        case .noImageURL:
            return "No image URL received"
        case .downloadFailed:
            return "Failed to download image"
        case .invalidResponse:
            return "Invalid API response"
        case .imageGenerationFailed(let message):
            return "Image generation failed: \(message)"
        case .imageGenerationNotAvailable:
            return "Image generation service is not available"
        }
    }
}
