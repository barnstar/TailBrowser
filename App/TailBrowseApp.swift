//
//  TailBrowseApp.swift
//  TailBrowse
//
//  Created by Jonathan Nobels on 2025-12-16.
//

import SwiftUI
import SwiftData
import TailscaleKit

@main
struct TailBrowseApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State var manager = TSNetManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bookmark.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView(manager: manager)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                manager.willEnterBackground()
            case .active:
                manager.willEnterForeground()
            @unknown default:
                break
            }
        }
    }
}
