import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var pickingProblem: ProblemType?
    @State private var activeSession: ChatSession?
    @State private var showingHistory = false
    @State private var startMode: StartMode = .troubleshoot

    enum StartMode: String, CaseIterable, Identifiable {
        case troubleshoot = "Troubleshoot"
        case quote = "Start a Quote"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .troubleshoot: return "stethoscope"
            case .quote: return "doc.text.fill"
            }
        }
    }

    struct ChatSession: Identifiable, Hashable {
        let id = UUID()
        let problem: ProblemType
        let customer: CustomerInfo
        let startWithQuote: Bool
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header

                    modeToggle

                    Text(startMode == .troubleshoot
                         ? "What are you looking at?"
                         : "What kind of job are you quoting?")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(ProblemType.allCases) { problem in
                            Button {
                                pickingProblem = problem
                            } label: {
                                ProblemTile(problem: problem)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    Text(startMode == .troubleshoot
                         ? "Ask the Duck uses photos, video stills, and your spoken description to diagnose issues on the spot — so you don't have to call the office unless you need a truck roll."
                         : "Capture the job, then let Claude draft a first-pass quote from what it sees. Pool Duck's default parts markup is 100% — adjust down only if the local market won't bear it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
                .padding(.vertical, 12)
            }
            .background(PoolDuckTheme.surface)
            .navigationDestination(item: $activeSession) { session in
                if let tech = auth.technician {
                    ChatView(
                        viewModel: {
                            let vm = ChatViewModel(
                                problem: session.problem,
                                customer: session.customer,
                                technician: tech
                            )
                            if session.startWithQuote {
                                Task { await vm.startBlankQuote() }
                            }
                            return vm
                        }()
                    )
                }
            }
            .sheet(item: $pickingProblem) { problem in
                CustomerInfoView(
                    problem: problem,
                    onContinue: { info in
                        pickingProblem = nil
                        activeSession = ChatSession(
                            problem: problem,
                            customer: info,
                            startWithQuote: startMode == .quote
                        )
                    },
                    onCancel: { pickingProblem = nil }
                )
            }
            .sheet(isPresented: $showingHistory) {
                if let tech = auth.technician {
                    HistoryView(viewModel: HistoryViewModel(technician: tech))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingHistory = true
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                            .labelStyle(.iconOnly)
                    }
                    .tint(PoolDuckTheme.deepTeal)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let tech = auth.technician {
                            Text(tech.name)
                            Text(tech.email).foregroundStyle(.secondary)
                            Divider()
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
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(PoolDuckTheme.gradient())
                HStack(spacing: 16) {
                    DuckLogo(size: 72, showsWordmark: false)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ask the Duck")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        if let tech = auth.technician {
                            Text("Welcome, \(tech.name)")
                                .font(.subheadline)
                                .foregroundStyle(PoolDuckTheme.cream)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .frame(height: 120)
            .padding(.horizontal)
        }
    }

    private var modeToggle: some View {
        Picker("Mode", selection: $startMode) {
            ForEach(StartMode.allCases) { mode in
                Label(mode.rawValue, systemImage: mode.icon).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

private struct ProblemTile: View {
    let problem: ProblemType

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: problem.systemIcon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Circle().fill(PoolDuckTheme.deepTeal))
            Text(problem.rawValue)
                .font(.headline)
                .foregroundStyle(PoolDuckTheme.inkBlack)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(PoolDuckTheme.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PoolDuckTheme.teal.opacity(0.4), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView().environmentObject(AuthViewModel())
}
