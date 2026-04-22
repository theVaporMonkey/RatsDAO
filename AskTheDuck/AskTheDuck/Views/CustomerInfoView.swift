import SwiftUI

/// Captured at the start of every service call so every ticket carries the
/// customer's contact info. Required before the chat can start.
struct CustomerInfoView: View {
    let problem: ProblemType
    let onContinue: (CustomerInfo) -> Void
    let onCancel: () -> Void

    @State private var info = CustomerInfo.empty
    @FocusState private var focus: Field?
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
            .onAppear { focus = .name }
        }
    }
}

#Preview {
    CustomerInfoView(
        problem: .equipment,
        onContinue: { _ in },
        onCancel: {}
    )
}
