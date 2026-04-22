import SwiftUI

/// Captured at the start of every service call. Required before the chat
/// can start. Also surfaces prior visits for the same customer as the
/// tech types — so they see "last time at 123 Oak Street" before they
/// even open the chat.
struct CustomerInfoView: View {
    let problem: ProblemType
    let onContinue: (CustomerInfo) -> Void
    let onCancel: () -> Void

    @State private var info = CustomerInfo.empty
    @FocusState private var focus: Field?
    @State private var priorVisits: [ServiceRecord] = []
    private let history: HistoryStoring = LocalHistoryStore.shared

    private enum Field { case name, address, phone }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: problem.systemIcon)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(PoolDuckTheme.deepTeal))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(problem.rawValue).font(.headline)
                            Text("New service call")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Customer") {
                    TextField("Full name", text: $info.name)
                        .textContentType(.name)
                        .focused($focus, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focus = .address }

                    TextField("Service address", text: $info.address, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                        .lineLimit(2...4)
                        .focused($focus, equals: .address)
                        .submitLabel(.next)
                        .onSubmit { focus = .phone }

                    TextField("Phone number", text: $info.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .focused($focus, equals: .phone)
                }

                if !priorVisits.isEmpty {
                    Section("Prior visits") {
                        ForEach(priorVisits.prefix(5)) { visit in
                            Button {
                                info = visit.customer
                                recomputeMatches()
                            } label: {
                                PriorVisitRow(record: visit)
                            }
                            .buttonStyle(.plain)
                        }
                        if priorVisits.count > 5 {
                            Text("+\(priorVisits.count - 5) more in Service History")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Text("Every ticket that gets escalated to the office will include this customer's info so it can be scheduled for a follow-up repair.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Who are you at?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") { onContinue(info) }
                        .disabled(!info.isValid)
                        .bold()
                }
            }
            .onAppear {
                focus = .name
                Task {
                    await history.refresh()
                    recomputeMatches()
                }
            }
            .onChange(of: info.name) { _, _ in recomputeMatches() }
            .onChange(of: info.address) { _, _ in recomputeMatches() }
            .onChange(of: info.phone) { _, _ in recomputeMatches() }
        }
    }

    private func recomputeMatches() {
        let name = info.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = info.address.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = info.phone.filter(\.isNumber)
        guard name.count >= 2 || address.count >= 3 || phone.count >= 4 else {
            priorVisits = []
            return
        }
        let tokens = [name, address, phone].filter { !$0.isEmpty }
        let query = tokens.joined(separator: " ")
        priorVisits = history.records(matching: query)
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}

private struct PriorVisitRow: View {
    let record: ServiceRecord

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: record.problem.systemIcon)
                .foregroundStyle(PoolDuckTheme.deepTeal)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(record.customer.name).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(record.updatedAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(record.customer.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(record.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CustomerInfoView(
        problem: .equipment,
        onContinue: { _ in },
        onCancel: {}
    )
}
