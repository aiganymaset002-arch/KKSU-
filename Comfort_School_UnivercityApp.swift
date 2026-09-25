//
//  Comfort_School_UnivercityApp.swift
//  Comfort School-Univercity
//
//  Created by MacBook on 20.08.2026.
//

import SwiftUI
import SwiftData

@main
struct Comfort_School_UnivercityApp: App {
    /// Единое хранилище KKSU Online (все 100 модулей платформы).
    @StateObject private var store = KKSUStore()
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
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
            KKSURootView()
                .environmentObject(store)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.saveNow() }
        }
    }
}
