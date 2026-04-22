import Foundation
import Combine
import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var scope: Scope = .mine
    @Published private(set) var allRecords: [ServiceRecord] = []

    enum Scope: String, CaseIterable, Identifiable {
        case mine = "Mine"
        case everyone = "Franchise"
        var id: String { rawValue }
    }

    let technician: Technician
    private let store: HistoryStoring
    private var cancellable: AnyCancellable?

    init(technician: Technician, store: HistoryStoring = LocalHistoryStore.shared) {
        self.technician = technician
        self.store = store
        cancellable = store.recordsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.allRecords = $0 }
        Task { await store.refresh() }
    }

    var results: [ServiceRecord] {
        let scoped: [ServiceRecord]
        switch scope {
        case .mine:
            scoped = allRecords.filter { $0.technicianId == technician.id }
        case .everyone:
            scoped = allRecords
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return scoped }
        let tokens = trimmed.split(separator: " ").map(String.init)
        return scoped.filter { record in
            let hay = record.searchHaystack
            return tokens.allSatisfy { hay.contains($0) }
        }
    }

    func attachmentURL(recordID: UUID, filename: String) -> URL {
        store.attachmentURL(recordID: recordID, filename: filename)
    }
}
