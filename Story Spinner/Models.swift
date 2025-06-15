//
//  Models.swift
//  Story Spinner
//
//  Created by Joseph Tabora on 6/14/25.
//

import Foundation
import SwiftUI

// MARK: - User Preferences Model
struct UserPreferences: Equatable {
    var childName: String = ""
    var childAge: String = ""
    var nickname: String = ""
    var gender: Gender = .other
    var genre: Genre = .fantasy
    var favoriteSeason: Season = .spring
    var favoriteVideoGame: String = ""
    var fashionStyle: FashionStyle = .casual
}

// MARK: - Enums
enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

enum Genre: String, CaseIterable {
    case sciFi = "Sci-fi"
    case fantasy = "Fantasy"
    case sports = "Sports"
    case fiction = "Fiction"
    case drama = "Drama"
    case suspense = "Suspense"
    case kidFriendlyHorror = "Scary / Kid Friendly Horror"
}

enum Season: String, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
}

enum FashionStyle: String, CaseIterable {
    case casual = "Casual"
    case sporty = "Sporty"
    case elegant = "Elegant"
    case trendy = "Trendy"
    case vintage = "Vintage"
    case bohemian = "Bohemian"
}

// MARK: - Story Models
struct Story: Equatable {
    let id = UUID()
    let title: String
    let pages: [StoryPage]
    let createdAt: Date
    let userPreferences: UserPreferences
    
    static func == (lhs: Story, rhs: Story) -> Bool {
        return lhs.id == rhs.id
    }
}

struct StoryPage: Equatable {
    let id = UUID()
    let pageNumber: Int
    let text: String
    let imageURL: String?
    let imageData: Data?
    
    static func == (lhs: StoryPage, rhs: StoryPage) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - API Models
struct OpenRouterRequest: Codable {
    let model: String
    let messages: [Message]
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxTokens = "max_tokens"
    }
}

struct Message: Codable {
    let role: String
    let content: String
}

struct OpenRouterResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct ImageGenerationRequest: Codable {
    let model: String
    let prompt: String
    let size: String
    let quality: String
    let n: Int
}

struct ImageGenerationResponse: Codable {
    let data: [ImageData]
}

struct ImageData: Codable {
    let url: String
}
