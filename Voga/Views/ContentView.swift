import SwiftUI
import Charts

struct ShareableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct TripCardView: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(trip.destination)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(VogaColor.textPrimary)
            
            HStack {
                Text(trip.formattedDateRange)
                     .font(.subheadline)
                     .fontWeight(.medium)
                
                Spacer()
                
                Text(String.localizedStringWithFormat(NSLocalizedString("duration_days_format", comment: ""), trip.durationInDays))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(VogaColor.accent.opacity(0.15))
                    .clipShape(Capsule())
            }
            .foregroundColor(VogaColor.textSecondary)
            .padding(.bottom, 8)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("remaining_balance")
                        .font(.caption)
                        .foregroundColor(VogaColor.textSecondary) // Cor do texto ajustada
                    Spacer()
                    Text(trip.remainingBudget.formatted(.currency(code: trip.currency.code)))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(VogaColor.textPrimary) // Cor do texto ajustada
                }
                
                ProgressView(value: trip.totalSpent, total: trip.totalBudget > 0 ? trip.totalBudget : 1)
                    .progressViewStyle(.linear)
                    .tint(VogaColor.accent) // Cor da barra ajustada
            }
        }
        .padding(20)
        .frame(height: 180)
        .background(VogaColor.backgroundSecondary) // COR DO FUNDO ALTERADA
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4) // Sombra mais sutil
    }
}


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
        .animation(.easeInOut(duration: 0.6), value: spendingData)
        .frame(height: 200)
    }
}

struct TripsListView: View {
    @ObservedObject var viewModel: TripViewModel
    @State private var showingAddTripSheet = false
    @State private var showingSettingsSheet = false
    @State private var tripToEdit: Trip?
    
    var body: some View {
        NavigationView {
            ZStack {
                VogaColor.backgroundPrimary.ignoresSafeArea()

                if viewModel.trips.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if !viewModel.activeTrips.isEmpty {
                                SectionHeader(title: "active_trips")
                                
                                ForEach(viewModel.activeTrips) { trip in
                                    NavigationLink(destination: TripDetailView(viewModel: viewModel, tripId: trip.id)) {
                                        TripCardView(trip: trip)
                                    }
                                    .contextMenu { makeContextMenu(for: trip) }
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                                }
                            }
                            
                            if !viewModel.completedTrips.isEmpty {
                                SectionHeader(title: "completed_trips")
                                
                                ForEach(viewModel.completedTrips) { trip in
                                    NavigationLink(destination: TripDetailView(viewModel: viewModel, tripId: trip.id)) {
                                        TripCardView(trip: trip)
                                            .opacity(0.7)
                                    }
                                    .contextMenu { makeContextMenu(for: trip) }
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                                }
                            }
                        }
                        .padding()
                        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2), value: viewModel.trips)
                    }
                }
            }
            .navigationTitle("my_trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettingsSheet = true }) { Image(systemName: "gear") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTripSheet = true }) { Image(systemName: "plus.circle.fill").font(.title2) }
                }
            }
            .sheet(isPresented: $showingAddTripSheet) { TripSetupView(viewModel: viewModel) }
            .sheet(isPresented: $showingSettingsSheet) { SettingsView() }
            .sheet(item: $tripToEdit) { trip in EditTripView(viewModel: viewModel, trip: trip) }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 50))
                .foregroundColor(VogaColor.textTertiary)
            Text("empty_state_title")
                .font(.title2.weight(.bold))
                .foregroundColor(VogaColor.textPrimary)
            Text("empty_state_description")
                .font(.subheadline)
                .foregroundColor(VogaColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(40)
    }
    
    @ViewBuilder
    private func makeContextMenu(for trip: Trip) -> some View {
        if !trip.isCompleted {
            Button {
                tripToEdit = trip
            } label: {
                Label("edit", systemImage: "pencil")
            }
        }
        Button(role: .destructive) {
            viewModel.deleteTrip(trip)
        } label: {
            Label("delete", systemImage: "trash")
        }
    }
}


struct TripRowView: View {
    let trip: Trip
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: trip.isCompleted ? "checkmark.circle.fill" : "airplane.departure")
                .font(.title2)
                .foregroundColor(trip.isCompleted ? .green : VogaColor.accent)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.destination)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(VogaColor.textPrimary)
                
                Text(trip.totalBudget.formatted(.currency(code: trip.currency.code)))
                    .font(.subheadline)
                    .foregroundColor(VogaColor.textSecondary)
                    .monospacedDigit()
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct EditTripView: View {
    @ObservedObject var viewModel: TripViewModel
    let trip: Trip
    
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDates: Set<DateComponents> = []
    @State private var budget: String = ""
    
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
                Section(header: Text(trip.destination)) {
                    Button(action: {
                        isShowingCalendarSheet = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(VogaColor.accent)
                            Text(dateRangeDisplayText)
                                .foregroundColor(VogaColor.textPrimary)
                            Spacer()
                        }
                    }
                    
                    HStack {
                        Text(trip.currency.symbol)
                        TextField(NSLocalizedString("budget", comment: ""), text: $budget)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Button(action: saveChanges) {
                    Text("save_trip")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!isFormValid())
            }
            .navigationTitle("edit_trip")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") { dismiss() }
                }
            }
            .onAppear {
                self.budget = CurrencyFormatter.format(value: trip.totalBudget)
                
                var date = trip.startDate
                let calendar = Calendar.current
                while date <= trip.endDate {
                    selectedDates.insert(calendar.dateComponents([.year, .month, .day], from: date))
                    date = calendar.date(byAdding: .day, value: 1, to: date)!
                }
            }
            .sheet(isPresented: $isShowingCalendarSheet) {
                DatePickerSheetView(selectedDateComponents: $selectedDates)
            }
        }
    }
    
    private func isFormValid() -> Bool {
        CurrencyFormatter.parseDouble(from: budget) != nil && startDate != nil && endDate != nil
    }
    
    private func saveChanges() {
        guard let budgetValue = CurrencyFormatter.parseDouble(from: budget),
              let validStartDate = startDate,
              let validEndDate = endDate else { return }
        
        viewModel.updateTrip(tripId: trip.id, newStartDate: validStartDate, newEndDate: validEndDate, newBudget: budgetValue)
        dismiss()
    }
}

struct TripDetailView: View {
    @ObservedObject var viewModel: TripViewModel
    let tripId: UUID
    
    private var trip: Trip {
        viewModel.trips.first { $0.id == tripId } ?? Trip(destination: "Unknown", startDate: Date(), endDate: Date(), totalBudget: 0, currency: .usd)
    }
    
    @State private var showingAddExpenseSheet = false
    @State private var showingEndTripAlert = false
    @State private var showingEditSheet = false
    @Environment(\.presentationMode) var presentationMode
    
    @State private var shareableURL: ShareableURL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                BudgetSummaryView(trip: trip)
                    .onTapGesture { if !trip.isCompleted { showingEditSheet = true } }

                if !trip.expenses.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "spending_chart")
                        SpendingChartView(spendingData: trip.categorySpendingData, currencyCode: trip.currency.code)
                            .padding()
                            .background(VogaColor.backgroundSecondary)
                            .cornerRadius(16)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "expense_history")
                    if trip.expenses.isEmpty {
                        Text("no_expenses_yet")
                            .foregroundStyle(VogaColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(40)
                            .background(VogaColor.backgroundSecondary)
                            .cornerRadius(16)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(trip.expenses.sorted(by: { $0.date > $1.date })) { expense in
                                ExpenseRowView(expense: expense, currencyCode: trip.currency.code)
                                    .padding()
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
                                    Divider().padding(.leading)
                                }
                            }
                        }
                        .background(VogaColor.backgroundSecondary)
                        .cornerRadius(16)
                    }
                }
            }
            .padding()
        }
        .background(VogaColor.backgroundPrimary)
        .navigationTitle(trip.destination)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if trip.isCompleted {
                    if !trip.expenses.isEmpty {
                        Button(action: {
                            if let url = trip.generateCSV() {
                                self.shareableURL = ShareableURL(url: url)
                            }
                        }) { Image(systemName: "square.and.arrow.up") }
                    }
                } else {
                    HStack(spacing: 5) {
                        Button(action: { showingEndTripAlert = true }) { Image(systemName: "checkmark.circle.fill") }
                        Button(action: { showingAddExpenseSheet = true }) { Image(systemName: "plus.circle.fill") }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExpenseSheet) { AddExpenseView(viewModel: viewModel, tripId: trip.id, currency: trip.currency) }
        .sheet(isPresented: $showingEditSheet) { EditTripView(viewModel: viewModel, trip: trip) }
        .sheet(item: $shareableURL) { item in
            ShareSheet(activityItems: [item.url])
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
        !description.trimmingCharacters(in: .whitespaces).isEmpty && CurrencyFormatter.parseDouble(from: amount) != nil
    }
    
    private func addExpense() {
        guard let amountValue = CurrencyFormatter.parseDouble(from: amount) else { return }
        viewModel.addExpense(to: tripId, description: description, amount: amountValue, category: category, date: date)
        dismiss()
    }
}

struct BudgetSummaryView: View {
    let trip: Trip
    
    var body: some View {
        VStack(spacing: 16) {
            VStack {
                Text("remaining_balance")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(VogaColor.textSecondary)
                
                Text(trip.remainingBudget.formatted(.currency(code: trip.currency.code)))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(trip.remainingBudget >= 0 ? .green : .red)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
            }
            .padding(.bottom, 8)
            
            ProgressView(value: trip.totalSpent, total: trip.totalBudget > 0 ? trip.totalBudget : 1)
                .progressViewStyle(.linear)
                .tint(trip.remainingBudget >= 0 ? VogaColor.accent : .red)

            HStack {
                StatView(title: "total_spent", value: trip.totalSpent, currencyCode: trip.currency.code)
                Spacer()
                StatView(title: "total_budget", value: trip.totalBudget, currencyCode: trip.currency.code)
                Spacer()
                StatView(title: "daily_average", value: trip.dailyAverageBudget, currencyCode: trip.currency.code)
            }
        }
        .padding()
        .background(VogaColor.backgroundSecondary)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
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
    let currencyCode: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundStyle(VogaColor.textSecondary)
            Text(value.formatted(.currency(code: currencyCode)))
                .font(.headline.weight(.semibold))
                .foregroundStyle(VogaColor.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
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
                Text(expense.description).font(.headline).foregroundStyle(VogaColor.textPrimary)
                Text(expense.date, style: .date).font(.caption).foregroundStyle(VogaColor.textSecondary)
            }
            Spacer()
            Text(expense.amount.formatted(.currency(code: currencyCode)))
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundStyle(VogaColor.textPrimary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LanguageSettings())
}
