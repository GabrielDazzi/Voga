import Foundation
import Combine
import SwiftUI

class TripViewModel: ObservableObject {
    
    @Published var trips: [Trip] = [] {
        didSet {
            saveTrips()
        }
    }
    
    private let iCloudKey = "savedTripsList_iCloud"
    
    var activeTrips: [Trip] {
        trips.filter { !$0.isCompleted }
    }
    
    var completedTrips: [Trip] {
        trips.filter { $0.isCompleted }
    }
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(iCloudDataDidChange),
                                               name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: NSUbiquitousKeyValueStore.default)
        
        NSUbiquitousKeyValueStore.default.synchronize()
        loadTrips()
    }
    
    @objc func iCloudDataDidChange(_ notification: Notification) {
        print("iCloud data changed externally. Reloading trips.")
        loadTrips()
    }
    
    func addTrip(destination: String, startDate: Date, endDate: Date, budget: Double, currency: Currency) {
        let newTrip = Trip(destination: destination, startDate: startDate, endDate: endDate, totalBudget: budget, currency: currency)
        trips.append(newTrip)
    }
    
    func updateTrip(tripId: UUID, newStartDate: Date, newEndDate: Date, newBudget: Double) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[index].startDate = newStartDate
        trips[index].endDate = newEndDate
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
            NSUbiquitousKeyValueStore.default.set(tripsData, forKey: iCloudKey)
            NSUbiquitousKeyValueStore.default.synchronize()
            print("Trips saved to iCloud.")
        }
    }
    
    private func loadTrips() {
        if let tripsData = NSUbiquitousKeyValueStore.default.data(forKey: iCloudKey),
           let savedTrips = try? JSONDecoder().decode([Trip].self, from: tripsData) {
            DispatchQueue.main.async {
                self.trips = savedTrips
                print("Trips loaded from iCloud.")
            }
        } else {
            print("No trips found in iCloud or failed to decode.")
        }
    }
}
