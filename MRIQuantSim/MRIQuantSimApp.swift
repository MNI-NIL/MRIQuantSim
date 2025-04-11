//
//  MRIQuantSimApp.swift
//  MRIQuantSim
//
//  Created by Rick Hoge on 2025-04-10.
//

import SwiftUI
import SwiftData

@main
struct MRIQuantSimApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SimulationParameters.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // Set the "AppHasLaunchedBefore" flag after first launch
        // This will cause all CollapsibleSections to start collapsed on first launch only
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "AppHasLaunchedBefore")
        if !hasLaunchedBefore {
            // This is the first launch
            UserDefaults.standard.set(true, forKey: "AppHasLaunchedBefore")
            
            // Initialize any other first-launch settings here if needed
            print("First launch detected - initializing default settings")
        }
    }
    
    // State to control when settings window is showing
    @State private var isShowingSettings = false
    // Shared simulator controller that can be passed to both ContentView and SettingsView
    @StateObject private var simulator = SimulationController()

    var body: some Scene {
        WindowGroup {
            ContentView(simulator: simulator)
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView(onParameterChanged: simulator.parameterChanged)
                }
                // Set default window size appropriate for a MacBook Air
                .frame(minWidth: 1280, idealWidth: 1280, maxWidth: .infinity,
                       minHeight: 800, idealHeight: 800, maxHeight: .infinity)
        }
        .windowStyle(TitleBarWindowStyle())
        .windowResizability(.contentSize)
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Settings...") {
                    isShowingSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
