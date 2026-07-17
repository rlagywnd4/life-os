import Supabase
import SwiftUI

struct LifeOSMainView: View {
    let client: SupabaseClient

    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List {
                NavigationLink {
                    InboxListView(client: client)
                } label: {
                    Label("Inbox", systemImage: "tray.full")
                }
            }
            .navigationTitle("LifeOS")
        } detail: {
            InboxListView(client: client)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("로그아웃", systemImage: "rectangle.portrait.and.arrow.right") {
                    Task { await sessionStore.signOut() }
                }
            }
        }
        #else
        NavigationStack {
            InboxListView(client: client)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("로그아웃", systemImage: "rectangle.portrait.and.arrow.right") {
                            Task { await sessionStore.signOut() }
                        }
                    }
                }
        }
        #endif
    }
}
