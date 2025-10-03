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
    
    func updateTrip(tripId: UUID, newDuration: Int, newBudget: Double) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[index].durationInDays = newDuration
        trips[index].totalBudget = newBudget
    }
    
    func addExpense(to tripId: UUID, description: String, amount: Double, category: BudgetCategory, date: Date) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else { return }
        let newExpense = Expense(description: description, amount: amount, category: category, date: date)
        trips[index].expenses.append(newExpense)
    }
    
    func deleteExpense(_ expenseToDelete: Expense, from tripId: UUID) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[tripIndex].expenses.removeAll { $0.id == expenseToDelete.id }
    }
    
    func markTripAsCompleted(_ trip: Trip) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[index].isCompleted = true
    }
    
    func deleteTrip(_ tripToDelete: Trip) {
        trips.removeAll { $0.id == tripToDelete.id }
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
