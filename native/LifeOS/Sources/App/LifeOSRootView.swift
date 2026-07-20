import SwiftUI

struct LifeOSRootView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        Group {
            switch sessionStore.state {
            case .loading:
                ProgressView("LifeOS 준비 중")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .configurationError(let message):
                ConfigurationErrorView(message: message)

            case .signedOut:
                LoginView()

            case .signedIn:
                if let client = sessionStore.client {
                    LifeOSMainView(client: client)
                } else {
                    ConfigurationErrorView(message: "Supabase 연결을 준비하지 못했습니다.")
                }
            }
        }
        .task {
            await sessionStore.restoreSession()
        }
        .onOpenURL { url in
            Task { await sessionStore.handleOpenURL(url) }
        }
        .sheet(isPresented: $sessionStore.isPasswordResetPresented) {
            PasswordResetView().environmentObject(sessionStore)
        }
    }
}

private struct ConfigurationErrorView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("연결 설정이 필요합니다", systemImage: "gear.badge.xmark")
        } description: {
            Text(message)
        } actions: {
            Text("Configuration/Secrets.xcconfig.example을 복사해 Supabase URL과 publishable key를 입력하세요.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
