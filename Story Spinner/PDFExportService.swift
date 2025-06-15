//
//  PDFExportService.swift
//  Story Spinner
//
//  Created by Joseph Tabora on 6/14/25.
//


//
//  PDFExportService.swift
//  Story Spinner
//
//  Created by Joseph Tabora on 6/14/25.
//

import Foundation
import PDFKit
import UIKit

class PDFExportService {
    static let shared = PDFExportService()
    
    private init() {}
    
    func createPDF(from story: Story) -> URL? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // 8.5 x 11 inch
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsPath.appendingPathComponent("\(story.title).pdf")
        
        do {
            try pdfRenderer.writePDF(to: pdfURL) { context in
                // Title Page
                createTitlePage(context: context, story: story)
                
                // Story Pages
                for page in story.pages {
                    context.beginPage()
                    createStoryPage(context: context, page: page)
                }
            }
            return pdfURL
        } catch {
            print("Error creating PDF: \(error)")
            return nil
        }
    }
    
    private func createTitlePage(context: UIGraphicsPDFRendererContext, story: Story) {
        context.beginPage()
        
        let pageRect = context.pdfContextBounds
        let titleFont = UIFont.systemFont(ofSize: 36, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 18, weight: .medium)
        let detailFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        // Title
        let titleText = story.title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.systemBlue
        ]
        
        let titleSize = titleText.size(withAttributes: titleAttributes)
        let titleRect = CGRect(
            x: (pageRect.width - titleSize.width) / 2,
            y: 150,
            width: titleSize.width,
            height: titleSize.height
        )
        titleText.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Subtitle
        let subtitleText = "A personalized story"
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.gray
        ]
        
        let subtitleSize = subtitleText.size(withAttributes: subtitleAttributes)
        let subtitleRect = CGRect(
            x: (pageRect.width - subtitleSize.width) / 2,
            y: titleRect.maxY + 20,
            width: subtitleSize.width,
            height: subtitleSize.height
        )
        subtitleText.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        
        // Story details
        let name = story.userPreferences.nickname.isEmpty ? story.userPreferences.childName : story.userPreferences.nickname
        let detailsText = """
        Starring: \(name)
        Genre: \(story.userPreferences.genre.rawValue)
        Created: \(DateFormatter.shortDate.string(from: story.createdAt))
        """
        
        let detailsAttributes: [NSAttributedString.Key: Any] = [
            .font: detailFont,
            .foregroundColor: UIColor.label
        ]
        
        let detailsRect = CGRect(
            x: 100,
            y: pageRect.height - 200,
            width: pageRect.width - 200,
            height: 100
        )
        detailsText.draw(in: detailsRect, withAttributes: detailsAttributes)
    }
    
    private func createStoryPage(context: UIGraphicsPDFRendererContext, page: StoryPage) {
        let pageRect = context.pdfContextBounds
        let margin: CGFloat = 50
        let textFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        // Page number
        let pageNumberText = "Page \(page.pageNumber)"
        let pageNumberAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.gray
        ]
        
        let pageNumberRect = CGRect(
            x: pageRect.width - margin - 50,
            y: margin,
            width: 50,
            height: 20
        )
        pageNumberText.draw(in: pageNumberRect, withAttributes: pageNumberAttributes)
        
        // Image
        if let imageData = page.imageData,
           let image = UIImage(data: imageData) {
            let imageHeight: CGFloat = 300
            let imageWidth = pageRect.width - (margin * 2)
            let imageRect = CGRect(
                x: margin,
                y: margin + 40,
                width: imageWidth,
                height: imageHeight
            )
            image.draw(in: imageRect)
            
            // Text below image
            let textRect = CGRect(
                x: margin,
                y: imageRect.maxY + 30,
                width: pageRect.width - (margin * 2),
                height: pageRect.height - imageRect.maxY - 80
            )
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor.label
            ]
            
            page.text.draw(in: textRect, withAttributes: textAttributes)
        } else {
            // Text only
            let textRect = CGRect(
                x: margin,
                y: margin + 60,
                width: pageRect.width - (margin * 2),
                height: pageRect.height - 120
            )
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor.label
            ]
            
            page.text.draw(in: textRect, withAttributes: textAttributes)
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}