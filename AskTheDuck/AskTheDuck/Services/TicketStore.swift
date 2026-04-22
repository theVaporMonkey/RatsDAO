import Foundation
import UIKit
import Combine

/// Abstract storage for escalation tickets. The default implementation
/// persists to the app's Application Support directory so it survives
/// launches on a single device; swap for a Firebase / CloudKit / REST
/// implementation when hooking up the real back office.
protocol TicketStoring: AnyObject {
    var ticketsPublisher: AnyPublisher<[EscalationTicket], Never> { get }
    func refresh() async
    func submit(
        technician: Technician,
        customer: CustomerInfo,
        problem: ProblemType,
        summary: String,
        troubleshootingTaken: String,
        messages: [ChatMessage]
    ) async throws -> EscalationTicket
    func update(_ ticket: EscalationTicket) async throws
    func attachmentURL(ticketID: UUID, filename: String) -> URL
}

/// Shared singleton so the technician-side submit and the admin-side list
/// see the same data.
final class LocalTicketStore: TicketStoring {
    static let shared = LocalTicketStore()

    private let rootURL: URL
    private let subject = CurrentValueSubject<[EscalationTicket], Never>([])
    private let queue = DispatchQueue(label: "com.poolduck.asktheduck.tickets")

    var ticketsPublisher: AnyPublisher<[EscalationTicket], Never> {
        subject.eraseToAnyPublisher()
    }

    init() {
        let fm = FileManager.default
        let base = (try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fm.temporaryDirectory
        rootURL = base.appendingPathComponent("AskTheDuckTickets", isDirectory: true)
        try? fm.createDirectory(at: rootURL, withIntermediateDirectories: true)
        Task { await refresh() }
    }

    func refresh() async {
        let loaded = await Task.detached(priority: .utility) { [rootURL] in
            Self.loadAll(from: rootURL)
        }.value
        subject.send(loaded.sorted { $0.submittedAt > $1.submittedAt })
    }

    func submit(
        technician: Technician,
        customer: CustomerInfo,
        problem: ProblemType,
        summary: String,
        troubleshootingTaken: String,
        messages: [ChatMessage]
    ) async throws -> EscalationTicket {
        let ticketID = UUID()
        let ticketDir = rootURL.appendingPathComponent(ticketID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: ticketDir, withIntermediateDirectories: true)

        var attachmentNames: [String] = []
        var transcriptEntries: [TicketMessage] = []
        var seenAttachmentIDs = Set<UUID>()

        for message in messages {
            var filesForThisMessage: [String] = []
            for attachment in message.attachments {
                let filename = "\(attachment.id.uuidString).jpg"
                if !seenAttachmentIDs.contains(attachment.id) {
                    let dest = ticketDir.appendingPathComponent(filename)
                    try attachment.jpegData.write(to: dest, options: .atomic)
                    attachmentNames.append(filename)
                    seenAttachmentIDs.insert(attachment.id)
                }
                filesForThisMessage.append(filename)
            }
            transcriptEntries.append(
                TicketMessage(
                    id: message.id,
                    role: mapRole(message.role),
                    text: message.text,
                    timestamp: message.timestamp,
                    attachmentFilenames: filesForThisMessage
                )
            )
        }

        let ticket = EscalationTicket(
            id: ticketID,
            status: .pending,
            submittedAt: Date(),
            technicianId: technician.id,
            technicianName: technician.name,
            technicianEmail: technician.email,
            customer: customer,
            problem: problem,
            summary: summary,
            troubleshootingTaken: troubleshootingTaken,
            transcript: transcriptEntries,
            attachmentFilenames: attachmentNames
        )

        try write(ticket)
        await refresh()
        return ticket
    }

    func update(_ ticket: EscalationTicket) async throws {
        try write(ticket)
        await refresh()
    }

    func attachmentURL(ticketID: UUID, filename: String) -> URL {
        rootURL
            .appendingPathComponent(ticketID.uuidString, isDirectory: true)
            .appendingPathComponent(filename)
    }

    // MARK: - Private

    private func write(_ ticket: EscalationTicket) throws {
        let dir = rootURL.appendingPathComponent(ticket.id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("ticket.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(ticket)
        try data.write(to: url, options: .atomic)
    }

    private static func loadAll(from root: URL) -> [EscalationTicket] {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return dirs.compactMap { dir in
            let jsonURL = dir.appendingPathComponent("ticket.json")
            guard let data = try? Data(contentsOf: jsonURL) else { return nil }
            return try? decoder.decode(EscalationTicket.self, from: data)
        }
    }

    private func mapRole(_ role: ChatMessage.Role) -> TicketMessage.Role {
        switch role {
        case .technician: return .technician
        case .duck: return .duck
        case .system: return .system
        }
    }
}
