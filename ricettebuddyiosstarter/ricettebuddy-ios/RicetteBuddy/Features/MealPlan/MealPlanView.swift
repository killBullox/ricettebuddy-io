import SwiftUI
import SwiftData

struct MealPlanView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [MealPlanEntry]
    @State private var weekStart: Date = MealPlanView.startOfWeek(for: .now)

    private let calendar = Calendar.current

    private var weekDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(weekDays, id: \.self) { day in
                    Section(dayTitle(day)) {
                        ForEach(MealSlot.allCases) { slot in
                            MealSlotRow(entry: entry(for: day, slot: slot), slot: slot)
                        }
                    }
                }
            }
            .navigationTitle("Piano pasti")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { shiftWeek(-1) } label: { Image(systemName: "chevron.left") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { shiftWeek(1) } label: { Image(systemName: "chevron.right") }
                }
            }
        }
    }

    private func entry(for day: Date, slot: MealSlot) -> MealPlanEntry? {
        entries.first {
            calendar.isDate($0.date, inSameDayAs: day) && $0.slot == slot
        }
    }

    private func shiftWeek(_ direction: Int) {
        if let newStart = calendar.date(byAdding: .day, value: 7 * direction, to: weekStart) {
            weekStart = newStart
        }
    }

    private func dayTitle(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month())
    }

    static func startOfWeek(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
}

private struct MealSlotRow: View {
    let entry: MealPlanEntry?
    let slot: MealSlot

    var body: some View {
        HStack {
            Text(slot.localizedName)
                .frame(width: 90, alignment: .leading)
                .foregroundStyle(.secondary)
            if let recipe = entry?.recipe {
                Text(recipe.title)
            } else {
                Text("—").foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }
}
