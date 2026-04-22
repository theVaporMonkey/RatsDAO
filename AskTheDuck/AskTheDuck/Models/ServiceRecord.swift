import Foundation

/// A full record of a technician's session at a customer. Every chat —
/// whether it gets escalated or not — is persisted as a ServiceRecord so
/// the tech can pull up "the last time I was at 123 Oak Street" later.
struct ServiceRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date

    let technicianId: String
    let technicianName: String
    let technicianEmail: String

    let customer: CustomerInfo
    let problem: ProblemType

    /// Short headline auto-derived from the first tech message (or the
    /// problem type if there's no message yet).
    var summary: String

    /// Full transcript captured as the session unfolds.
    var transcript: [TicketMessage]
    /// Every attachment saved into the record's folder.
    var attachmentFilenames: [String]

    /// Set when the session is escalated. Links the two together so the
    /// history row can show the scheduled repair status.
    var escalatedTicketID: UUID?

    /// Quotes the tech generated during or after this session.
    var quoteIDs: [UUID]

    /// Text the tech can search on (customer name/address/phone/summary).
    var searchHaystack: String {
        [
            customer.name,
            customer.address,
            customer.phone,
            problem.rawValue,
            summary,
            transcript.map { $0.text }.joined(separator: " ")
        ]
        .joined(separator: " ")
        .lowercased()
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        technicianId: String,
        technicianName: String,
        technicianEmail: String,
        customer: CustomerInfo,
        problem: ProblemType,
        summary: String = "",
        transcript: [TicketMessage] = [],
        attachmentFilenames: [String] = [],
        escalatedTicketID: UUID? = nil,
        quoteIDs: [UUID] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.technicianId = technicianId
        self.technicianName = technicianName
        self.technicianEmail = technicianEmail
        self.customer = customer
        self.problem = problem
        self.summary = summary
        self.transcript = transcript
        self.attachmentFilenames = attachmentFilenames
        self.escalatedTicketID = escalatedTicketID
        self.quoteIDs = quoteIDs
    }
}
