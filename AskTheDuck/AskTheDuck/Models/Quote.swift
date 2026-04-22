import Foundation

struct QuoteLineItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var description: String
    var partNumber: String?
    var quantity: Double
    var unitCost: Double

    var subtotal: Double { quantity * unitCost }
}

struct Quote: Codable, Identifiable, Hashable {
    enum Status: String, Codable, CaseIterable {
        case draft, readyToSend, sent, accepted, declined

        var display: String {
            switch self {
            case .draft: return "Draft"
            case .readyToSend: return "Ready to Send"
            case .sent: return "Sent"
            case .accepted: return "Accepted"
            case .declined: return "Declined"
            }
        }
    }

    let id: UUID
    let createdAt: Date
    var updatedAt: Date

    let technicianId: String
    let technicianName: String
    let customer: CustomerInfo
    let problem: ProblemType

    /// Links the quote back to the chat session it came from, if any.
    var serviceRecordID: UUID?

    var lineItems: [QuoteLineItem]
    var laborHours: Double
    var laborRate: Double

    /// Pool Duck's default markup on parts is 100% (2x cost). The tech
    /// can pull this down if the local high-end market won't bear it.
    var markupPercent: Double
    /// Freeform note from the tech explaining why they deviated from
    /// the default 100% markup (e.g. "Tampa market tops out around 75%
    /// on variable-speed swaps").
    var localMarketNote: String
    var notes: String
    var status: Status

    // MARK: - Computed totals

    var partsCost: Double { lineItems.reduce(0) { $0 + $1.subtotal } }
    var partsMarkedUp: Double { partsCost * (1 + markupPercent / 100.0) }
    var laborCost: Double { laborHours * laborRate }
    var total: Double { partsMarkedUp + laborCost }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        technicianId: String,
        technicianName: String,
        customer: CustomerInfo,
        problem: ProblemType,
        serviceRecordID: UUID? = nil,
        lineItems: [QuoteLineItem] = [],
        laborHours: Double = 0,
        laborRate: Double = 125,
        markupPercent: Double = 100,
        localMarketNote: String = "",
        notes: String = "",
        status: Status = .draft
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.technicianId = technicianId
        self.technicianName = technicianName
        self.customer = customer
        self.problem = problem
        self.serviceRecordID = serviceRecordID
        self.lineItems = lineItems
        self.laborHours = laborHours
        self.laborRate = laborRate
        self.markupPercent = markupPercent
        self.localMarketNote = localMarketNote
        self.notes = notes
        self.status = status
    }
}
