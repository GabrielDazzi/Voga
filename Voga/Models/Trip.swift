import Foundation
import SwiftUI

// Enum para moedas suportadas
enum Currency: String, CaseIterable, Identifiable, Codable {
    case usd
    case brl
    case eur
    case gbp

    var id: String { self.rawValue }

    // Código ISO 4217, essencial para formatação
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

// Enumeração para as categorias de despesas.
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

// Representa uma única despesa.
struct Expense: Identifiable, Codable, Hashable {
    let id: UUID = UUID()
    var description: String
    var amount: Double
    var category: BudgetCategory
    var date: Date = Date()
}

// Representa a viagem completa com todos os seus dados.
struct Trip: Identifiable, Codable {
    let id: UUID = UUID()
    var destination: String
    var durationInDays: Int
    var totalBudget: Double
    var currency: Currency
    var expenses: [Expense] = []
    var isCompleted: Bool = false
}
