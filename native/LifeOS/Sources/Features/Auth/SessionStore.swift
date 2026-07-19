import Foundation
import Supabase

@MainActor
final class SessionStore: ObservableObject {
    enum State: Equatable {
        case loading
        case configurationError(String)
        case signedOut
        case signedIn(email: String?)
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var signInError: String?
    @Published private(set) var isSigningIn = false

    let client: SupabaseClient?
    private let personalAccountCredentials: PersonalAccountCredentials?

    var hasConfiguredPersonalAccount: Bool {
        personalAccountCredentials != nil
    }

    init() {
        personalAccountCredentials = PersonalAccountCredentials.load()

        do {
            client = try SupabaseConfiguration.makeClient()
        } catch {
            client = nil
            state = .configurationError(error.localizedDescription)
        }
    }

    func restoreSession() async {
        guard let client else { return }

        do {
            let session = try await client.auth.session
            state = .signedIn(email: session.user.email)
        } catch {
            state = .signedOut
        }
    }

    func signIn(email: String, password: String) async {
        guard let client else { return }

        isSigningIn = true
        signInError = nil
        defer { isSigningIn = false }

        do {
            try await client.auth.signIn(email: email, password: password)
            let session = try await client.auth.session
            state = .signedIn(email: session.user.email)
        } catch {
            signInError = "로그인하지 못했습니다. 이메일과 비밀번호를 다시 확인하세요."
        }
    }

    func signInUsingConfiguredPersonalAccount() async {
        guard let personalAccountCredentials else {
            signInError = "개인 계정 설정이 없습니다. Secrets.xcconfig에 이메일과 비밀번호를 입력해 주세요."
            return
        }

        await signIn(
            email: personalAccountCredentials.email,
            password: personalAccountCredentials.password
        )
    }

    func signOut() async {
        guard let client else { return }

        do {
            try await client.auth.signOut()
        } catch {
            // The local state should still leave the protected area after a failed remote sign-out.
        }

        signInError = nil
        state = .signedOut
    }
}
