import Foundation
import Combine
import SwiftUI

@MainActor
final class AdminViewModel: ObservableObject {
    @Published private(set) var tickets: [EscalationTicket] = []
    @Published var filter: EscalationTicket.Status? = nil
    @Published var errorMessage: String?

    private let store: TicketStoring
    private var cancellable: AnyCancellable?

    init(store: TicketStoring = LocalTicketStore.shared) {
        self.store = store
        cancellable = store.ticketsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.tickets = $0 }
        Task { await store.refresh() }
    }

    var filteredTickets: [EscalationTicket] {
        guard let filter else { return tickets }
        return tickets.filter { $0.status == filter }
    }

    var pendingCount: Int { tickets.filter { $0.status == .pending }.count }
    var scheduledCount: Int { tickets.filter { $0.status == .scheduled }.count }
    var completedCount: Int { tickets.filter { $0.status == .completed }.count }

    func schedule(_ ticket: EscalationTicket, for date: Date, notes: String?) async {
        var updated = ticket
        updated.status = .scheduled
        updated.scheduledFor = date
        if let notes, !notes.isEmpty { updated.adminNotes = notes }
        await save(updated)
    }

    func markCompleted(_ ticket: EscalationTicket, notes: String?) async {
        var updated = ticket
        updated.status = .completed
        if let notes, !notes.isEmpty { updated.adminNotes = notes }
        await save(updated)
    }

    func reopen(_ ticket: EscalationTicket) async {
        var updated = ticket
        updated.status = .pending
        updated.scheduledFor = nil
        await save(updated)
    }

    private func save(_ ticket: EscalationTicket) async {
        do {
            try await store.update(ticket)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func attachmentURL(ticketID: UUID, filename: String) -> URL {
        store.attachmentURL(ticketID: ticketID, filename: filename)
    }
}
