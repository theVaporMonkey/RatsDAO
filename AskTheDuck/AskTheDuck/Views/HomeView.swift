import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var selectedProblem: ProblemType?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header

                    Text("What are you looking at?")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(ProblemType.allCases) { problem in
                            Button {
                                selectedProblem = problem
                            } label: {
                                ProblemTile(problem: problem)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    Text("Ask the Duck uses photos, video stills, and your spoken description to diagnose issues on the spot — so you don't have to call the office.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }
                .padding(.vertical, 12)
            }
            .background(PoolDuckTheme.surface)
            .navigationDestination(item: $selectedProblem) { problem in
                ChatView(viewModel: ChatViewModel(problem: problem))
            }
            .toolbar {
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
}

private struct ProblemTile: View {
    let problem: ProblemType

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: problem.systemIcon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    Circle().fill(PoolDuckTheme.deepTeal)
                )
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
    HomeView().environmentObject({
        let vm = AuthViewModel()
        return vm
    }())
}
