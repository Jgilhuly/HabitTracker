//
//  ContentView.swift
//  HabitTracker
//
//  Created by John Gilhuly on 8/12/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var dataManager = HabitDataManager()
    @State private var habits: [Habit] = []
    @State private var showingAddHabit = false
    
    var body: some View {
        NavigationView {
            VStack {
                if habits.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.tint)
                        
                        Text("Welcome to HabitTracker!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start building better habits today")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Button("Add Your First Habit") {
                            showingAddHabit = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(habits, id: \.objectID) { habit in
                            HabitRowView(habit: habit, dataManager: dataManager)
                        }
                        .onDelete(perform: deleteHabits)
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Habit") {
                        showingAddHabit = true
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(dataManager: dataManager) {
                    loadHabits()
                }
            }
        }
        .onAppear {
            loadHabits()
        }
    }
    
    private func loadHabits() {
        habits = dataManager.fetchActiveHabits()
    }
    
    private func deleteHabits(offsets: IndexSet) {
        withAnimation {
            offsets.map { habits[$0] }.forEach(dataManager.deleteHabit)
            loadHabits()
        }
    }
}

struct HabitRowView: View {
    let habit: Habit
    let dataManager: HabitDataManager
    @State private var isCompleted = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name ?? "Unknown Habit")
                    .font(.headline)
                
                if let description = habit.descriptionText, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text(habit.frequency?.capitalized ?? "Daily")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    
                    if let category = habit.category_relationship {
                        Text(category.name ?? "")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                toggleCompletion()
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .gray)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            checkTodaysCompletion()
        }
    }
    
    private func checkTodaysCompletion() {
        isCompleted = dataManager.isHabitCompleted(habit, on: Date())
    }
    
    private func toggleCompletion() {
        if isCompleted {
            // Find and delete today's completion
            let completions = dataManager.fetchCompletions(for: habit)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            if let todayCompletion = completions.first(where: { completion in
                calendar.isDate(completion.completionDate ?? Date(), inSameDayAs: today)
            }) {
                dataManager.deleteCompletion(todayCompletion)
            }
        } else {
            // Create a new completion for today
            dataManager.createHabitCompletion(for: habit, notes: nil)
        }
        
        withAnimation {
            isCompleted.toggle()
        }
    }
}

struct AddHabitView: View {
    let dataManager: HabitDataManager
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var frequency = "daily"
    @State private var categories: [HabitCategory] = []
    @State private var selectedCategory: HabitCategory?
    
    let frequencies = ["daily", "weekly"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Habit Details") {
                    TextField("Habit Name", text: $name)
                    TextField("Description (optional)", text: $description)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            Text(freq.capitalized).tag(freq)
                        }
                    }
                }
                
                Section("Category") {
                    if categories.isEmpty {
                        Text("No categories available")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategory) {
                            Text("None").tag(nil as HabitCategory?)
                            ForEach(categories, id: \.objectID) { category in
                                Text(category.name ?? "Unknown").tag(category as HabitCategory?)
                            }
                        }
                    }
                    
                    Button("Create New Category") {
                        createSampleCategory()
                    }
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            loadCategories()
        }
    }
    
    private func loadCategories() {
        categories = dataManager.fetchAllCategories()
    }
    
    private func createSampleCategory() {
        let category = dataManager.createHabitCategory(name: "Health", color: "blue")
        categories.append(category)
    }
    
    private func saveHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        dataManager.createHabit(
            name: trimmedName,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            frequency: frequency,
            category: selectedCategory
        )
        
        onSave()
        dismiss()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
