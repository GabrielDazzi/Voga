import SwiftUI

struct DatePickerSheetView: View {
    @Binding var selectedDateComponents: Set<DateComponents>
    @Environment(\.dismiss) var dismiss

    @State private var startDate: Date?
    @State private var endDate: Date?
    
    @State private var pickerSelection: Set<DateComponents> = []

    var body: some View {
        NavigationView {
            MultiDatePicker("select_dates", selection: $pickerSelection, in: Date()...)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("select_dates")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("done") {
                            selectedDateComponents = pickerSelection
                            dismiss()
                        }
                        .disabled(startDate == nil || endDate == nil)
                    }
                }
                .onAppear(perform: setupInitialDates)
                .onChange(of: pickerSelection) { newSelection in
                    if isSelectionProgrammatic(newSelection) {
                        return
                    }
                    handleDateSelection(newSelection)
                }
        }
    }
    
    private func setupInitialDates() {
        self.pickerSelection = selectedDateComponents
        
        let dates = selectedDateComponents.compactMap { Calendar.current.date(from: $0) }.sorted()
        if let first = dates.first {
            self.startDate = first
        }
        if dates.count > 1, let last = dates.last {
            self.endDate = last
        }
    }
    
    private func isSelectionProgrammatic(_ selection: Set<DateComponents>) -> Bool {
        var expectedSelection = Set<DateComponents>()
        let calendar = Calendar.current
        
        guard let start = startDate else { return false }
        
        expectedSelection.insert(calendar.dateComponents([.year, .month, .day], from: start))
        
        if let end = endDate {
            var currentDate = start
            while currentDate < end {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                expectedSelection.insert(calendar.dateComponents([.year, .month, .day], from: currentDate))
            }
        }
        
        return selection == expectedSelection
    }
    
    private func handleDateSelection(_ newSelection: Set<DateComponents>) {
        guard let latestDate = newSelection.compactMap({ $0.date }).max(by: { $0 < $1 }) else {
            startDate = nil
            endDate = nil
            pickerSelection = []
            return
        }
        
        if startDate == nil || (startDate != nil && endDate != nil) {
            startDate = latestDate
            endDate = nil
        } else if let currentStartDate = startDate {
            if latestDate < currentStartDate {
                startDate = latestDate
            } else {
                endDate = latestDate
            }
        }
        
        updatePickerSelection()
    }
    
    private func updatePickerSelection() {
        var newPickerSelection = Set<DateComponents>()
        let calendar = Calendar.current
        
        guard let start = startDate else {
            pickerSelection = newPickerSelection
            return
        }
        
        newPickerSelection.insert(calendar.dateComponents([.year, .month, .day], from: start))
        
        guard let end = endDate else {
            pickerSelection = newPickerSelection
            return
        }

        var currentDate = start
        while currentDate < end {
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            newPickerSelection.insert(calendar.dateComponents([.year, .month, .day], from: currentDate))
        }
        
        pickerSelection = newPickerSelection
    }
}
