import SwiftUI

@main
struct AskTheDuckApp: App {
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .preferredColorScheme(.light)
                .tint(PoolDuckTheme.teal)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            if let tech = auth.technician {
                switch tech.role {
                case .admin:
                    AdminPanelView()
                case .technician:
                    HomeView()
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: auth.isSignedIn)
    }
}
