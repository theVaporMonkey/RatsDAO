import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var technician: Technician?

    var isSignedIn: Bool { technician != nil }

    private let backend: AuthBackend

    init(backend: AuthBackend = MockAuthBackend()) {
        self.backend = backend
    }

    func signIn() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            technician = try await backend.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        Task { await backend.signOut() }
        technician = nil
        email = ""
        password = ""
    }
}
