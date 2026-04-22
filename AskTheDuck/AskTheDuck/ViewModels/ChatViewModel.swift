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

    /// Customer whose pool we're at. Required before the first message.
    @Published var customer: CustomerInfo

    /// Submission state for escalations.
    @Published var isEscalating = false
    @Published var lastEscalatedTicket: EscalationTicket?
    @Published var escalationError: String?

    let technician: Technician

    private let service: ClaudeService
    private let tickets: TicketStoring

    init(
        problem: ProblemType,
        customer: CustomerInfo,
        technician: Technician,
        service: ClaudeService = ClaudeService(),
        tickets: TicketStoring = LocalTicketStore.shared
    ) {
        self.problem = problem
        self.customer = customer
        self.technician = technician
        self.service = service
        self.tickets = tickets
        messages.append(
            ChatMessage(
                role: .system,
                text: "Ask the Duck is ready for \(customer.name.isEmpty ? "the customer" : customer.name). Snap a photo, record a short video of the equipment or water, or just tell me what you're seeing."
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

    /// Package the full session (customer info, chat transcript, all photos/
    /// video stills) and send it to the back office for a scheduled repair.
    func escalate(summary: String, troubleshootingTaken: String) async {
        guard customer.isValid else {
            escalationError = "Add the customer name, address, and phone before escalating."
            return
        }
        escalationError = nil
        isEscalating = true
        defer { isEscalating = false }

        do {
            let ticket = try await tickets.submit(
                technician: technician,
                customer: customer,
                problem: problem,
                summary: summary,
                troubleshootingTaken: troubleshootingTaken,
                messages: messages
            )
            lastEscalatedTicket = ticket
            messages.append(
                ChatMessage(
                    role: .system,
                    text: "Escalated to the office. Ticket \(ticket.id.uuidString.prefix(8)) is now in the admin queue for scheduling."
                )
            )
        } catch {
            escalationError = error.localizedDescription
        }
    }
}
