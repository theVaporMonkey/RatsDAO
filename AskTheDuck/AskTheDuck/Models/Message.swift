import Foundation
import UIKit

struct Attachment: Identifiable, Hashable {
    enum Kind: Hashable { case image, video }

    let id = UUID()
    let kind: Kind
    /// For images: encoded JPEG. For videos: a representative still frame we
    /// send to Claude, since the Messages API accepts images.
    let jpegData: Data
    /// Optional local file URL (kept for video playback previews).
    let localURL: URL?
}

struct ChatMessage: Identifiable, Hashable {
    enum Role: String, Hashable { case technician, duck, system }

    let id = UUID()
    let role: Role
    let text: String
    let attachments: [Attachment]
    let timestamp: Date

    init(role: Role, text: String, attachments: [Attachment] = [], timestamp: Date = Date()) {
        self.role = role
        self.text = text
        self.attachments = attachments
        self.timestamp = timestamp
    }
}

struct Technician: Codable, Hashable {
    enum Role: String, Codable, Hashable { case technician, admin }

    let id: String
    let name: String
    let role: Role
    let franchiseLocation: String
    let email: String
}
