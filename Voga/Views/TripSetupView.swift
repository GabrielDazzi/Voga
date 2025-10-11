import SwiftUI

struct TripSetupView: View {
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var destination: String = ""
    @State private var duration: Int = 1
    @State private var budget: String = ""
    @State private var currency: Currency = .usd

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("trip_details")) {
                    TextField(NSLocalizedString("destination_placeholder", comment: ""), text: $destination)
                    
                    Stepper(String(format: NSLocalizedString("duration_days", comment: ""), duration), value: $duration, in: 1...365)
                    
                    Picker("currency", selection: $currency) {
                        ForEach(Currency.allCases) { currency in
                            Text(LocalizedStringKey(currency.localizedNameKey)).tag(currency)
                        }
                    }
                    
                    HStack {
                        Text(currency.symbol)
                        TextField(NSLocalizedString("total_budget", comment: ""), text: $budget)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Button(action: addTripAndDismiss) {
                    Text("save_trip")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .fontWeight(.semibold)
                        .background(VogaColor.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!isFormValid())
                .opacity(isFormValid() ? 1.0 : 0.4)
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
                
            }
            .navigationTitle("new_trip")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") { dismiss() }
                }
            }
        }
    }
    
    private func isFormValid() -> Bool {
        !destination.trimmingCharacters(in: .whitespaces).isEmpty &&
        CurrencyFormatter.parseDouble(from: budget) != nil &&
        duration > 0
    }
    
    private func addTripAndDismiss() {
        guard let budgetValue = CurrencyFormatter.parseDouble(from: budget) else { return }
        viewModel.addTrip(destination: destination, duration: duration, budget: budgetValue, currency: currency)
        dismiss()
    }
}
