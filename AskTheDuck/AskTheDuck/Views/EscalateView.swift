import SwiftUI

/// Presented when a tech can't resolve the issue with Claude's help and
/// wants to kick the whole thing (photos, transcript, customer info) up
/// to the admin queue.
struct EscalateView: View {
    @ObservedObject var viewModel: ChatViewModel
    let onSubmitted: (EscalationTicket) -> Void
    let onCancel: () -> Void

    @State private var summary: String = ""
    @State private var troubleshooting: String = ""

    private var suggestedTroubleshooting: String {
        let duckReplies = viewModel.messages
            .filter { $0.role == .duck }
            .map { $0.text }
            .joined(separator: "\n\n---\n\n")
        return duckReplies.isEmpty
            ? ""
            : "Tried Claude's recommendations:\n\n\(duckReplies)"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer") {
                    LabeledContent("Name", value: viewModel.customer.name)
                    LabeledContent("Address", value: viewModel.customer.address)
                    LabeledContent("Phone", value: viewModel.customer.phone)
                    LabeledContent("Problem", value: viewModel.problem.rawValue)
                }

                Section("What's the issue?") {
                    TextField(
                        "Short description of what's wrong",
                        text: $summary,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                Section("What have you already tried?") {
                    TextField(
                        "Steps taken so far",
                        text: $troubleshooting,
                        axis: .vertical
                    )
                    .lineLimit(4...10)
                    if !suggestedTroubleshooting.isEmpty {
                        Button {
                            if troubleshooting.isEmpty {
                                troubleshooting = suggestedTroubleshooting
                            } else {
                                troubleshooting += "\n\n" + suggestedTroubleshooting
                            }
                        } label: {
                            Label("Paste Claude's guidance", systemImage: "text.quote")
                        }
                        .font(.footnote)
                    }
                }

                Section("Going to the office") {
                    Label("\(viewModel.messages.count) chat messages", systemImage: "bubble.left.and.bubble.right")
                    let attachmentCount = viewModel.messages.reduce(0) { $0 + $1.attachments.count }
                    Label("\(attachmentCount) photos / video stills", systemImage: "photo.stack")
                }

                if let error = viewModel.escalationError {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Escalate to office")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: onCancel)
                        .disabled(viewModel.isEscalating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await viewModel.escalate(
                                summary: summary,
                                troubleshootingTaken: troubleshooting
                            )
                            if let ticket = viewModel.lastEscalatedTicket {
                                onSubmitted(ticket)
                            }
                        }
                    } label: {
                        if viewModel.isEscalating {
                            ProgressView()
                        } else {
                            Text("Submit").bold()
                        }
                    }
                    .disabled(
                        viewModel.isEscalating ||
                        summary.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                }
            }
        }
    }
}
