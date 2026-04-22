import SwiftUI
import UIKit

struct HistoryView: View {
    @StateObject var viewModel: HistoryViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Scope", selection: $viewModel.scope) {
                    ForEach(HistoryViewModel.Scope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                list
            }
            .background(PoolDuckTheme.surface)
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by customer, address, phone, or keyword"
            )
            .navigationTitle("Service History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var list: some View {
        if viewModel.results.isEmpty {
            empty
        } else {
            List {
                ForEach(viewModel.results) { record in
                    NavigationLink {
                        HistoryDetailView(
                            record: record,
                            viewModel: viewModel
                        )
                    } label: {
                        HistoryRow(record: record)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(viewModel.query.isEmpty ? "No sessions yet" : "No matches")
                .font(.headline)
            Text("Every chat session is saved here automatically. Search by customer name, address, phone, or any keyword from the conversation.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct HistoryRow: View {
    let record: ServiceRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: record.problem.systemIcon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(PoolDuckTheme.deepTeal))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.customer.name).font(.headline)
                    Spacer()
                    if record.escalatedTicketID != nil {
                        Text("Escalated")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                Text(record.customer.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(record.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 12) {
                    Label(record.problem.rawValue, systemImage: "tag")
                    Label("\(record.attachmentFilenames.count)", systemImage: "photo.stack")
                    Label(record.updatedAt.formatted(.relative(presentation: .named)),
                          systemImage: "clock")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HistoryDetailView: View {
    let record: ServiceRecord
    let viewModel: HistoryViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                if !record.attachmentFilenames.isEmpty {
                    attachmentGallery
                }
                transcriptCard
            }
            .padding()
        }
        .background(PoolDuckTheme.surface)
        .navigationTitle(record.customer.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: record.problem.systemIcon)
                    .foregroundStyle(PoolDuckTheme.deepTeal)
                Text(record.problem.rawValue).font(.headline)
                Spacer()
                Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Label(record.customer.address, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
            HStack {
                Image(systemName: "phone.fill")
                Link(record.customer.phone, destination: telURL(record.customer.phone))
            }
            .font(.subheadline)

            Divider()
            HStack {
                Image(systemName: "person.fill")
                Text("Tech: \(record.technicianName)")
                Spacer()
                if record.escalatedTicketID != nil {
                    Label("Escalated", systemImage: "tray.and.arrow.up")
                        .foregroundStyle(.orange)
                }
            }
            .font(.footnote)
        }
        .cardBackground()
    }

    private var attachmentGallery: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Captured on this visit").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(record.attachmentFilenames, id: \.self) { name in
                        let url = viewModel.attachmentURL(recordID: record.id, filename: name)
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
            ForEach(record.transcript) { message in
                TranscriptLine(message: message)
            }
        }
        .cardBackground()
    }

    private func telURL(_ phone: String) -> URL {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel://\(digits)") ?? URL(string: "about:blank")!
    }
}

private struct TranscriptLine: View {
    let message: TicketMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            if !message.text.isEmpty {
                Text(.init(message.text))
                    .font(.footnote)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(background, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(foreground)
            }
        }
    }

    private var label: String {
        switch message.role {
        case .technician: return "Technician"
        case .duck: return "Ask the Duck"
        case .system: return "System"
        }
    }

    private var background: Color {
        switch message.role {
        case .technician: return PoolDuckTheme.deepTeal
        case .duck: return PoolDuckTheme.surface
        case .system: return .clear
        }
    }

    private var foreground: Color {
        switch message.role {
        case .technician: return .white
        case .duck, .system: return PoolDuckTheme.inkBlack
        }
    }
}
