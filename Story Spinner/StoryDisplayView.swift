//
//  StoryDisplayView.swift
//  Story Spinner
//
//  Created by Joseph Tabora on 6/14/25.
//

import SwiftUI

struct StoryDisplayView: View {
    let story: Story
    @State private var currentPageIndex = 0
    @State private var showingPDFPreview = false
    @State private var pdfURL: URL?
    @State private var isExporting = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Title
                Text(story.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Page indicator
                Text("Page \(currentPageIndex + 1) of \(story.pages.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Story content
                TabView(selection: $currentPageIndex) {
                    ForEach(Array(story.pages.enumerated()), id: \.element.id) { index, page in
                        StoryPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                // Navigation buttons
                HStack {
                    Button("Previous") {
                        withAnimation {
                            currentPageIndex = max(0, currentPageIndex - 1)
                        }
                    }
                    .disabled(currentPageIndex == 0)
                    
                    Spacer()
                    
                    Button("Next") {
                        withAnimation {
                            currentPageIndex = min(story.pages.count - 1, currentPageIndex + 1)
                        }
                    }
                    .disabled(currentPageIndex == story.pages.count - 1)
                }
                .padding(.horizontal)
                
                // Export button
                Button(action: exportToPDF) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text("Export as PDF")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        exportToPDF()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfURL = pdfURL {
                PDFPreviewView(pdfURL: pdfURL)
            }
        }
    }
    
    private func exportToPDF() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let url = PDFExportService.shared.createPDF(from: story)
            
            DispatchQueue.main.async {
                isExporting = false
                pdfURL = url
                showingPDFPreview = true
            }
        }
    }
}

struct StoryPageView: View {
    let page: StoryPage
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image
                if let imageData = page.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                } else {
                    // Placeholder for missing image
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Image Loading...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }
                
                // Story text
                Text(page.text)
                    .font(.title3)
                    .lineSpacing(4)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding()
        }
    }
}

struct PDFPreviewView: View {
    let pdfURL: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            PDFViewRepresentable(url: pdfURL)
                .navigationTitle("Story Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(item: pdfURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

struct PDFViewRepresentable: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

// Import PDFKit at the top of the file
import PDFKit

#Preview {
    let samplePreferences = UserPreferences()
    let samplePages = [
        StoryPage(pageNumber: 1, text: "Once upon a time, in a magical forest, there lived a brave young adventurer named Alex.", imageURL: nil, imageData: nil),
        StoryPage(pageNumber: 2, text: "Alex discovered a mysterious glowing portal that would change everything.", imageURL: nil, imageData: nil)
    ]
    let sampleStory = Story(title: "Alex's Magical Adventure", pages: samplePages, createdAt: Date(), userPreferences: samplePreferences)
    
    return StoryDisplayView(story: sampleStory)
}
