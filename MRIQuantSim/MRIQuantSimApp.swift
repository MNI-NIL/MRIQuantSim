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
            // First try to create the container normally
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If regular creation fails, try to find and delete the old store file
            print("Failed to create ModelContainer: \(error). Attempting recovery...")
            
            // Get default store URL - check both container and non-container locations
            var storeURL: URL?
            
            // First try the container path (sandboxed)
            if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "net.endoquant.MRIQuantSim") {
                let containerStoreURL = containerURL.appendingPathComponent("Library/Application Support/default.store")
                if FileManager.default.fileExists(atPath: containerStoreURL.path) {
                    storeURL = containerStoreURL
                    print("Found store in container at: \(containerStoreURL.path)")
                }
            }
            
            // If not found in container, try regular application support directory
            if storeURL == nil, let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let appSupportStoreURL = applicationSupportURL.appendingPathComponent("default.store")
                if FileManager.default.fileExists(atPath: appSupportStoreURL.path) {
                    storeURL = appSupportStoreURL
                    print("Found store in application support at: \(appSupportStoreURL.path)")
                }
            }
            
            // If we found a store URL, delete it to start fresh
            if let storeURL = storeURL {
                do {
                    // Delete the file
                    try FileManager.default.removeItem(at: storeURL)
                    print("Deleted existing store file at: \(storeURL.path)")
                    
                    // Now try to create a fresh container
                    return try ModelContainer(for: schema, configurations: [modelConfiguration])
                } catch let deleteError {
                    print("Failed to delete store file: \(deleteError)")
                }
            }
            
            // If we get here, all recovery attempts failed
            fatalError("Could not create ModelContainer after recovery attempt: \(error)")
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
                // Set default window size appropriate for a MacBook Air with extra space for charts
                .frame(minWidth: 1400, idealWidth: 1450, maxWidth: .infinity,
                       minHeight: 800, idealHeight: 840, maxHeight: .infinity)
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
