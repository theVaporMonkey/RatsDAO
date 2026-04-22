import SwiftUI

struct QuoteView: View {
    @State var quote: Quote
    let onSave: (Quote) async -> Void
    let onClose: () -> Void

    @State private var isSaving = false

    private static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                headerSection
                lineItemsSection
                laborSection
                markupSection
                notesSection
                totalsSection
                statusSection
            }
            .navigationTitle("Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            isSaving = true
                            await onSave(quote)
                            isSaving = false
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save").bold()
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private var headerSection: some View {
        Section {
            LabeledContent("Customer", value: quote.customer.name)
            LabeledContent("Address", value: quote.customer.address)
            LabeledContent("Problem", value: quote.problem.rawValue)
            LabeledContent("Tech", value: quote.technicianName)
        }
    }

    private var lineItemsSection: some View {
        Section {
            ForEach($quote.lineItems) { $item in
                LineItemEditor(item: $item)
            }
            .onDelete { indexSet in
                quote.lineItems.remove(atOffsets: indexSet)
            }
            Button {
                quote.lineItems.append(
                    QuoteLineItem(description: "", partNumber: nil, quantity: 1, unitCost: 0)
                )
            } label: {
                Label("Add line item", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Parts")
        } footer: {
            Text("Enter dealer cost. Pool Duck markup is applied below.")
                .font(.caption)
        }
    }

    private var laborSection: some View {
        Section("Labor") {
            HStack {
                Text("Hours")
                Spacer()
                TextField("0.0", value: $quote.laborHours, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                Text("Rate / hr")
                Spacer()
                TextField("0.00", value: $quote.laborRate, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private var markupSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Parts markup")
                    Spacer()
                    Text("\(Int(quote.markupPercent))%")
                        .font(.headline)
                        .foregroundStyle(PoolDuckTheme.deepTeal)
                }
                Slider(value: $quote.markupPercent, in: 0...100, step: 5)
                HStack(spacing: 8) {
                    ForEach([60, 75, 90, 100], id: \.self) { preset in
                        Button("\(preset)%") {
                            quote.markupPercent = Double(preset)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(
                            Int(quote.markupPercent) == preset
                            ? PoolDuckTheme.deepTeal : .gray
                        )
                    }
                }
            }
            TextField(
                "Local market note (e.g. \"Tampa tops out ~75% on VS pump swaps\")",
                text: $quote.localMarketNote,
                axis: .vertical
            )
            .lineLimit(2...4)
        } header: {
            Text("Markup")
        } footer: {
            Text("Pool Duck default is 100%. Only pull this down if the local market won't bear it — leave a note explaining why.")
                .font(.caption)
        }
    }

    private var notesSection: some View {
        Section("Notes for the tech") {
            TextField("Internal notes", text: $quote.notes, axis: .vertical)
                .lineLimit(3...8)
        }
    }

    private var totalsSection: some View {
        Section("Totals") {
            LabeledContent("Parts (dealer)", value: currency(quote.partsCost))
            LabeledContent(
                "Parts (billable)",
                value: currency(quote.partsMarkedUp)
            )
            LabeledContent("Labor", value: currency(quote.laborCost))
            LabeledContent {
                Text(currency(quote.total)).font(.title3.bold())
                    .foregroundStyle(PoolDuckTheme.deepTeal)
            } label: {
                Text("Customer total").font(.headline)
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: $quote.status) {
                ForEach(Quote.Status.allCases, id: \.self) { status in
                    Text(status.display).tag(status)
                }
            }
        }
    }

    private func currency(_ value: Double) -> String {
        Self.currency.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

private struct LineItemEditor: View {
    @Binding var item: QuoteLineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Part description", text: $item.description)
                .font(.body.weight(.medium))

            HStack(spacing: 10) {
                TextField("Part #", text: Binding(
                    get: { item.partNumber ?? "" },
                    set: { item.partNumber = $0.isEmpty ? nil : $0 }
                ))
                .font(.caption)
                .frame(maxWidth: 120)

                Spacer()

                HStack(spacing: 2) {
                    Text("Qty")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("1", value: $item.quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 44)
                }

                HStack(spacing: 2) {
                    Text("$")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("0.00", value: $item.unitCost, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                }
            }

            HStack {
                Spacer()
                Text("Subtotal \(item.subtotal, format: .currency(code: "USD"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
