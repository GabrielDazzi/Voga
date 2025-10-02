import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var viewModel = TripViewModel()

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            TripsListView(viewModel: viewModel)
        }
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
            ZStack {
                if viewModel.trips.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("empty_state_title")
                            .font(.title2.weight(.bold))
                        
                        Text("empty_state_description")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            
                            SectionHeader(title: "active_trips")
                            
                            if viewModel.activeTrips.isEmpty {
                                CardView {
                                    Text("no_active_trips")
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            } else {
                                ForEach(viewModel.activeTrips) { trip in
                                    NavigationLink(destination: TripDetailView(viewModel: viewModel, tripId: trip.id)) {
                                        TripRowView(trip: trip, onDelete: {
                                            viewModel.deleteTrip(trip)
                                        })
                                    }
                                }
                            }
                            
                            SectionHeader(title: "completed_trips")
                            
                            if viewModel.completedTrips.isEmpty {
                                 CardView {
                                    Text("no_completed_trips")
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            } else {
                                ForEach(viewModel.completedTrips) { trip in
                                    NavigationLink(destination: TripDetailView(viewModel: viewModel, tripId: trip.id)) {
                                        TripRowView(trip: trip, onDelete: {
                                            viewModel.deleteTrip(trip)
                                        })
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("my_trips")
            .background(Color(.systemGray6).ignoresSafeArea())
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
    let onDelete: () -> Void
    
    var body: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.destination)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text("\(NSLocalizedString("budget_label", comment: "")) \(trip.totalBudget.formatted(.currency(code: trip.currency.code)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer()
                if trip.isCompleted {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("delete", systemImage: "trash")
            }
        }
    }
}

struct TripSetupView: View {
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeSettings: ThemeSettings
    
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !trip.isCompleted {
                    BudgetSummaryView(trip: trip)
                        .padding(.top)
                }
                
                if !trip.expenses.isEmpty {
                    SectionHeader(title: "spending_chart")
                    CardView {
                        SpendingChartView(spendingData: trip.categorySpendingData, currencyCode: trip.currency.code)
                    }
                }
                
                SectionHeader(title: "category_spending")
                CardView {
                    CategorySpendingView(trip: trip)
                }
                
                SectionHeader(title: "expense_history")
                if trip.expenses.isEmpty {
                    CardView {
                        Text("no_expenses_yet").foregroundStyle(.secondary).padding(.vertical, 40)
                    }
                } else {
                    CardView {
                        VStack {
                            ForEach(trip.expenses.sorted(by: { $0.date > $1.date })) { expense in
                                ExpenseRowView(expense: expense, currencyCode: trip.currency.code)

                                    .contextMenu {
                                        if !trip.isCompleted {
                                            Button(role: .destructive) {
                                                viewModel.deleteExpense(expense, from: trip.id)
                                            } label: {
                                                Label("delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                
                                if expense.id != trip.expenses.sorted(by: { $0.date > $1.date }).last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(trip.destination)
        .background(Color(.systemGray6).ignoresSafeArea())
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

struct BudgetSummaryView: View {
    let trip: Trip
    @EnvironmentObject var themeSettings: ThemeSettings
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(trip.totalBudget.formatted(.currency(code: trip.currency.code)))
                    .font(.largeTitle.weight(.bold))
                    .monospacedDigit()
                
                Text(NSLocalizedString("total_budget", comment: "").lowercased())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: trip.totalSpent, total: trip.totalBudget > 0 ? trip.totalBudget : 1)
                .tint(trip.remainingBudget >= 0 ? themeSettings.accentColor.colorValue : .red)
                .padding(.bottom)
            
            HStack(spacing: 20) {
                StatView(title: "total_spent", value: trip.totalSpent, color: .red, currencyCode: trip.currency.code)
                Spacer()
                StatView(title: "remaining_balance", value: trip.remainingBudget, color: .green, currencyCode: trip.currency.code)
                Spacer()
                StatView(title: "daily_average", value: trip.dailyAverageBudget, color: themeSettings.accentColor.colorValue, currencyCode: trip.currency.code)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct CategorySpendingView: View {
    let trip: Trip
    let columns = [GridItem(.adaptive(minimum: 150))]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(BudgetCategory.allCases) { category in
                HStack {
                    Image(systemName: category.icon)
                        .foregroundStyle(category.color)
                        .font(.headline)
                    
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey(category.localizedNameKey)).font(.headline)
                        Text(trip.spent(for: category).formatted(.currency(code: trip.currency.code)))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct StatView: View {
    let title: LocalizedStringKey
    let value: Double
    let color: Color
    let currencyCode: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value.formatted(.currency(code: currencyCode)))
                .font(.headline.weight(.bold))
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    let currencyCode: String
    
    var body: some View {
        HStack {
            Image(systemName: expense.category.icon)
                .font(.title3)
                .foregroundStyle(expense.category.color)
                .frame(width: 40)
            VStack(alignment: .leading) {
                Text(expense.description).font(.headline)
                Text(expense.date, style: .date).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(expense.amount.formatted(.currency(code: currencyCode)))
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}


#Preview {
    ContentView()
        .environmentObject(LanguageSettings())
        .environmentObject(ThemeSettings())
}
