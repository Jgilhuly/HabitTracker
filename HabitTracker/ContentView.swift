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
    @State private var selectedCategoryFilter: HabitCategory?
    @State private var availableCategories: [HabitCategory] = []
    @State private var selectedDateForMarking: Date = Date()
    
    private var filteredHabits: [Habit] {
        if let selected = selectedCategoryFilter {
            return habits.filter { $0.category_relationship == selected }
        }
        return habits
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category filter chips
                if !availableCategories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button(action: { selectedCategoryFilter = nil }) {
                                Text("All")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedCategoryFilter == nil ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundStyle(selectedCategoryFilter == nil ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            ForEach(availableCategories, id: \.objectID) { category in
                                Button(action: {
                                    selectedCategoryFilter = selectedCategoryFilter == category ? nil : category
                                }) {
                                    Text(category.name ?? "Unknown")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedCategoryFilter == category ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundStyle(selectedCategoryFilter == category ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundStyle(Color(.separator)), alignment: .bottom
                    )
                }
                
                // Date selector for inline completion marking
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text("Mark for:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    DatePicker("Mark for", selection: $selectedDateForMarking, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color(.separator)), alignment: .bottom
                )

                // Main content
                if filteredHabits.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: habits.isEmpty ? "checkmark.circle" : "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.tint)
                        Text(habits.isEmpty ? "Welcome to HabitTracker!" : "No habits found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(habits.isEmpty ? "Start building better habits today" : "Try adjusting your category filter or add a new habit")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        if habits.isEmpty {
                            Button("Add Your First Habit") { showingAddHabit = true }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button("Clear Filter") { selectedCategoryFilter = nil }
                                .buttonStyle(.bordered)
                        }
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredHabits, id: \.objectID) { habit in
                            HabitRowView(habit: habit, dataManager: dataManager, selectedDate: selectedDateForMarking)
                                .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete(perform: deleteHabits)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Habit")
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(dataManager: dataManager) {
                    loadHabits()
                    loadCategories()
                }
            }
        }
        .onAppear {
            loadHabits()
            loadCategories()
        }
    }
    
    private func loadHabits() {
        habits = dataManager.fetchActiveHabits()
    }
    
    private func loadCategories() {
        availableCategories = dataManager.fetchAllCategories()
    }
    
    private func deleteHabits(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredHabits[$0] }.forEach(dataManager.deleteHabit)
            loadHabits()
        }
    }
}

struct HabitRowView: View {
    let habit: Habit
    let dataManager: HabitDataManager
    let selectedDate: Date
    @State private var isCompleted = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { toggleCompletion() }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name ?? "Unknown Habit")
                    .font(.headline)
                    .lineLimit(1)
                if let description = habit.descriptionText, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 8) {
                    Text(habit.frequency?.capitalized ?? "Daily")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    if let category = habit.category_relationship {
                        Text(category.name ?? "")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
            NavigationLink(destination: HabitDetailView(habit: habit, dataManager: dataManager)) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 6)
        .onAppear { refreshCompletionState() }
        .onChange(of: selectedDate, initial: false) {
            refreshCompletionState()
        }
    }
    
    private func refreshCompletionState() {
        let startOfSelected = Calendar.current.startOfDay(for: selectedDate)
        isCompleted = dataManager.isHabitCompleted(habit, on: startOfSelected)
    }
    
    private func toggleCompletion() {
        let newValue = !isCompleted
        let dateToSet = Calendar.current.startOfDay(for: selectedDate)
        dataManager.setCompletion(for: habit, on: dateToSet, completed: newValue)
        withAnimation(.easeInOut(duration: 0.2)) { isCompleted = newValue }
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
    @State private var isActive: Bool = true
    @State private var newCategoryName: String = ""
    
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
                    .pickerStyle(.segmented)
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
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("New Category Name", text: $newCategoryName)
                        Button("Add Category") {
                            let created = dataManager.createHabitCategory(name: newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines), color: nil)
                            categories.append(created)
                            selectedCategory = created
                            newCategoryName = ""
                        }
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                Section("Status") {
                    Toggle("Active", isOn: $isActive)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveHabit() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear { loadCategories() }
    }
    
    private func loadCategories() { categories = dataManager.fetchAllCategories() }
    private func createSampleCategory() {
        let category = dataManager.createHabitCategory(name: "Health", color: "blue")
        categories.append(category)
    }
    private func saveHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = dataManager.createHabit(
            name: trimmedName,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            frequency: frequency,
            isActive: isActive,
            category: selectedCategory
        )
        onSave()
        dismiss()
    }
}

// MARK: - Habit Detail View
struct HabitDetailView: View {
    let habit: Habit
    let dataManager: HabitDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedDate: Date = Date()
    @State private var selectedDateCompleted: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(habit.name ?? "Unknown Habit")
                            .font(.largeTitle).bold()
                        if let description = habit.descriptionText, !description.isEmpty {
                            Text(description)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 8) {
                            Text(habit.frequency?.capitalized ?? "Daily")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.2))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                            if let category = habit.category_relationship {
                                Text(category.name ?? "")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    Spacer()
                    Button { showingEditSheet = true } label: {
                        Image(systemName: "pencil")
                            .font(.title2)
                    }
                }
                
                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Statistics").font(.headline)
                    HStack(spacing: 16) {
                        StatCard(title: "Current Streak", value: String(dataManager.getCompletionStreak(for: habit)), icon: "flame.fill", color: .orange)
                        StatCard(title: "This Week", value: "\(Int(dataManager.getCompletionPercentage(for: habit, days: 7)))%", icon: "chart.bar.fill", color: .blue)
                    }
                }
                
                // Recent completions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Completions").font(.headline)
                    let completions = dataManager.fetchCompletions(for: habit).prefix(5)
                    if completions.isEmpty {
                        Text("No completions yet").foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(completions), id: \.objectID) { completion in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                    Text(completion.completionDate?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown Date")
                                    Spacer()
                                    if let notes = completion.notes, !notes.isEmpty { Text(notes).font(.caption).foregroundStyle(.secondary) }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                // Mark past dates
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mark Completion by Date").font(.headline)
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .onChange(of: selectedDate, initial: false) {
                            refreshSelectedDateState()
                        }
                    Toggle(isOn: $selectedDateCompleted) {
                        Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    .onChange(of: selectedDateCompleted, initial: false) {
                        dataManager.setCompletion(for: habit, on: selectedDate, completed: selectedDateCompleted)
                    }
                    Text("Tip: Use this to backfill or correct past days.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Delete") { showingDeleteAlert = true }.foregroundStyle(.red)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditHabitView(habit: habit, dataManager: dataManager)
        }
        .alert("Delete Habit", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dataManager.deleteHabit(habit)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this habit? This action cannot be undone.")
        }
        .onAppear { refreshSelectedDateState() }
    }
}

private extension HabitDetailView {
    func refreshSelectedDateState() {
        selectedDateCompleted = dataManager.isHabitCompleted(habit, on: Calendar.current.startOfDay(for: selectedDate))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(color).font(.title2)
            Text(value).font(.title2).bold()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EditHabitView: View {
    let habit: Habit
    let dataManager: HabitDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var frequency: String
    @State private var categories: [HabitCategory] = []
    @State private var selectedCategory: HabitCategory?
    @State private var isActive: Bool
    @State private var newCategoryName: String = ""
    let frequencies = ["daily", "weekly"]
    
    init(habit: Habit, dataManager: HabitDataManager) {
        self.habit = habit
        self.dataManager = dataManager
        _name = State(initialValue: habit.name ?? "")
        _description = State(initialValue: habit.descriptionText ?? "")
        _frequency = State(initialValue: habit.frequency ?? "daily")
        _selectedCategory = State(initialValue: habit.category_relationship)
        _isActive = State(initialValue: habit.isActive)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Habit Details") {
                    TextField("Habit Name", text: $name)
                    TextField("Description (optional)", text: $description)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in Text(freq.capitalized).tag(freq) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Category") {
                    if categories.isEmpty {
                        Text("No categories available").foregroundStyle(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategory) {
                            Text("None").tag(nil as HabitCategory?)
                            ForEach(categories, id: \.objectID) { category in
                                Text(category.name ?? "Unknown").tag(category as HabitCategory?)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("New Category Name", text: $newCategoryName)
                        Button("Add Category") {
                            let created = dataManager.createHabitCategory(name: newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines), color: nil)
                            categories.append(created)
                            selectedCategory = created
                            newCategoryName = ""
                        }
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                Section("Status") {
                    Toggle("Active", isOn: $isActive)
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveHabit() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear { loadCategories() }
    }
    
    private func loadCategories() { categories = dataManager.fetchAllCategories() }
    private func saveHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        dataManager.updateHabit(
            habit,
            name: trimmedName,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            frequency: frequency,
            isActive: isActive,
            category: selectedCategory
        )
        dismiss()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
