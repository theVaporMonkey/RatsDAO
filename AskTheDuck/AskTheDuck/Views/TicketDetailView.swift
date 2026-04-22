import SwiftUI
import UIKit

struct TicketDetailView: View {
    let ticket: EscalationTicket
    @ObservedObject var viewModel: AdminViewModel

    @State private var scheduledDate: Date
    @State private var adminNotes: String
    @State private var showingScheduler = false

    init(ticket: EscalationTicket, viewModel: AdminViewModel) {
        self.ticket = ticket
        self.viewModel = viewModel
        _scheduledDate = State(
            initialValue: ticket.scheduledFor ?? Date().addingTimeInterval(60 * 60 * 24)
        )
        _adminNotes = State(initialValue: ticket.adminNotes ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                statusHeader
                customerCard
                problemCard
                if !ticket.attachmentFilenames.isEmpty {
                    attachmentGallery
                }
                transcriptCard
                schedulingCard
            }
            .padding()
        }
        .background(PoolDuckTheme.surface)
        .navigationTitle(ticket.customer.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingScheduler) {
            NavigationStack {
                Form {
                    DatePicker(
                        "Scheduled for",
                        selection: $scheduledDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    Section("Notes for technician") {
                        TextField("Optional notes", text: $adminNotes, axis: .vertical)
                            .lineLimit(3...8)
                    }
                }
                .navigationTitle("Schedule repair")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingScheduler = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                await viewModel.schedule(
                                    ticket,
                                    for: scheduledDate,
                                    notes: adminNotes
                                )
                                showingScheduler = false
                            }
                        }
                        .bold()
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var statusHeader: some View {
        HStack(spacing: 10) {
            StatusBadge(status: ticket.status)
            Text("Submitted \(ticket.submittedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var customerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Customer").font(.caption).foregroundStyle(.secondary)
            Text(ticket.customer.name).font(.title3.bold())
            HStack {
                Image(systemName: "mappin.and.ellipse")
                Text(ticket.customer.address)
            }
            .font(.subheadline)

            HStack {
                Image(systemName: "phone.fill")
                Link(ticket.customer.phone, destination: telURL(ticket.customer.phone))
            }
            .font(.subheadline)

            Divider()
            HStack {
                Image(systemName: "person.fill")
                Text("Tech: \(ticket.technicianName)")
                Spacer()
                Text(ticket.technicianEmail).foregroundStyle(.secondary)
            }
            .font(.footnote)
        }
        .cardBackground()
    }

    private var problemCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: ticket.problem.systemIcon)
                    .foregroundStyle(PoolDuckTheme.deepTeal)
                Text(ticket.problem.rawValue).font(.headline)
            }

            Text("Issue").font(.caption).foregroundStyle(.secondary)
            Text(ticket.summary)
                .font(.body)

            if !ticket.troubleshootingTaken.isEmpty {
                Text("Already tried").font(.caption).foregroundStyle(.secondary)
                Text(ticket.troubleshootingTaken)
                    .font(.footnote)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PoolDuckTheme.surface, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .cardBackground()
    }

    private var attachmentGallery: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photos & video stills").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ticket.attachmentFilenames, id: \.self) { name in
                        let url = viewModel.attachmentURL(ticketID: ticket.id, filename: name)
                        if let data = try? Data(contentsOf: url),
                           let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
        .cardBackground()
    }

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chat transcript").font(.headline)
            ForEach(ticket.transcript) { message in
                TranscriptBubble(message: message)
            }
        }
        .cardBackground()
    }

    private var schedulingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dispatch").font(.headline)
            if let scheduled = ticket.scheduledFor {
                HStack {
                    Image(systemName: "calendar")
                    Text("Repair scheduled: \(scheduled.formatted(date: .complete, time: .shortened))")
                }
                .font(.subheadline)
            }
            if let notes = ticket.adminNotes, !notes.isEmpty {
                Text(notes)
                    .font(.footnote)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PoolDuckTheme.surface, in: RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 10) {
                Button {
                    showingScheduler = true
                } label: {
                    Label(
                        ticket.status == .scheduled ? "Reschedule" : "Schedule repair",
                        systemImage: "calendar.badge.plus"
                    )
                }
                .buttonStyle(PrimaryButtonStyle())

                if ticket.status != .completed {
                    Button {
                        Task { await viewModel.markCompleted(ticket, notes: adminNotes) }
                    } label: {
                        Label("Mark done", systemImage: "checkmark.seal.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button {
                        Task { await viewModel.reopen(ticket) }
                    } label: {
                        Label("Reopen", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .cardBackground()
    }

    private func telURL(_ phone: String) -> URL {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel://\(digits)") ?? URL(string: "about:blank")!
    }
}

private struct TranscriptBubble: View {
    let message: TicketMessage

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            if !message.text.isEmpty {
                Text(.init(message.text))
                    .font(.footnote)
                    .padding(10)
                    .background(bubbleColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(foregroundColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private var alignment: HorizontalAlignment {
        switch message.role {
        case .technician: return .trailing
        case .duck, .system: return .leading
        }
    }

    private var frameAlignment: Alignment {
        switch message.role {
        case .technician: return .trailing
        case .duck, .system: return .leading
        }
    }

    private var label: String {
        switch message.role {
        case .technician: return "Technician"
        case .duck: return "Ask the Duck"
        case .system: return "System"
        }
    }

    private var bubbleColor: Color {
        switch message.role {
        case .technician: return PoolDuckTheme.deepTeal
        case .duck: return PoolDuckTheme.surface
        case .system: return .clear
        }
    }

    private var foregroundColor: Color {
        switch message.role {
        case .technician: return .white
        case .duck, .system: return PoolDuckTheme.inkBlack
        }
    }
}
