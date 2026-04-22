import Foundation
import SwiftUI
import UIKit

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var problem: ProblemType
    @Published var inputText: String = ""
    @Published var pendingAttachments: [Attachment] = []
    @Published private(set) var messages: [ChatMessage] = []
    @Published var isSending = false
    @Published var errorMessage: String?

    private let service: ClaudeService

    init(problem: ProblemType, service: ClaudeService = ClaudeService()) {
        self.problem = problem
        self.service = service
        messages.append(
            ChatMessage(
                role: .system,
                text: "Ask the Duck is ready. Snap a photo, record a short video of the equipment or water, or just tell me what you're seeing."
            )
        )
    }

    func attach(image: UIImage) {
        guard let data = MediaService.jpeg(from: image) else { return }
        pendingAttachments.append(Attachment(kind: .image, jpegData: data, localURL: nil))
    }

    func attach(videoAt url: URL) {
        Task {
            guard let thumb = await MediaService.thumbnail(for: url),
                  let data = MediaService.jpeg(from: thumb) else { return }
            await MainActor.run {
                self.pendingAttachments.append(Attachment(kind: .video, jpegData: data, localURL: url))
            }
        }
    }

    func removeAttachment(_ attachment: Attachment) {
        pendingAttachments.removeAll { $0.id == attachment.id }
    }

    func send() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !pendingAttachments.isEmpty else { return }

        let outgoing = ChatMessage(
            role: .technician,
            text: trimmed,
            attachments: pendingAttachments
        )
        messages.append(outgoing)
        inputText = ""
        pendingAttachments = []
        errorMessage = nil
        isSending = true
        defer { isSending = false }

        let history = messages.filter { $0.role != .system && $0.id != outgoing.id }
        do {
            let reply = try await service.ask(problem: problem, history: history, newMessage: outgoing)
            messages.append(ChatMessage(role: .duck, text: reply))
        } catch {
            errorMessage = error.localizedDescription
            messages.append(
                ChatMessage(
                    role: .system,
                    text: "Couldn't reach Ask the Duck: \(error.localizedDescription)"
                )
            )
        }
    }
}
