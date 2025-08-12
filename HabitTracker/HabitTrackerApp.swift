//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Created by John Gilhuly on 8/12/25.
//

import SwiftUI

@main
struct HabitTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
