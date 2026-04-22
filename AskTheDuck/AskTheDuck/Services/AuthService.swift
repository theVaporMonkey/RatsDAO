import Foundation

/// Placeholder auth backend. Swap for Firebase Auth, Cognito, or the Pool
/// Duck franchise portal when integrating. The contract is intentionally
/// tiny so it's trivial to replace.
protocol AuthBackend {
    func signIn(email: String, password: String) async throws -> Technician
    func signOut() async
}

struct MockAuthBackend: AuthBackend {
    func signIn(email: String, password: String) async throws -> Technician {
        guard email.contains("@"), password.count >= 4 else {
            throw NSError(
                domain: "AskTheDuck.Auth",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Invalid email or password"]
            )
        }
        try? await Task.sleep(nanoseconds: 400_000_000)
        return Technician(
            id: UUID().uuidString,
            name: email.split(separator: "@").first.map(String.init) ?? "Technician",
            franchiseLocation: "Pool Duck HQ",
            email: email
        )
    }

    func signOut() async {}
}
