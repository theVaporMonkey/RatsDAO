import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @FocusState private var focus: Field?
    private enum Field { case email, password }

    var body: some View {
        ZStack {
            PoolDuckTheme.gradient()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    DuckLogo(size: 140)
                        .padding(.top, 40)

                    VStack(spacing: 6) {
                        Text("ASK THE DUCK")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .tracking(2)
                        Text("Crystal clear pools aren't luck,\nthey're cleaned by Pool Duck.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(PoolDuckTheme.cream)
                    }

                    VStack(spacing: 14) {
                        TextField("Technician email", text: $auth.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .textContentType(.username)
                            .focused($focus, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focus = .password }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        SecureField("Password", text: $auth.password)
                            .textContentType(.password)
                            .focused($focus, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { Task { await auth.signIn() } }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if let error = auth.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.white)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.red.opacity(0.85))
                                )
                        }

                        Button {
                            Task { await auth.signIn() }
                        } label: {
                            if auth.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign in")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(auth.isLoading)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal, 20)

                    Text("Pool Duck Franchising\u{2122}")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.bottom, 24)
                }
            }
        }
    }
}

#Preview {
    LoginView().environmentObject(AuthViewModel())
}
