import Foundation
import Combine
import SwiftUI

class TripViewModel: ObservableObject {
    
    @Published var trips: [Trip] = [] {
        didSet {
            saveTrips()
        }
    }
    
    // 1. MUDANÇA: Usaremos uma chave específica para o iCloud
    private let iCloudKey = "savedTripsList_iCloud"
    
    var activeTrips: [Trip] {
        trips.filter { !$0.isCompleted }
    }
    
    var completedTrips: [Trip] {
        trips.filter { $0.isCompleted }
    }
    
    init() {
        // 2. MUDANÇA: Adicionar um observador para atualizações externas do iCloud
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(iCloudDataDidChange),
                                               name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: NSUbiquitousKeyValueStore.default)
        
        // 3. MUDANÇA: Sincronizar o armazenamento do iCloud ao iniciar
        NSUbiquitousKeyValueStore.default.synchronize()
        loadTrips()
    }
    
    // + ADIÇÃO: Função para lidar com notificações de mudança do iCloud
    @objc func iCloudDataDidChange(_ notification: Notification) {
        // Quando os dados mudam em outro dispositivo, recarregamos aqui.
        print("iCloud data changed externally. Reloading trips.")
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
        // 4. MUDANÇA: Salvar no NSUbiquitousKeyValueStore em vez de UserDefaults
        if let tripsData = try? JSONEncoder().encode(trips) {
            NSUbiquitousKeyValueStore.default.set(tripsData, forKey: iCloudKey)
            NSUbiquitousKeyValueStore.default.synchronize() // Inicia a sincronização
            print("Trips saved to iCloud.")
        }
    }
    
    private func loadTrips() {
        // 5. MUDANÇA: Carregar do NSUbiquitousKeyValueStore
        if let tripsData = NSUbiquitousKeyValueStore.default.data(forKey: iCloudKey),
           let savedTrips = try? JSONDecoder().decode([Trip].self, from: tripsData) {
            // Atualiza na thread principal, pois pode ser chamado por uma notificação
            DispatchQueue.main.async {
                self.trips = savedTrips
                print("Trips loaded from iCloud.")
            }
        } else {
            print("No trips found in iCloud or failed to decode.")
        }
    }
}
