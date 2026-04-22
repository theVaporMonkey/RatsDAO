import SwiftUI

struct AdminPanelView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel = AdminViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                filterBar
                ticketList
            }
            .background(PoolDuckTheme.surface)
            .navigationTitle("Admin Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let tech = auth.technician {
                            Text(tech.name)
                            Text(tech.email).foregroundStyle(.secondary)
                            Divider()
                        }
                        Button {
                            Task { await LocalTicketStore.shared.refresh() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        Button(role: .destructive) {
                            auth.signOut()
                        } label: {
                            Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(PoolDuckTheme.deepTeal)
                    }
                }
            }
            .refreshable { await LocalTicketStore.shared.refresh() }
        }
    }

    private var header: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(PoolDuckTheme.gradient())
            HStack(spacing: 16) {
                DuckLogo(size: 64, showsWordmark: false)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pool Duck Admin")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    if let tech = auth.technician {
                        Text(tech.name)
                            .font(.subheadline)
                            .foregroundStyle(PoolDuckTheme.cream)
                    }
                }
                Spacer()
                countPills
            }
            .padding()
        }
        .frame(height: 110)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var countPills: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(viewModel.pendingCount) new")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.white, in: Capsule())
                .foregroundStyle(PoolDuckTheme.deepTeal)
            Text("\(viewModel.scheduledCount) scheduled")
                .font(.caption)
                .foregroundStyle(.white)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(title: "All (\(viewModel.tickets.count))", isOn: viewModel.filter == nil) {
                    viewModel.filter = nil
                }
                FilterPill(title: "Pending (\(viewModel.pendingCount))", isOn: viewModel.filter == .pending) {
                    viewModel.filter = .pending
                }
                FilterPill(title: "Scheduled (\(viewModel.scheduledCount))", isOn: viewModel.filter == .scheduled) {
                    viewModel.filter = .scheduled
                }
                FilterPill(title: "Completed (\(viewModel.completedCount))", isOn: viewModel.filter == .completed) {
                    viewModel.filter = .completed
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var ticketList: some View {
        if viewModel.filteredTickets.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text("No tickets here yet")
                    .font(.headline)
                Text("When a technician can't resolve an issue in the field, they'll escalate it here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(viewModel.filteredTickets) { ticket in
                    NavigationLink {
                        TicketDetailView(ticket: ticket, viewModel: viewModel)
                    } label: {
                        TicketRow(ticket: ticket)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct FilterPill: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isOn ? PoolDuckTheme.deepTeal : PoolDuckTheme.surfaceMuted)
                )
                .foregroundStyle(isOn ? .white : PoolDuckTheme.inkBlack)
        }
    }
}

private struct TicketRow: View {
    let ticket: EscalationTicket

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: ticket.problem.systemIcon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(PoolDuckTheme.deepTeal))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(ticket.customer.name).font(.headline)
                    Spacer()
                    StatusBadge(status: ticket.status)
                }
                Text(ticket.problem.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(ticket.summary)
                    .font(.footnote)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Label("\(ticket.attachmentFilenames.count)", systemImage: "photo.stack")
                    Label(ticket.submittedAt.formatted(.relative(presentation: .named)), systemImage: "clock")
                    if let scheduled = ticket.scheduledFor {
                        Label(scheduled.formatted(date: .abbreviated, time: .shortened),
                              systemImage: "calendar")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: EscalationTicket.Status

    var body: some View {
        Text(status.display)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(background, in: Capsule())
            .foregroundStyle(.white)
    }

    private var background: Color {
        switch status {
        case .pending: return .orange
        case .scheduled: return PoolDuckTheme.deepTeal
        case .completed: return PoolDuckTheme.duckGreen
        }
    }
}
