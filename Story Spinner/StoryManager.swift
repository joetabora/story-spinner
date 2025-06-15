//
//  StoryManager.swift
//  Story Spinner
//
//  Created by Joseph Tabora on 6/14/25.
//

import Foundation
import SwiftUI

@MainActor
class StoryManager: ObservableObject {
    @Published var userPreferences = UserPreferences()
    @Published var currentStory: Story?
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var generationStatus = "Ready to create your story"
    @Published var error: String?
    
    private let apiService = APIService.shared
    
    // MARK: - Story Generation
    func generateStory() async {
        isGenerating = true
        generationProgress = 0.0
        error = nil
        currentStory = nil
        
        do {
            // Step 1: Generate story text
            generationStatus = "Writing your adventure..."
            generationProgress = 0.1
            
            let storyText = try await apiService.generateStory(preferences: userPreferences)
            let pages = parseStoryIntoPages(storyText)
            
            generationProgress = 0.3
            generationStatus = "Story written! Creating illustrations..."
            
            // Step 2: Generate images for each page
            var storyPages: [StoryPage] = []
            let totalPages = pages.count
            
            for (index, pageText) in pages.enumerated() {
                let pageNumber = index + 1
                generationStatus = "Creating illustration \(pageNumber) of \(totalPages)..."
                generationProgress = 0.3 + (Double(index) / Double(totalPages)) * 0.6
                
                var imageData: Data?
                var imageURL: String?
                
                // Try to generate image with multiple fallback options
                do {
                    let imagePrompt = createImagePrompt(for: pageText, pageNumber: pageNumber)
                    imageURL = try await apiService.generateImage(prompt: imagePrompt, preferences: userPreferences)
                    imageData = try await apiService.downloadImageData(from: imageURL!)
                    print("Successfully generated image for page \(pageNumber)")
                } catch {
                    print("Primary image generation failed for page \(pageNumber): \(error)")
                    
                    // Fallback 1: Try alternative image generation
                    do {
                        imageURL = try await apiService.generateImageAlternative(prompt: createImagePrompt(for: pageText, pageNumber: pageNumber), preferences: userPreferences)
                        imageData = try await apiService.downloadImageData(from: imageURL!)
                        print("Alternative image generation succeeded for page \(pageNumber)")
                    } catch {
                        print("Alternative image generation failed for page \(pageNumber): \(error)")
                        
                        // Fallback 2: Generate placeholder image
                        imageData = apiService.generatePlaceholderImage(for: pageText, preferences: userPreferences)
                        imageURL = nil
                        print("Using placeholder image for page \(pageNumber)")
                    }
                }
                
                let storyPage = StoryPage(
                    pageNumber: pageNumber,
                    text: pageText,
                    imageURL: imageURL,
                    imageData: imageData
                )
                storyPages.append(storyPage)
                
                // Small delay to prevent API rate limiting
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Step 3: Create final story
            generationStatus = "Finalizing your story..."
            generationProgress = 0.95
            
            let story = Story(
                title: generateStoryTitle(),
                pages: storyPages,
                createdAt: Date(),
                userPreferences: userPreferences
            )
            
            currentStory = story
            generationStatus = "Your story is ready!"
            generationProgress = 1.0
            
            // Small delay to show completion
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
        } catch {
            self.error = "Failed to create your story: \(error.localizedDescription)"
            generationStatus = "Story creation failed"
            print("Story generation error: \(error)")
        }
        
        isGenerating = false
    }
    
    // MARK: - Private Helper Methods
    private func parseStoryIntoPages(_ storyText: String) -> [String] {
        var pages = storyText.components(separatedBy: "[PAGE BREAK]")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Ensure we have 5 pages
        if pages.count > 5 {
            pages = Array(pages[0..<5])
        } else if pages.count < 5 {
            // If we have fewer pages, try to split longer ones or add content
            while pages.count < 5 && !pages.isEmpty {
                if let longestPageIndex = findLongestPageIndex(pages) {
                    let splitPages = splitPage(pages[longestPageIndex])
                    if splitPages.count > 1 {
                        pages.remove(at: longestPageIndex)
                        pages.insert(contentsOf: splitPages, at: longestPageIndex)
                    } else {
                        // Add a simple continuation page
                        pages.append("The adventure continues with \(getCharacterName())...")
                    }
                } else {
                    break
                }
            }
            
            // If still less than 5, add simple pages
            while pages.count < 5 {
                pages.append("And so \(getCharacterName())'s amazing adventure continued...")
            }
        }
        
        return Array(pages.prefix(5))
    }
    
    private func findLongestPageIndex(_ pages: [String]) -> Int? {
        guard !pages.isEmpty else { return nil }
        
        var longestIndex = 0
        var longestLength = pages[0].count
        
        for (index, page) in pages.enumerated() {
            if page.count > longestLength && page.count > 200 { // Only split if page is long enough
                longestLength = page.count
                longestIndex = index
            }
        }
        
        return longestLength > 200 ? longestIndex : nil
    }
    
    private func splitPage(_ pageText: String) -> [String] {
        let sentences = pageText.components(separatedBy: ". ")
        if sentences.count >= 4 {
            let midpoint = sentences.count / 2
            let firstHalf = sentences[0..<midpoint].joined(separator: ". ") + "."
            let secondHalf = sentences[midpoint...].joined(separator: ". ")
            return [firstHalf, secondHalf]
        }
        return [pageText]
    }
    
    private func getCharacterName() -> String {
        return userPreferences.nickname.isEmpty ? userPreferences.childName : userPreferences.nickname
    }
    
    private func createImagePrompt(for pageText: String, pageNumber: Int) -> String {
        let name = getCharacterName()
        
        // Extract key visual elements from the page text
        let visualKeywords = extractVisualKeywords(from: pageText)
        
        return """
        Page \(pageNumber) of children's book featuring \(name).
        Scene description: \(pageText.prefix(100))...
        Visual focus: \(visualKeywords)
        Character: \(name) as the main character in this scene.
        Style: Consistent character appearance across all illustrations.
        """
    }
    
    private func extractVisualKeywords(from text: String) -> String {
        let commonVisualWords = [
            "forest", "castle", "dragon", "magic", "sword", "treasure", "mountain", "river",
            "cave", "bridge", "tower", "garden", "door", "window", "stairs", "path",
            "light", "dark", "bright", "colorful", "mysterious", "glowing", "sparkling"
        ]
        
        let words = text.lowercased().components(separatedBy: .whitespacesAndPunctuationCharacters)
        let foundKeywords = words.filter { commonVisualWords.contains($0) }
        
        return foundKeywords.isEmpty ? "adventure scene" : foundKeywords.prefix(3).joined(separator: ", ")
    }
    
    private func generateStoryTitle() -> String {
        let name = getCharacterName()
        let genreAdj = getGenreAdjective()
        let seasonAdj = getSeasonAdjective()
        
        let titleTemplates = [
            "\(name)'s \(genreAdj) Adventure",
            "The \(genreAdj) Quest of \(name)",
            "\(name) and the \(seasonAdj) \(genreAdj) Mystery",
            "\(name)'s \(seasonAdj) Journey"
        ]
        
        return titleTemplates.randomElement() ?? "\(name)'s Amazing Adventure"
    }
    
    private func getGenreAdjective() -> String {
        switch userPreferences.genre {
        case .sciFi:
            return "Space"
        case .fantasy:
            return "Magical"
        case .sports:
            return "Championship"
        case .fiction:
            return "Amazing"
        case .drama:
            return "Heartwarming"
        case .suspense:
            return "Mysterious"
        case .kidFriendlyHorror:
            return "Spooky"
        }
    }
    
    private func getSeasonAdjective() -> String {
        switch userPreferences.favoriteSeason {
        case .spring:
            return "Blooming"
        case .summer:
            return "Sunny"
        case .fall:
            return "Golden"
        case .winter:
            return "Snowy"
        }
    }
    
    // MARK: - Validation
    func validatePreferences() -> Bool {
        return !userPreferences.childName.trimmingCharacters(in: .whitespaces).isEmpty &&
               !userPreferences.childAge.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func getValidationMessage() -> String? {
        if userPreferences.childName.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Please enter your child's name"
        }
        if userPreferences.childAge.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Please enter your child's age"
        }
        return nil
    }
    
    // MARK: - Reset Function
    func resetStory() {
        currentStory = nil
        isGenerating = false
        generationProgress = 0.0
        generationStatus = "Ready to create your story"
        error = nil
    }
}
