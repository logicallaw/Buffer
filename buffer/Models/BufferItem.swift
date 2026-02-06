import Foundation
import SwiftData

enum BufferCategory: String, Codable, CaseIterable, Identifiable {
    case all
    case notes
    case links
    case files
    case images

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .notes: return "Notes"
        case .links: return "Links"
        case .files: return "Files"
        case .images: return "Images"
        }
    }

    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .notes: return "note.text"
        case .links: return "link"
        case .files: return "doc"
        case .images: return "photo"
        }
    }
}

@Model
final class BufferItem {
    var title: String
    var content: String
    var category: BufferCategory
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool

    // Link-specific
    var url: String?
    var linkTitle: String?
    var linkDescription: String?

    // File-specific
    var fileName: String?
    var fileSize: Int?
    var fileBookmark: Data?

    // Image-specific
    var imageData: Data?

    init(
        title: String = "",
        content: String = "",
        category: BufferCategory = .notes,
        isPinned: Bool = false
    ) {
        self.title = title
        self.content = content
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPinned = isPinned
    }
}
