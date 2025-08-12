//
//  PersistenceController.swift
//  HabitTracker
//
//  Created by John Gilhuly on 8/12/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleCategory = HabitCategory(context: viewContext)
        sampleCategory.name = "Health"
        sampleCategory.color = "blue"
        sampleCategory.createdDate = Date()
        
        let sampleHabit = Habit(context: viewContext)
        sampleHabit.name = "Drink 8 glasses of water"
        sampleHabit.descriptionText = "Stay hydrated throughout the day"
        sampleHabit.frequency = "daily"
        sampleHabit.isActive = true
        sampleHabit.createdDate = Date()
        sampleHabit.category_relationship = sampleCategory
        
        let sampleCompletion = HabitCompletion(context: viewContext)
        sampleCompletion.completionDate = Date()
        sampleCompletion.notes = "Completed successfully"
        sampleCompletion.habit = sampleHabit
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "HabitTracker")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
                                                                forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
                                                                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // Typical reasons for an error here include:
                // * The parent directory does not exist, cannot be created, or disallows writing.
                // * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                // * The device is out of space.
                // * The store could not be migrated to the current model version.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}