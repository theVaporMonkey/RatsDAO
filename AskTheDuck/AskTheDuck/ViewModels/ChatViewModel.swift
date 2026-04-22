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

    /// Quote generation state.
    @Published var isGeneratingQuote = false
    @Published var generatedQuote: Quote?
    @Published var quoteError: String?

    /// When the tech flags that cellular signal is weak, we stop nudging
    /// video captures and pause background attachment uploads.
    @Published var signalLimited: Bool = false

    let technician: Technician

    /// Stable ID for this session's service record. Used for upserts into
    /// the history store — every message tick, every attachment.
    private let serviceRecordID: UUID
    private var currentRecord: ServiceRecord

    private let service: ClaudeService
    private let tickets: TicketStoring
    private let history: HistoryStoring
    private let quotes: QuoteStoring
    private let quoteService: QuoteService

    init(
        problem: ProblemType,
        customer: CustomerInfo,
        technician: Technician,
        service: ClaudeService = ClaudeService(),
        tickets: TicketStoring = LocalTicketStore.shared,
        history: HistoryStoring = LocalHistoryStore.shared,
        quotes: QuoteStoring = LocalQuoteStore.shared,
        quoteService: QuoteService = QuoteService()
    ) {
        self.problem = problem
        self.customer = customer
        self.technician = technician
        self.service = service
        self.tickets = tickets
        self.history = history
        self.quotes = quotes
        self.quoteService = quoteService

        let recordID = UUID()
        self.serviceRecordID = recordID
        self.currentRecord = ServiceRecord(
            id: recordID,
            technicianId: technician.id,
            technicianName: technician.name,
            technicianEmail: technician.email,
            customer: customer,
            problem: problem
        )

        messages.append(
            ChatMessage(
                role: .system,
                text: "Ask the Duck is ready for \(customer.name.isEmpty ? "the customer" : customer.name). Snap a photo, record a short video of the equipment or water, or just tell me what you're seeing."
            )
        )
    }

    // MARK: - Attachments

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

    // MARK: - Chat

    func send() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !pendingAttachments.isEmpty else { return }

        let outgoing = ChatMessage(
            role: .technician,
            text: trimmed,
            attachments: pendingAttachments
        )
        messages.append(outgoing)
        let sentAttachments = pendingAttachments
        inputText = ""
        pendingAttachments = []
        errorMessage = nil
        isSending = true
        defer { isSending = false }

        await persistHistory(newAttachments: sentAttachments)

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
        await persistHistory()
    }

    // MARK: - History persistence

    /// Upserts the current session into `HistoryStore` so the tech's
    /// search picks it up immediately. Called after every message tick.
    private func persistHistory(newAttachments: [Attachment] = []) async {
        let transcriptEntries = messages.map { message in
            TicketMessage(
                id: message.id,
                role: mapRole(message.role),
                text: message.text,
                timestamp: message.timestamp,
                attachmentFilenames: message.attachments.map { "\($0.id.uuidString).jpg" }
            )
        }
        let firstTechText = messages.first(where: { $0.role == .technician })?.text ?? ""
        let summary = firstTechText.isEmpty
            ? "\(problem.rawValue) — \(customer.name)"
            : String(firstTechText.prefix(120))

        currentRecord.transcript = transcriptEntries
        currentRecord.summary = summary
        currentRecord.escalatedTicketID = lastEscalatedTicket?.id
        currentRecord.quoteIDs = Array(Set((currentRecord.quoteIDs) + [generatedQuote?.id].compactMap { $0 }))

        do {
            currentRecord = try await history.upsert(
                record: currentRecord,
                newAttachments: newAttachments
            )
        } catch {
            // History persistence is best-effort; surface in debug only.
            #if DEBUG
            print("History upsert failed: \(error)")
            #endif
        }
    }

    // MARK: - Escalation

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
            await persistHistory()
        } catch {
            escalationError = error.localizedDescription
        }
    }

    // MARK: - Quote generation

    /// Asks Claude to draft a quote from the current transcript. Result
    /// lands in `generatedQuote` for `QuoteView` to open + edit.
    func generateQuote() async {
        quoteError = nil
        isGeneratingQuote = true
        defer { isGeneratingQuote = false }

        do {
            let draft = try await quoteService.draft(
                from: currentRecord,
                existingQuote: generatedQuote,
                technicianId: technician.id,
                technicianName: technician.name
            )
            let saved = try await quotes.save(draft)
            generatedQuote = saved
            await persistHistory()
            messages.append(
                ChatMessage(
                    role: .system,
                    text: "Drafted a \(Int(saved.markupPercent))% markup quote with \(saved.lineItems.count) line item\(saved.lineItems.count == 1 ? "" : "s"). Review and send when ready."
                )
            )
        } catch {
            quoteError = error.localizedDescription
        }
    }

    /// Starts a brand-new empty quote (entry point: "Start with a quote"
    /// from the problem-type screen). Techs often open a job already
    /// knowing they're writing a quote before they troubleshoot.
    func startBlankQuote() async {
        let blank = Quote(
            technicianId: technician.id,
            technicianName: technician.name,
            customer: customer,
            problem: problem,
            serviceRecordID: serviceRecordID,
            lineItems: [
                QuoteLineItem(description: "", partNumber: nil, quantity: 1, unitCost: 0)
            ],
            laborHours: 0,
            laborRate: 125,
            markupPercent: 100
        )
        do {
            generatedQuote = try await quotes.save(blank)
        } catch {
            quoteError = error.localizedDescription
        }
    }

    func save(_ quote: Quote) async {
        do {
            generatedQuote = try await quotes.save(quote)
            await persistHistory()
        } catch {
            quoteError = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func mapRole(_ role: ChatMessage.Role) -> TicketMessage.Role {
        switch role {
        case .technician: return .technician
        case .duck: return .duck
        case .system: return .system
        }
    }
}
