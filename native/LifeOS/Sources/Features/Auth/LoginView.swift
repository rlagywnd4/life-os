import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 42))
                    .foregroundStyle(.tint)
                Text("LifeOS")
                    .font(.largeTitle.bold())
                Text("기존 LifeOS 계정으로 로그인하세요.")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                if sessionStore.hasConfiguredPersonalAccount {
                    Button {
                        Task { await sessionStore.signInUsingConfiguredPersonalAccount() }
                    } label: {
                        if sessionStore.isSigningIn {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("내 계정으로 로그인", systemImage: "person.crop.circle.badge.checkmark")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(sessionStore.isSigningIn)

                    Divider()
                    Text("또는 직접 로그인")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                #if os(iOS)
                TextField("이메일", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                #else
                TextField("이메일", text: $email)
                    .textContentType(.emailAddress)
                    .textFieldStyle(.roundedBorder)
                #endif

                SecureField("비밀번호", text: $password)
                    .textContentType(.password)
                    .textFieldStyle(.roundedBorder)

                if let error = sessionStore.signInError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await sessionStore.signIn(email: email, password: password) }
                } label: {
                    if sessionStore.isSigningIn {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("로그인")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty || sessionStore.isSigningIn)
            }
            .frame(maxWidth: 360)
        }
        .padding(24)
    }
}
