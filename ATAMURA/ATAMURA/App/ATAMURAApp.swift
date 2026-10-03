//
//  ATAMURAApp.swift
//  ATA MURA — Digital Heritage & Innovation Platform
//
//  История Казахстана → человек → идея → исследование → изобретение → будущее.
//  Heritage creates innovation.
//

import SwiftUI

@main
struct ATAMURAApp: App {
    @StateObject private var store = AMStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AMRootView()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.saveNow() }
        }
    }
}
