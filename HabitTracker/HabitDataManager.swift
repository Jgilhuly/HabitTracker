//
//  HabitDataManager.swift
//  HabitTracker
//
//  Created by John Gilhuly on 8/12/25.
//

import CoreData
import Foundation
import Combine

class HabitDataManager: ObservableObject {
    private let container: NSPersistentContainer
    
    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }
    
    private var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    // MARK: - Habit CRUD Operations
    
    /// Create a new habit
    func createHabit(name: String, description: String?, frequency: String, isActive: Bool, category: HabitCategory?) -> Habit {
        let habit = Habit(context: context)
        habit.name = name
        habit.descriptionText = description
        habit.frequency = frequency
        habit.isActive = isActive
        habit.createdDate = Date()
        habit.category_relationship = category
        
        saveContext()
        return habit
    }
    
    /// Fetch all habits
    func fetchAllHabits() -> [Habit] {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.createdDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching habits: \(error)")
            return []
        }
    }
    
    /// Fetch active habits
    func fetchActiveHabits() -> [Habit] {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.createdDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching active habits: \(error)")
            return []
        }
    }
    
    /// Update a habit
    func updateHabit(_ habit: Habit, name: String?, description: String?, frequency: String?, isActive: Bool?, category: HabitCategory?) {
        if let name = name { habit.name = name }
        if let description = description { habit.descriptionText = description }
        if let frequency = frequency { habit.frequency = frequency }
        if let isActive = isActive { habit.isActive = isActive }
        if let category = category { habit.category_relationship = category }
        
        saveContext()
    }
    
    /// Delete a habit
    func deleteHabit(_ habit: Habit) {
        context.delete(habit)
        saveContext()
    }
    
    // MARK: - HabitCategory CRUD Operations
    
    /// Create a new habit category
    func createHabitCategory(name: String, color: String?) -> HabitCategory {
        let category = HabitCategory(context: context)
        category.name = name
        category.color = color
        category.createdDate = Date()
        
        saveContext()
        return category
    }
    
    /// Fetch all habit categories
    func fetchAllCategories() -> [HabitCategory] {
        let request: NSFetchRequest<HabitCategory> = HabitCategory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HabitCategory.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    /// Update a category
    func updateCategory(_ category: HabitCategory, name: String?, color: String?) {
        if let name = name { category.name = name }
        if let color = color { category.color = color }
        
        saveContext()
    }
    
    /// Delete a category
    func deleteCategory(_ category: HabitCategory) {
        context.delete(category)
        saveContext()
    }
    
    // MARK: - HabitCompletion CRUD Operations
    
    /// Create a habit completion
    func createHabitCompletion(for habit: Habit, date: Date = Date(), notes: String?) -> HabitCompletion {
        let completion = HabitCompletion(context: context)
        completion.habit = habit
        completion.completionDate = date
        completion.notes = notes
        
        saveContext()
        return completion
    }
    
    /// Fetch completions for a specific habit
    func fetchCompletions(for habit: Habit) -> [HabitCompletion] {
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(format: "habit == %@", habit)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HabitCompletion.completionDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching completions: \(error)")
            return []
        }
    }
    
    /// Fetch completions for a specific date range
    func fetchCompletions(from startDate: Date, to endDate: Date) -> [HabitCompletion] {
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(format: "completionDate >= %@ AND completionDate <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HabitCompletion.completionDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching completions for date range: \(error)")
            return []
        }
    }
    
    /// Check if habit was completed on a specific date
    func isHabitCompleted(_ habit: Habit, on date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(format: "habit == %@ AND completionDate >= %@ AND completionDate < %@", 
                                       habit, startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Error checking habit completion: \(error)")
            return false
        }
    }

    /// Find the completion for a habit on a specific date, if any
    func findCompletion(for habit: Habit, on date: Date) -> HabitCompletion? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(format: "habit == %@ AND completionDate >= %@ AND completionDate < %@",
                                        habit, startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error finding habit completion: \(error)")
            return nil
        }
    }

    /// Set completion state for a habit on a specific date
    func setCompletion(for habit: Habit, on date: Date, completed: Bool) {
        if completed {
            if findCompletion(for: habit, on: date) == nil {
                _ = createHabitCompletion(for: habit, date: date, notes: nil)
            }
        } else {
            if let completion = findCompletion(for: habit, on: date) {
                deleteCompletion(completion)
            }
        }
    }
    
    /// Update a completion
    func updateCompletion(_ completion: HabitCompletion, date: Date?, notes: String?) {
        if let date = date { completion.completionDate = date }
        if let notes = notes { completion.notes = notes }
        
        saveContext()
    }
    
    /// Delete a completion
    func deleteCompletion(_ completion: HabitCompletion) {
        context.delete(completion)
        saveContext()
    }
    
    // MARK: - Analytics & Statistics
    
    /// Get completion streak for a habit
    func getCompletionStreak(for habit: Habit) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var currentDate = today
        var streak = 0
        
        while true {
            if isHabitCompleted(habit, on: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    /// Get completion percentage for a habit in the last N days
    func getCompletionPercentage(for habit: Habit, days: Int) -> Double {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        let completions = fetchCompletions(from: startDate, to: endDate).filter { $0.habit == habit }
        return Double(completions.count) / Double(days) * 100.0
    }
    
    // MARK: - Core Data Management
    
    /// Save the managed object context
    private func saveContext() {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Error saving context: \(error)")
            // In a real app, you might want to show an alert to the user
        }
    }
    
    /// Delete all data (useful for testing)
    func deleteAllData() {
        let entities = ["Habit", "HabitCategory", "HabitCompletion"]
        
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Error deleting \(entity): \(error)")
            }
        }
        
        saveContext()
    }
}