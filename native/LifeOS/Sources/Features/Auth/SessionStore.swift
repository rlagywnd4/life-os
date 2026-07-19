import Foundation
import Supabase

enum LoginFailureMessage {
    static func make(from error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
            case .timedOut:
                return "Supabase 응답 시간이 초과됐습니다. 인터넷 연결을 확인한 뒤 다시 시도해 주세요."
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .secureConnectionFailed:
                return "Supabase 서버에 연결하지 못했습니다. URL과 publishable key 설정을 확인해 주세요."
            default:
                return "네트워크 오류로 로그인하지 못했습니다. 연결 상태를 확인해 주세요."
            }
        }

        if case let .api(message, errorCode, _, response) = error as? AuthError {
            switch errorCode {
            case .invalidCredentials, .userNotFound:
                return "이메일 또는 비밀번호가 맞지 않습니다."
            case .emailNotConfirmed:
                return "이메일 인증이 완료되지 않았습니다. 기존 LifeOS 계정의 인증 메일을 확인해 주세요."
            case .emailProviderDisabled:
                return "Supabase에서 이메일 로그인이 비활성화되어 있습니다."
            case .overRequestRateLimit, .overEmailSendRateLimit:
                return "로그인 시도가 너무 많습니다. 잠시 후 다시 시도해 주세요."
            default:
                let normalizedMessage = message.lowercased()
                if normalizedMessage.contains("api key") || normalizedMessage.contains("apikey") {
                    return "Supabase publishable key가 현재 프로젝트와 맞지 않습니다. Secrets.xcconfig 설정을 확인해 주세요."
                }
                if response.statusCode >= 500 {
                    return "Supabase 인증 서버에 일시적인 문제가 있습니다. 잠시 후 다시 시도해 주세요."
                }
                return "Supabase가 로그인 요청을 처리하지 못했습니다. URL·publishable key·계정 상태를 확인해 주세요."
            }
        }

        return "알 수 없는 오류로 로그인하지 못했습니다. 인터넷 연결과 Supabase 설정을 확인해 주세요."
    }
}

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
            signInError = LoginFailureMessage.make(from: error)
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
