import SwiftUI

@main
struct LifeOSApp: App {
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            LifeOSRootView()
                .environmentObject(sessionStore)
        }
    }
}
