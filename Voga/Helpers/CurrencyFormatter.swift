import Foundation

struct CurrencyFormatter {
    
    static private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        // A mágica acontece aqui: o formatter usará a localidade atual do dispositivo
        // para entender se o separador é ',' ou '.'.
        return formatter
    }()
    
    /// Converte uma String (ex: "10,50" ou "10.50") para um Double,
    /// respeitando as configurações de região do usuário.
    static func parseDouble(from string: String) -> Double? {
        return formatter.number(from: string)?.doubleValue
    }
    
    /// Formata um Double de volta para uma String localizada.
    /// Útil para preencher campos de texto na edição.
    static func format(value: Double) -> String {
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
}
