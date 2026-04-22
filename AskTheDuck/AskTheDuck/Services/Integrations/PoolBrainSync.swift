import Foundation

// MARK: - Pool Brain integration (future release)
//
// NOT WIRED UP YET. This is a protocol stub so the rest of the app
// (ChatViewModel, TicketStore, HistoryStore) can be wired through a
// seam today, and a real Pool Brain adapter can be dropped in later
// without touching any call sites.
//
// Target behavior (planned for a follow-up release):
// 1. When a technician finishes a session, `syncServiceRecord` pushes
//    the photos + transcript + summary to Pool Brain as a work order /
//    service history entry.
// 2. When the admin schedules a repair, `syncTicketStatus` updates the
//    Pool Brain appointment and Pool Brain sends the customer an
//    email/SMS confirmation + reminders via `CustomerNotifier`.
// 3. `pullUpdates` fetches anything Pool Brain changed (tech
//    reassignments, reschedules) so the admin panel stays in sync.
//
// Auth: Pool Brain API key lives on the Pool Duck proxy, NOT in the
// mobile binary. Mirror the pattern already used for `CLAUDE_API_KEY`.
//
// Rate limits & offline: queue sync operations so a tech in a bad-
// signal backyard can still capture a full session; the sync drains
// once the truck rolls back into range.

protocol PoolBrainSyncing: AnyObject {
    func syncServiceRecord(_ record: ServiceRecord) async throws
    func syncTicket(_ ticket: EscalationTicket) async throws
    func pullUpdates() async throws -> [PoolBrainUpdate]
}

/// Thin envelope for whatever Pool Brain hands back when we pull. The
/// real shape will be defined against the Pool Brain API contract; this
/// is just a placeholder so the surrounding code compiles.
struct PoolBrainUpdate: Codable, Hashable {
    let remoteID: String
    let kind: String
    let payload: [String: String]
}

/// No-op default. The app wires this in today so feature flags can
/// flip to a real adapter later without call-site changes.
final class NoopPoolBrainSync: PoolBrainSyncing {
    static let shared = NoopPoolBrainSync()

    func syncServiceRecord(_ record: ServiceRecord) async throws {
        // TODO: POST to Pool Duck proxy → Pool Brain work-order endpoint.
    }

    func syncTicket(_ ticket: EscalationTicket) async throws {
        // TODO: POST to Pool Duck proxy → Pool Brain appointment endpoint.
    }

    func pullUpdates() async throws -> [PoolBrainUpdate] {
        // TODO: GET from Pool Duck proxy → Pool Brain change feed.
        []
    }
}
