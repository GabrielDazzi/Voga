import Foundation
import SwiftUI
import UniformTypeIdentifiers

// ADICIONADO Equatable AQUI
struct CategorySpending: Identifiable, Equatable {
    let id = UUID()
    let category: BudgetCategory
    let totalAmount: Double
}

enum Currency: String, CaseIterable, Identifiable, Codable {
    case usd
    case brl
    case eur
    case gbp

    var id: String { self.rawValue }

    var code: String {
        switch self {
        case .usd: return "USD"
        case .brl: return "BRL"
        case .eur: return "EUR"
        case .gbp: return "GBP"
        }
    }
    
    var localizedNameKey: String {
        switch self {
        case .usd: return "currency_usd"
        case .brl: return "currency_brl"
        case .eur: return "currency_eur"
        case .gbp: return "currency_gbp"
        }
    }
    
    var symbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = self.code
        return formatter.currencySymbol ?? "$"
    }
}

enum BudgetCategory: String, CaseIterable, Identifiable, Codable {
    case hospedagem
    case alimentacao
    case transporte
    case lazer

    var id: String { self.rawValue }
    
    var localizedNameKey: String {
        switch self {
        case .hospedagem: return "category_hospedagem"
        case .alimentacao: return "category_alimentacao"
        case .transporte: return "category_transporte"
        case .lazer: return "category_lazer"
        }
    }

    var icon: String {
        switch self {
        case .hospedagem: return "bed.double.fill"
        case .alimentacao: return "fork.knife"
        case .transporte: return "car.fill"
        case .lazer: return "party.popper.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .hospedagem: return .blue
        case .alimentacao: return .orange
        case .transporte: return .green
        case .lazer: return .purple
        }
    }
}

struct Expense: Identifiable, Codable, Hashable {
    let id: UUID = UUID()
    var description: String
    var amount: Double
    var category: BudgetCategory
    var date: Date = Date()
}

// ADICIONADO Equatable AQUI
struct Trip: Identifiable, Codable, Equatable {
    let id: UUID = UUID()
    var destination: String
    var durationInDays: Int
    var totalBudget: Double
    var currency: Currency
    var expenses: [Expense] = []
    var isCompleted: Bool = false
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
    
    var categorySpendingData: [CategorySpending] {
        let groupedExpenses = Dictionary(grouping: expenses, by: { $0.category })
        
        return groupedExpenses.map { (category, expenses) in
            let total = expenses.reduce(0) { $0 + $1.amount }
            return CategorySpending(category: category, totalAmount: total)
        }.sorted(by: { $0.totalAmount > $1.totalAmount })
    }

    func generateCSV() -> URL? {
        var csvString = "Date,Description,Category,Amount\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for expense in expenses.sorted(by: { $0.date < $1.date }) {
            let date = dateFormatter.string(from: expense.date)
            let description = "\"\(expense.description.replacingOccurrences(of: "\"", with: "\"\""))\""
            let category = NSLocalizedString(expense.category.localizedNameKey, comment: "")
            let amount = String(expense.amount)
            csvString.append("\(date),\(description),\(category),\(amount)\n")
        }

        do {
            let sanitizedDestination = destination.replacingOccurrences(of: "[^a-zA-Z0-9]+", with: "_", options: .regularExpression, range: nil)
            let filename = "Voga_Export_\(sanitizedDestination).csv"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            
            try csvString.write(to: url, atomically: true, encoding: .utf8)
            
            return url
        } catch {
            print("Error generating CSV file: \(error.localizedDescription)")
            return nil
        }
    }
}
