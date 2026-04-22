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
            if auth.isSignedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: auth.isSignedIn)
    }
}
