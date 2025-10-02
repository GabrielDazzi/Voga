import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var viewModel = TripViewModel()

    var body: some View {
        TripsListView(viewModel: viewModel)
    }
}

struct SpendingChartView: View {
    let spendingData: [CategorySpending]
    let currencyCode: String
    
    var body: some View {
        Chart(spendingData) { data in
            BarMark(
                x: .value("Amount", data.totalAmount),
                y: .value("Category", NSLocalizedString(data.category.localizedNameKey, comment: ""))
            )
            .foregroundStyle(data.category.color)
            .cornerRadius(6)
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(centered: true)
            }
        }
        .chartXAxis {
            AxisMarks(preset: .automatic, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount.formatted(.currency(code: currencyCode)))
                    }
                }
            }
        }
        .frame(height: 200)
    }
}

struct TripsListView: View {
    @ObservedObject var viewModel: TripViewModel
    @State private var showingAddTripSheet = false
    @State private var showingSettingsSheet = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("active_trips")) {
                    if viewModel.activeTrips.isEmpty {
                        Text("no_active_trips").foregroundColor(.secondary)
                    }
                    ForEach(viewModel.activeTrips) { trip in
                        NavigationLink(destination: TripDetailView(viewModel: viewModel, tripId: trip.id)) {
                            TripRowView(trip: trip)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.deleteTrip(at: offsets, in: viewModel.activeTrips)
                    }
                }
                
                Section(header: Text("completed_trips")) {
                    if viewModel.completedTrips.isEmpty {
                        Text("no_completed_trips").foregroundColor(.secondary)
                    }
                    ForEach(viewModel.completedTrips) { trip in
                        NavigationLink(destination: TripDetailView(viewModel: viewModel, tripId: trip.id)) {
                            TripRowView(trip: trip)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.deleteTrip(at: offsets, in: viewModel.completedTrips)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("my_trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettingsSheet = true }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTripSheet = true }) {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddTripSheet) {
                TripSetupView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
            }
        }
    }
}

struct TripRowView: View {
    let trip: Trip
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.destination)
                    .font(.headline)
                    .foregroundColor(trip.isCompleted ? .secondary : .primary)
                Text("\(NSLocalizedString("budget", comment: "")) \(trip.totalBudget.formatted(.currency(code: trip.currency.code)))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if trip.isCompleted {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
    }
}

// ALTERAÇÃO AQUI
struct TripSetupView: View {
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeSettings: ThemeSettings // Aceder ao tema
    
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
                        .frame(maxWidth: .infinity).padding()
                        // USA A COR DO TEMA AQUI
                        .background(isFormValid() ? themeSettings.accentColor.colorValue : Color.gray)
                        .foregroundColor(.white).cornerRadius(10)
                }
                .disabled(!isFormValid())
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
        Double(budget) != nil &&
        duration > 0
    }
    
    private func addTripAndDismiss() {
        guard let budgetValue = Double(budget) else { return }
        viewModel.addTrip(destination: destination, duration: duration, budget: budgetValue, currency: currency)
        dismiss()
    }
}

// ... TripDetailView não precisa de alterações ...
struct TripDetailView: View {
    @ObservedObject var viewModel: TripViewModel
    let tripId: UUID
    
    private var trip: Trip {
        viewModel.trips.first { $0.id == tripId } ?? Trip(destination: String(localized: "unknown_destination"), durationInDays: 0, totalBudget: 0, currency: .usd)
    }
    
    @State private var showingAddExpenseSheet = false
    @State private var showingEndTripAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showShareSheet = false
    @State private var csvURLToShare: URL?

    var body: some View {
        List {
            if !trip.isCompleted {
                Section(header: Text("budget_summary")) {
                    BudgetSummaryView(trip: trip)
                }
            }
            
            if !trip.expenses.isEmpty {
                Section(header: Text("spending_chart")) {
                    SpendingChartView(spendingData: trip.categorySpendingData, currencyCode: trip.currency.code)
                }
            }
            
            Section(header: Text("category_spending")) {
                CategorySpendingView(trip: trip)
            }
            
            Section(header: Text("expense_history")) {
                if trip.expenses.isEmpty {
                    Text("no_expenses_yet").foregroundColor(.gray)
                }
                ForEach(trip.expenses.sorted(by: { $0.date > $1.date })) { expense in
                    ExpenseRowView(expense: expense, currencyCode: trip.currency.code)
                }
                .onDelete { offsets in
                    if !trip.isCompleted {
                        viewModel.deleteExpense(from: tripId, at: offsets)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(trip.destination)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if trip.isCompleted {
                    if !trip.expenses.isEmpty {
                        Button(action: {
                            self.csvURLToShare = trip.generateCSV()
                            if self.csvURLToShare != nil {
                                self.showShareSheet = true
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                } else {
                    Button(action: { showingEndTripAlert = true }) {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Button(action: { showingAddExpenseSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExpenseSheet) {
            AddExpenseView(viewModel: viewModel, tripId: trip.id, currency: trip.currency)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = csvURLToShare {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("complete_trip_q", isPresented: $showingEndTripAlert) {
            Button("cancel", role: .cancel) {}
            Button("complete", role: .destructive) {
                viewModel.markTripAsCompleted(trip)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("complete_trip_message")
        }
    }
}

// ... ShareSheet e AddExpenseView não precisam de alterações ...
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct AddExpenseView: View {
    @ObservedObject var viewModel: TripViewModel
    let tripId: UUID
    let currency: Currency
    @Environment(\.dismiss) var dismiss
    
    @State private var description: String = ""
    @State private var amount: String = ""
    @State private var category: BudgetCategory = .alimentacao
    @State private var date: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("expense_details")) {
                    TextField(NSLocalizedString("description_placeholder", comment: ""), text: $description)
                    
                    HStack {
                        Text(currency.symbol)
                        TextField(NSLocalizedString("amount", comment: ""), text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    Picker("category", selection: $category) {
                        ForEach(BudgetCategory.allCases) { category in
                            Text(LocalizedStringKey(category.localizedNameKey)).tag(category)
                        }
                    }
                    DatePicker("date", selection: $date, displayedComponents: .date)
                }
                
                Button(action: addExpense) { Text("add_expense") }
                .disabled(!isFormValid())
            }
            .navigationTitle("new_expense")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") { dismiss() }
                }
            }
        }
    }
    
    private func isFormValid() -> Bool {
        !description.trimmingCharacters(in: .whitespaces).isEmpty && Double(amount) != nil
    }
    
    private func addExpense() {
        guard let amountValue = Double(amount) else { return }
        viewModel.addExpense(to: tripId, description: description, amount: amountValue, category: category, date: date)
        dismiss()
    }
}

// ALTERAÇÃO AQUI
struct BudgetSummaryView: View {
    let trip: Trip
    @EnvironmentObject var themeSettings: ThemeSettings // Aceder ao tema
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatView(title: "total_budget", value: trip.totalBudget, color: .primary, currencyCode: trip.currency.code)
                Spacer()
                // USA A COR DO TEMA AQUI
                StatView(title: "daily_average", value: trip.dailyAverageBudget, color: themeSettings.accentColor.colorValue, alignment: .trailing, currencyCode: trip.currency.code)
            }
            ProgressView(value: trip.totalSpent, total: trip.totalBudget > 0 ? trip.totalBudget : 1)
                // E AQUI
                .tint(trip.remainingBudget >= 0 ? themeSettings.accentColor.colorValue : .red)
            HStack {
                StatView(title: "total_spent", value: trip.totalSpent, color: .red, currencyCode: trip.currency.code)
                Spacer()
                StatView(title: "remaining_balance", value: trip.remainingBudget, color: .green, alignment: .trailing, currencyCode: trip.currency.code)
            }
        }
        .padding(.vertical, 8)
    }
}

// ... O resto do ficheiro não precisa de alterações ...
struct CategorySpendingView: View {
    let trip: Trip
    let columns = [GridItem(.adaptive(minimum: 150))]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(BudgetCategory.allCases) { category in
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: category.icon).foregroundColor(category.color)
                        Text(LocalizedStringKey(category.localizedNameKey)).font(.headline)
                    }
                    Text(trip.spent(for: category).formatted(.currency(code: trip.currency.code)))
                        .font(.title3).fontWeight(.semibold)
                }
                .padding().background(Color(.systemGray6)).cornerRadius(10)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatView: View {
    let title: LocalizedStringKey
    let value: Double
    let color: Color
    var alignment: HorizontalAlignment = .leading
    let currencyCode: String
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value.formatted(.currency(code: currencyCode))).font(.title2).fontWeight(.bold).foregroundColor(color)
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    let currencyCode: String
    
    var body: some View {
        HStack {
            Image(systemName: expense.category.icon).font(.title2).foregroundColor(expense.category.color).frame(width: 40)
            VStack(alignment: .leading) {
                Text(expense.description).font(.headline)
                Text(expense.date, style: .date).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(expense.amount.formatted(.currency(code: currencyCode))).fontWeight(.medium)
        }
        .padding(.vertical, 8)
    }
}


#Preview {
    ContentView()
}
