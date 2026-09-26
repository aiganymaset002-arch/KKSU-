//
//  Comfort_School_UnivercityApp.swift
//  Comfort School-Univercity
//
//  Created by MacBook on 20.08.2026.
//

import SwiftUI

@main
struct Comfort_School_UnivercityApp: App {
    /// Единое хранилище KKSU Online (все модули платформы).
    @StateObject private var store = KKSUStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            KKSURootView()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.saveNow() }
        }
    }
}
