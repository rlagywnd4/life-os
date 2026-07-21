import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    @State private var email = ""
    @State private var password = ""
    @State private var authMode: AuthMode?

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

                HStack {
                    Button("회원가입") { authMode = .signUp }
                    Spacer()
                    Button("비밀번호 찾기") { authMode = .forgotPassword }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)

                if let message = sessionStore.authMessage {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 360)
        }
        .padding(24)
        .sheet(item: $authMode) { mode in
            NavigationStack { AuthSupportView(mode: mode) }
        }
    }
}

enum AuthMode: String, Identifiable {
    case signUp
    case forgotPassword
    var id: Self { self }
}

private struct AuthSupportView: View {
    let mode: AuthMode
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        Form {
            TextField("이메일", text: $email)
            #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
            #endif
            if mode == .signUp { SecureField("비밀번호 (6자 이상)", text: $password) }
            if let error = sessionStore.signInError { Text(error).foregroundStyle(.red) }
            if let message = sessionStore.authMessage { Text(message).foregroundStyle(.secondary) }
        }
        .navigationTitle(mode == .signUp ? "회원가입" : "비밀번호 찾기")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(mode == .signUp ? "가입" : "메일 보내기") {
                    Task {
                        let success = mode == .signUp
                            ? await sessionStore.signUp(email: email, password: password)
                            : await sessionStore.sendPasswordReset(email: email)
                        if success { dismiss() }
                    }
                }
                .disabled(email.isEmpty || (mode == .signUp && password.count < 6) || sessionStore.isSigningIn)
            }
        }
    }
}

struct PasswordResetView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var password = ""
    @State private var confirmation = ""

    var body: some View {
        NavigationStack {
            Form {
                SecureField("새 비밀번호", text: $password)
                SecureField("새 비밀번호 확인", text: $confirmation)
                if !confirmation.isEmpty && password != confirmation { Text("비밀번호가 서로 다릅니다.").foregroundStyle(.red) }
                if let error = sessionStore.signInError { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("비밀번호 재설정")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("변경") { Task { _ = await sessionStore.updatePassword(password) } }
                        .disabled(password.count < 6 || password != confirmation || sessionStore.isSigningIn)
                }
            }
        }
    }
}
