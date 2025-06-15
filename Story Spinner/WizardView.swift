//
//  WizardView.swift
//  Story Spinner
//
//  Created by Joseph Tabora on 6/14/25.
//

import SwiftUI

struct WizardView: View {
    @StateObject private var storyManager = StoryManager()
    @State private var currentStep = 0
    @State private var showingStoryView = false
    
    private let totalSteps = 6
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress Bar
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                
                // Step Indicator
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Content
                TabView(selection: $currentStep) {
                    BasicInfoView(preferences: $storyManager.userPreferences)
                        .tag(0)
                    
                    GenreSelectionView(preferences: $storyManager.userPreferences)
                        .tag(1)
                    
                    SeasonSelectionView(preferences: $storyManager.userPreferences)
                        .tag(2)
                    
                    VideoGameView(preferences: $storyManager.userPreferences)
                        .tag(3)
                    
                    FashionStyleView(preferences: $storyManager.userPreferences)
                        .tag(4)
                    
                    ConfirmationView(preferences: $storyManager.userPreferences)
                        .tag(5)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation Buttons
                HStack {
                    Button("Previous") {
                        withAnimation {
                            currentStep = max(0, currentStep - 1)
                        }
                    }
                    .disabled(currentStep == 0)
                    
                    Spacer()
                    
                    if currentStep < totalSteps - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep = min(totalSteps - 1, currentStep + 1)
                            }
                        }
                        .disabled(!canProceedFromCurrentStep())
                    } else {
                        Button("Create Story") {
                            createStory()
                        }
                        .disabled(!storyManager.validatePreferences())
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("Story Spinner")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingStoryView) {
            if let story = storyManager.currentStory {
                StoryDisplayView(story: story)
            } else {
                StoryGenerationView(storyManager: storyManager)
            }
        }
    }
    
    private func canProceedFromCurrentStep() -> Bool {
        switch currentStep {
        case 0:
            return !storyManager.userPreferences.childName.trimmingCharacters(in: .whitespaces).isEmpty
        default:
            return true
        }
    }
    
    private func createStory() {
        showingStoryView = true
    }
}

// MARK: - Individual Step Views

struct BasicInfoView: View {
    @Binding var preferences: UserPreferences
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Let's get to know your child")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading) {
                    Text("Child's Name *")
                        .font(.headline)
                    TextField("Enter child's name", text: $preferences.childName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading) {
                        Text("Child's Age *")
                            .font(.headline)
                        TextField("Enter child's age", text: $preferences.childAge)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Nickname (Optional)")
                            .font(.headline)
                        TextField("Enter nickname", text: $preferences.nickname)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Gender")
                            .font(.headline)
                        Picker("Gender", selection: $preferences.gender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct GenreSelectionView: View {
    @Binding var preferences: UserPreferences
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("Choose your adventure")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("What type of story would you like?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(Genre.allCases, id: \.self) { genre in
                    GenreCard(genre: genre, isSelected: preferences.genre == genre) {
                        preferences.genre = genre
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct GenreCard: View {
    let genre: Genre
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: genreIcon(for: genre))
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(genre.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func genreIcon(for genre: Genre) -> String {
        switch genre {
        case .sciFi: return "rocket.fill"
        case .fantasy: return "wand.and.stars"
        case .sports: return "sportscourt.fill"
        case .fiction: return "book.fill"
        case .drama: return "theatermasks.fill"
        case .suspense: return "magnifyingglass"
        case .kidFriendlyHorror: return "ghost.fill"
        }
    }
}

struct SeasonSelectionView: View {
    @Binding var preferences: UserPreferences
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Pick your favorite season")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This will set the mood for your story")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(Season.allCases, id: \.self) { season in
                    SeasonCard(season: season, isSelected: preferences.favoriteSeason == season) {
                        preferences.favoriteSeason = season
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct SeasonCard: View {
    let season: Season
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: seasonIcon(for: season))
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : seasonColor(for: season))
                
                Text(season.rawValue)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(isSelected ? seasonColor(for: season) : Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func seasonIcon(for season: Season) -> String {
        switch season {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .fall: return "leaf.arrow.circlepath"
        case .winter: return "snowflake"
        }
    }
    
    private func seasonColor(for season: Season) -> Color {
        switch season {
        case .spring: return .green
        case .summer: return .orange
        case .fall: return .brown
        case .winter: return .blue
        }
    }
}

struct VideoGameView: View {
    @Binding var preferences: UserPreferences
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Favorite Video Game")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("We'll weave elements from this game into your story")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("Enter your favorite video game", text: $preferences.favoriteVideoGame)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.title3)
            
            Text("Examples: Minecraft, Mario, Pokémon, Roblox")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct FashionStyleView: View {
    @Binding var preferences: UserPreferences
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tshirt.fill")
                .font(.system(size: 60))
                .foregroundColor(.pink)
            
            Text("Choose your style")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("How would you like your character to dress?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(FashionStyle.allCases, id: \.self) { style in
                    FashionStyleCard(style: style, isSelected: preferences.fashionStyle == style) {
                        preferences.fashionStyle = style
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct FashionStyleCard: View {
    let style: FashionStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: styleIcon(for: style))
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(style.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.pink : Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func styleIcon(for style: FashionStyle) -> String {
        switch style {
        case .casual: return "tshirt.fill"
        case .sporty: return "figure.run"
        case .elegant: return "suit.fill"
        case .trendy: return "sunglasses.fill"
        case .vintage: return "hat.widebrim.fill"
        case .bohemian: return "scarf.fill"
        }
    }
}

struct ConfirmationView: View {
    @Binding var preferences: UserPreferences
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Story Preview")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Here's what we'll create for you:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 15) {
                    ConfirmationRow(title: "Character Name", value: preferences.nickname.isEmpty ? preferences.childName : preferences.nickname)
                    ConfirmationRow(title: "Character Age", value: preferences.childAge)
                    ConfirmationRow(title: "Gender", value: preferences.gender.rawValue)
                    ConfirmationRow(title: "Story Genre", value: preferences.genre.rawValue)
                    ConfirmationRow(title: "Season Setting", value: preferences.favoriteSeason.rawValue)
                    if !preferences.favoriteVideoGame.isEmpty {
                        ConfirmationRow(title: "Video Game Element", value: preferences.favoriteVideoGame)
                    }
                    ConfirmationRow(title: "Fashion Style", value: preferences.fashionStyle.rawValue)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Text("Ready to create your personalized story with illustrations?")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
        }
    }
}

struct ConfirmationRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    WizardView()
}
