import SwiftUI

struct TripSetupView: View {
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var destination: String = ""
    @State private var selectedDates: Set<DateComponents> = []
    @State private var budget: String = ""
    @State private var currency: Currency = .usd
    
    @State private var isShowingCalendarSheet = false
    
    private var startDate: Date? {
        let sortedDates = selectedDates.compactMap { Calendar.current.date(from: $0) }.sorted()
        return sortedDates.first
    }
    
    private var endDate: Date? {
        let sortedDates = selectedDates.compactMap { Calendar.current.date(from: $0) }.sorted()
        return sortedDates.last
    }
    
    private var dateRangeDisplayText: String {
        guard let start = startDate, let end = endDate else {
            return NSLocalizedString("select_travel_dates", comment: "")
        }
        
        if Calendar.current.isDate(start, inSameDayAs: end) {
            return start.formatted(date: .abbreviated, time: .omitted)
        }
        
        return "\(start.formatted(date: .abbreviated, time: .omitted)) - \(end.formatted(date: .abbreviated, time: .omitted))"
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("trip_details")) {
                    TextField(NSLocalizedString("destination_placeholder", comment: ""), text: $destination)
                    
                    Button(action: {
                        isShowingCalendarSheet = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(VogaColor.accent)
                            Text(dateRangeDisplayText)
                                .foregroundColor(selectedDates.isEmpty ? .secondary : VogaColor.textPrimary)
                            Spacer()
                        }
                    }
                    
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
            .sheet(isPresented: $isShowingCalendarSheet) {
                DatePickerSheetView(selectedDateComponents: $selectedDates)
            }
        }
    }
    
    private func isFormValid() -> Bool {
        !destination.trimmingCharacters(in: .whitespaces).isEmpty &&
        CurrencyFormatter.parseDouble(from: budget) != nil &&
        startDate != nil && endDate != nil
    }
    
    private func addTripAndDismiss() {
        guard let budgetValue = CurrencyFormatter.parseDouble(from: budget),
              let validStartDate = startDate,
              let validEndDate = endDate else { return }
        
        viewModel.addTrip(destination: destination, startDate: validStartDate, endDate: validEndDate, budget: budgetValue, currency: currency)
        dismiss()
    }
}
