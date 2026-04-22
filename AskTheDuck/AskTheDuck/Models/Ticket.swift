import Foundation

/// Transcript-style entry preserved on a ticket so the admin sees the full
/// back-and-forth between the technician and Claude.
struct TicketMessage: Codable, Hashable, Identifiable {
    enum Role: String, Codable { case technician, duck, system }

    let id: UUID
    let role: Role
    let text: String
    let timestamp: Date
    /// Filenames (no path) of attachments saved into the ticket's folder.
    let attachmentFilenames: [String]

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        timestamp: Date = Date(),
        attachmentFilenames: [String] = []
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
        self.attachmentFilenames = attachmentFilenames
    }
}

struct EscalationTicket: Codable, Identifiable, Hashable {
    enum Status: String, Codable, CaseIterable {
        case pending
        case scheduled
        case completed

        var display: String {
            switch self {
            case .pending: return "Pending"
            case .scheduled: return "Scheduled"
            case .completed: return "Completed"
            }
        }
    }

    let id: UUID
    var status: Status
    let submittedAt: Date
    let technicianId: String
    let technicianName: String
    let technicianEmail: String
    let customer: CustomerInfo
    let problem: ProblemType

    /// The technician's own description of what's wrong.
    let summary: String
    /// Freeform notes from the technician about what they've already tried
    /// (Claude's suggestions + what the tech did).
    let troubleshootingTaken: String

    /// Full chat transcript for the admin to scroll through.
    let transcript: [TicketMessage]
    /// Every attachment captured during the session (photos + video stills),
    /// stored on disk next to the ticket JSON.
    let attachmentFilenames: [String]

    var scheduledFor: Date?
    var adminNotes: String?

    init(
        id: UUID = UUID(),
        status: Status = .pending,
        submittedAt: Date = Date(),
        technicianId: String,
        technicianName: String,
        technicianEmail: String,
        customer: CustomerInfo,
        problem: ProblemType,
        summary: String,
        troubleshootingTaken: String,
        transcript: [TicketMessage],
        attachmentFilenames: [String],
        scheduledFor: Date? = nil,
        adminNotes: String? = nil
    ) {
        self.id = id
        self.status = status
        self.submittedAt = submittedAt
        self.technicianId = technicianId
        self.technicianName = technicianName
        self.technicianEmail = technicianEmail
        self.customer = customer
        self.problem = problem
        self.summary = summary
        self.troubleshootingTaken = troubleshootingTaken
        self.transcript = transcript
        self.attachmentFilenames = attachmentFilenames
        self.scheduledFor = scheduledFor
        self.adminNotes = adminNotes
    }
}
