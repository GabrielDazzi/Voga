import Foundation
import Combine
import SwiftUI

class TripViewModel: ObservableObject {
    
    @Published var trips: [Trip] = [] {
        didSet {
            saveTrips()
        }
    }
    
    private let userDefaultsKey = "savedTripsList"
    
    var activeTrips: [Trip] {
        trips.filter { !$0.isCompleted }
    }
    
    var completedTrips: [Trip] {
        trips.filter { $0.isCompleted }
    }
    
    init() {
        loadTrips()
    }
    
    func addTrip(destination: String, duration: Int, budget: Double, currency: Currency) {
        let newTrip = Trip(destination: destination, durationInDays: duration, totalBudget: budget, currency: currency)
        trips.append(newTrip)
    }
    
    func addExpense(to tripId: UUID, description: String, amount: Double, category: BudgetCategory, date: Date) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else { return }
        let newExpense = Expense(description: description, amount: amount, category: category, date: date)
        trips[index].expenses.append(newExpense)
    }
    
    func deleteExpense(from tripId: UUID, at offsets: IndexSet) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[index].expenses.remove(atOffsets: offsets)
    }
    
    func markTripAsCompleted(_ trip: Trip) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[index].isCompleted = true
    }
    
    func deleteTrip(at offsets: IndexSet, in tripList: [Trip]) {
        let idsToRemove = offsets.map { tripList[$0].id }
        trips.removeAll { idsToRemove.contains($0.id) }
    }

    private func saveTrips() {
        if let tripsData = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(tripsData, forKey: userDefaultsKey)
        }
    }
    
    private func loadTrips() {
        if let tripsData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedTrips = try? JSONDecoder().decode([Trip].self, from: tripsData) {
            self.trips = savedTrips
        }
    }
}

extension Trip {
    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var remainingBudget: Double {
        totalBudget - totalSpent
    }
    
    var dailyAverageBudget: Double {
        guard durationInDays > 0 else { return 0 }
        return totalBudget / Double(durationInDays)
    }
    
    func spent(for category: BudgetCategory) -> Double {
        expenses.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
    }
}
