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
                    DashboardView(client: client)
                } label: {
                    Label("홈", systemImage: "house")
                }
                NavigationLink {
                    TodayView(client: client)
                } label: {
                    Label("Today", systemImage: "sun.max")
                }
                NavigationLink {
                    CalendarView(client: client)
                } label: {
                    Label("달력", systemImage: "calendar")
                }
                NavigationLink {
                    InboxListView(client: client)
                } label: {
                    Label("Inbox", systemImage: "tray.full")
                }
                NavigationLink {
                    ProjectsView(client: client)
                } label: {
                    Label("프로젝트", systemImage: "folder")
                }
                NavigationLink { MoreView(client: client) } label: { Label("기록과 설정", systemImage: "ellipsis.circle") }
                NavigationLink { HealthView(client: client) } label: { Label("건강", systemImage: "heart") }
            }
            .navigationTitle("LifeOS")
        } detail: {
            DashboardView(client: client)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("로그아웃", systemImage: "rectangle.portrait.and.arrow.right") {
                    Task { await sessionStore.signOut() }
                }
            }
        }
        #else
        TabView {
            NavigationStack {
                DashboardView(client: client)
                    .toolbar { logoutToolbar }
            }
            .tabItem { Label("홈", systemImage: "house") }

            NavigationStack { TodayView(client: client).toolbar { logoutToolbar } }
                .tabItem { Label("오늘", systemImage: "sun.max") }

            NavigationStack { CalendarView(client: client).toolbar { logoutToolbar } }
                .tabItem { Label("달력", systemImage: "calendar") }

            NavigationStack {
                ProjectsView(client: client)
                    .toolbar { logoutToolbar }
            }
            .tabItem { Label("프로젝트", systemImage: "folder") }

            NavigationStack { MoreView(client: client).toolbar { logoutToolbar } }
                .tabItem { Label("더보기", systemImage: "ellipsis.circle") }

        }
        #endif
    }

    #if os(iOS)
    @ToolbarContentBuilder
    private var logoutToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("로그아웃", systemImage: "rectangle.portrait.and.arrow.right") {
                Task { await sessionStore.signOut() }
            }
        }
    }
    #endif
}
