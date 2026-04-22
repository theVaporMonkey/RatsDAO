import Foundation
import UIKit
import Combine

/// Abstract persistence for `ServiceRecord`s. Default implementation saves
/// to Application Support; swap for Firestore / REST when syncing across
/// the franchise.
protocol HistoryStoring: AnyObject {
    var recordsPublisher: AnyPublisher<[ServiceRecord], Never> { get }
    func refresh() async
    func upsert(
        record: ServiceRecord,
        newAttachments: [Attachment]
    ) async throws -> ServiceRecord
    func records(forTechnician technicianId: String) -> [ServiceRecord]
    func records(matching query: String) -> [ServiceRecord]
    func records(forCustomer customer: CustomerInfo) -> [ServiceRecord]
    func attachmentURL(recordID: UUID, filename: String) -> URL
}

final class LocalHistoryStore: HistoryStoring {
    static let shared = LocalHistoryStore()

    private let rootURL: URL
    private let subject = CurrentValueSubject<[ServiceRecord], Never>([])
    private let ioQueue = DispatchQueue(label: "com.poolduck.asktheduck.history")

    var recordsPublisher: AnyPublisher<[ServiceRecord], Never> {
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
        rootURL = base.appendingPathComponent("AskTheDuckHistory", isDirectory: true)
        try? fm.createDirectory(at: rootURL, withIntermediateDirectories: true)
        Task { await refresh() }
    }

    func refresh() async {
        let loaded = await Task.detached(priority: .utility) { [rootURL] in
            Self.loadAll(from: rootURL)
        }.value
        subject.send(loaded.sorted { $0.updatedAt > $1.updatedAt })
    }

    /// Upserts the record and writes any new attachment JPEGs to its
    /// folder. Safe to call on every message send — cheap ops.
    func upsert(
        record: ServiceRecord,
        newAttachments: [Attachment]
    ) async throws -> ServiceRecord {
        let dir = rootURL.appendingPathComponent(record.id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        var updated = record
        updated.updatedAt = Date()

        var known = Set(updated.attachmentFilenames)
        for attachment in newAttachments {
            let filename = "\(attachment.id.uuidString).jpg"
            guard !known.contains(filename) else { continue }
            let dest = dir.appendingPathComponent(filename)
            try attachment.jpegData.write(to: dest, options: .atomic)
            updated.attachmentFilenames.append(filename)
            known.insert(filename)
        }

        try write(updated, in: dir)
        await refresh()
        return updated
    }

    func records(forTechnician technicianId: String) -> [ServiceRecord] {
        subject.value.filter { $0.technicianId == technicianId }
    }

    func records(matching query: String) -> [ServiceRecord] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return subject.value }
        let tokens = trimmed.split(separator: " ").map(String.init)
        return subject.value.filter { record in
            let hay = record.searchHaystack
            return tokens.allSatisfy { hay.contains($0) }
        }
    }

    func records(forCustomer customer: CustomerInfo) -> [ServiceRecord] {
        let normalizedAddress = customer.address.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPhone = customer.phone.filter(\.isNumber)
        let normalizedName = customer.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return subject.value.filter { record in
            let addressMatch = !normalizedAddress.isEmpty &&
                record.customer.address.lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines) == normalizedAddress
            let phoneMatch = !normalizedPhone.isEmpty &&
                record.customer.phone.filter(\.isNumber) == normalizedPhone
            let nameMatch = !normalizedName.isEmpty &&
                record.customer.name.lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines) == normalizedName
            return addressMatch || phoneMatch || nameMatch
        }
    }

    func attachmentURL(recordID: UUID, filename: String) -> URL {
        rootURL
            .appendingPathComponent(recordID.uuidString, isDirectory: true)
            .appendingPathComponent(filename)
    }

    // MARK: - Private

    private func write(_ record: ServiceRecord, in dir: URL) throws {
        let url = dir.appendingPathComponent("record.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)
        try data.write(to: url, options: .atomic)
    }

    private static func loadAll(from root: URL) -> [ServiceRecord] {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return dirs.compactMap { dir in
            let jsonURL = dir.appendingPathComponent("record.json")
            guard let data = try? Data(contentsOf: jsonURL) else { return nil }
            return try? decoder.decode(ServiceRecord.self, from: data)
        }
    }
}
