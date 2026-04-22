import Foundation
import Combine

protocol QuoteStoring: AnyObject {
    var quotesPublisher: AnyPublisher<[Quote], Never> { get }
    func refresh() async
    func save(_ quote: Quote) async throws -> Quote
    func quotes(forCustomer customer: CustomerInfo) -> [Quote]
    func quotes(forTechnician technicianId: String) -> [Quote]
}

final class LocalQuoteStore: QuoteStoring {
    static let shared = LocalQuoteStore()

    private let rootURL: URL
    private let subject = CurrentValueSubject<[Quote], Never>([])

    var quotesPublisher: AnyPublisher<[Quote], Never> {
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
        rootURL = base.appendingPathComponent("AskTheDuckQuotes", isDirectory: true)
        try? fm.createDirectory(at: rootURL, withIntermediateDirectories: true)
        Task { await refresh() }
    }

    func refresh() async {
        let loaded = await Task.detached(priority: .utility) { [rootURL] in
            Self.loadAll(from: rootURL)
        }.value
        subject.send(loaded.sorted { $0.updatedAt > $1.updatedAt })
    }

    func save(_ quote: Quote) async throws -> Quote {
        var updated = quote
        updated.updatedAt = Date()
        let url = rootURL.appendingPathComponent("\(quote.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(updated).write(to: url, options: .atomic)
        await refresh()
        return updated
    }

    func quotes(forCustomer customer: CustomerInfo) -> [Quote] {
        let phone = customer.phone.filter(\.isNumber)
        let address = customer.address.lowercased().trimmingCharacters(in: .whitespaces)
        return subject.value.filter { q in
            q.customer.phone.filter(\.isNumber) == phone ||
            q.customer.address.lowercased().trimmingCharacters(in: .whitespaces) == address
        }
    }

    func quotes(forTechnician technicianId: String) -> [Quote] {
        subject.value.filter { $0.technicianId == technicianId }
    }

    private static func loadAll(from root: URL) -> [Quote] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return files.compactMap { file in
            guard file.pathExtension == "json",
                  let data = try? Data(contentsOf: file) else { return nil }
            return try? decoder.decode(Quote.self, from: data)
        }
    }
}
