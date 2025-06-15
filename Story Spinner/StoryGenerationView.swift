//
//  StoryGenerationView.swift
//  Story Spinner
//
//  Created by Joseph Tabora on 6/14/25.
//

import SwiftUI

struct StoryGenerationView: View {
    @ObservedObject var storyManager: StoryManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Animated Spider Icon
                Image(systemName: "network")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(storyManager.isGenerating ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: storyManager.isGenerating)
                
                Text("Creating Your Story")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(storyManager.generationStatus)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: storyManager.generationProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    Text("\(Int(storyManager.generationProgress * 100))% Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
                
                if let error = storyManager.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                if !storyManager.isGenerating && storyManager.currentStory == nil && storyManager.error == nil {
                    Button("Start Creating Story") {
                        Task {
                            await storyManager.generateStory()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                if storyManager.error != nil {
                    Button("Try Again") {
                        storyManager.error = nil
                        Task {
                            await storyManager.generateStory()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Story Spinner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if storyManager.currentStory == nil && storyManager.error == nil {
                Task {
                    await storyManager.generateStory()
                }
            }
        }
        .onChange(of: storyManager.currentStory) { story in
            if story != nil {
                // Story generation completed, the sheet will update to show StoryDisplayView
            }
        }
    }
}

#Preview {
    StoryGenerationView(storyManager: StoryManager())
}
