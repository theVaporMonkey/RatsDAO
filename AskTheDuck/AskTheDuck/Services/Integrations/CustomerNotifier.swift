import Foundation

// MARK: - Customer notifications (future release)
//
// NOT WIRED UP YET. This is a protocol stub for the outbound-comms
// feature planned in the next couple of releases: once the admin
// schedules a repair, Pool Duck automatically sends the customer an
// email AND/OR SMS with the appointment details, reminders, and a
// post-visit summary rewritten for a homeowner audience (a separate
// Claude prompt from the one that powers Ask the Duck — this one
// translates the tech-facing notes into customer-friendly language).
//
// Delivery options under consideration (pick one at wire-up):
// - Twilio for SMS + SendGrid for email, behind the Pool Duck proxy.
// - The Pool Brain notification endpoints (if Pool Brain supports
//   transactional email/SMS already — TBD against their docs).
// - A serverless proxy on the Pool Duck franchise portal that
//   fans out to the right provider per franchise (some franchisees
//   may have their own Twilio / SendGrid accounts for brand-match).
//
// Compliance reminders for whoever implements this:
// - TCPA for SMS: must have explicit opt-in on record before sending.
//   Surface the opt-in status in the admin ticket UI.
// - CAN-SPAM: include the franchise's physical address + unsubscribe.
// - Quiet hours per recipient time zone.

protocol CustomerNotifying: AnyObject {
    func sendAppointmentConfirmation(
        ticket: EscalationTicket,
        scheduledFor: Date,
        channels: Set<NotificationChannel>
    ) async throws

    func sendServiceSummary(
        record: ServiceRecord,
        homeownerFriendlySummary: String,
        channels: Set<NotificationChannel>
    ) async throws
}

enum NotificationChannel: String, Codable, CaseIterable {
    case email, sms
}

/// No-op default until the real notifier is wired in.
final class NoopCustomerNotifier: CustomerNotifying {
    static let shared = NoopCustomerNotifier()

    func sendAppointmentConfirmation(
        ticket: EscalationTicket,
        scheduledFor: Date,
        channels: Set<NotificationChannel>
    ) async throws {
        // TODO: POST to Pool Duck proxy → Twilio / SendGrid / Pool Brain.
    }

    func sendServiceSummary(
        record: ServiceRecord,
        homeownerFriendlySummary: String,
        channels: Set<NotificationChannel>
    ) async throws {
        // TODO: Generate a homeowner-friendly summary via a second
        // Claude call (re-audience the transcript), then ship it.
    }
}
