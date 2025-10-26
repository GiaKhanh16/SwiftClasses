import SwiftUI
import SwiftData

struct StaffView: View {
	 @State private var searchable: String = ""
	 @State private var addStaffBool: Bool = false
	 @Query var staffs: [StaffModel]

	 var body: some View {
			NavigationStack {
				 List(filteredStaff) { staff in
						NavigationLink(value: staff) {
							 VStack(alignment: .leading, spacing: 8) {
									Text(staff.name)
									Text(staff.note)
										 .foregroundStyle(.secondary)
										 .font(.footnote)
							 }
						}
				 }
				 .navigationTitle("Staffs")
				 .toolbar {
						Button {
							 withAnimation {
									addStaffBool.toggle()
							 }
						} label: {
							 Image(systemName: "plus")
						}
				 }
				 .navigationDestination(for: StaffModel.self) { staff in
						StaffDetailView(staff: staff)
							 .toolbar(.hidden, for: .tabBar)
				 }
				 .searchable(text: $searchable)
				 .sheet(isPresented: $addStaffBool) {
						AddStaffView()

				 }
			}
	 }
	 var filteredStaff: [StaffModel] {
			if searchable.isEmpty {
				 return staffs
			} else {
				 return staffs.filter { 
						$0.name.localizedCaseInsensitiveContains(searchable)
				 }
			}
	 }

}

struct StaffDetailView: View {
	 @Environment(\.dismiss) var dismiss
	 @Environment(SubscriptionStatus.self) var subModel
	 @Environment(\.modelContext) var modelContext
	 @Bindable var staff: StaffModel

	 @State private var displayedCount = 5
	 @State private var confirmationShown = false
	 @State private var filterTogg = false

			// Active date filters
	 @State private var startDate = Date.distantPast
	 @State private var endDate = Date.distantFuture

	 @State private var exportStartDate = Date()
	 @State private var exportEndDate = Date()
	 @State private var tempStartDate = Date()
	 @State private var tempEndDate = Date()
	 @State private var exportMenu: Bool = false
	 @State private var AISheet: Bool = false
	 @State private var paywall: Bool = false

	 var totalFilteredHours: Double {
			let calendar = Calendar.current
			let start = calendar.startOfDay(for: tempStartDate)
			let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: tempEndDate))!

			let filteredAttendances = staff.staffAttendances.filter { staffAttendance in
				 let date = staffAttendance.attendance.date
				 return date >= start && date < end
			}

			let total = filteredAttendances.reduce(0.0) { sum, staffAttendance in
				 sum + Double(staffAttendance.hour) + Double(staffAttendance.minute) / 60.0
			}

			return total
	 }


	 var body: some View {
			VStack {
				 Form {
						Section("Name") {
							 TextField("John Doe", text: $staff.name)
						}

						Section("Note") {
							 TextField("Yoga Teacher", text: $staff.note)
						}

						Section("History") {
									// 1. Sort by date (latest first)
							 let sortedAttendances = staff.staffAttendances.sorted {
									$0.attendance.date > $1.attendance.date
							 }

									// 2. Filter by active range
							 let filteredAttendances = sortedAttendances.filter { staffAttendance in
									let date = staffAttendance.attendance.date
									return date >= startDate && date <= endDate
							 }

									// 3. Limit results
							 let displayedAttendances = filteredAttendances.prefix(displayedCount)

									// 4. UI
							 if filteredAttendances.isEmpty {
									Text("No attendance records in this date range.")
										 .foregroundStyle(.secondary)
							 } else {
									ForEach(displayedAttendances) { staffAttendance in
										 let attendance = staffAttendance.attendance
										 if let classModel = attendance.classModel {
												HStack {
													 VStack(alignment: .leading, spacing: 4) {
															Text(classModel.name)
																 .font(.headline)
															Text(attendance.date, style: .date)
																 .font(.subheadline)
																 .foregroundStyle(.secondary)
													 }
													 Spacer()
													 StaffDurationPicker(staffAttendance: staffAttendance)
												}
										 }
									}
							 }

									// 5. Show more
							 if filteredAttendances.count > displayedCount {
									Button("Show More") {
										 displayedCount += 5
									}
							 }
						}
				 }
				 .listSectionSpacing(.custom(0))
				 .navigationTitle("Details")
				 .toolbar {

						Button {
									AISheet.toggle()
						} label: {
							 Image(systemName: "apple.intelligence")
						}


						Button {
									// Preload temp dates
							 tempStartDate = startDate == .distantPast ? Date() : startDate
							 tempEndDate = endDate == .distantFuture ? Date() : endDate
							 filterTogg.toggle()
						} label: {
							 Image(systemName: "line.3.horizontal.decrease")
						}
						.popover(
							 isPresented: $filterTogg,
							 attachmentAnchor: .point(.bottomTrailing)
						) {
							 VStack(alignment: .leading, spacing: 12) {
									DatePicker("From", selection: $tempStartDate, displayedComponents: .date)
									DatePicker("To", selection: $tempEndDate, displayedComponents: .date)

									Text("Total Hours: \(totalFilteredHours, specifier: "%.2f")")

									HStack(spacing: 10) {
										 Button("Apply") {
												startDate = tempStartDate
												endDate = tempEndDate
												filterTogg = false
										 }
										 .buttonStyle(.borderedProminent)


										 Button("Reset") {
												startDate = .distantPast
												endDate = .distantFuture
												filterTogg = false
										 }
										 .buttonStyle(.bordered)
									}
									.padding(.top, 8)
							 }
							 .padding(20)
							 .presentationCompactAdaptation(.popover)
						}

						Button {
//							 if subModel.notSubscribed == false {
//									paywall.toggle()
//							 } else {
									exportMenu.toggle()
//							 }

						} label: {
							 Image(systemName: "square.and.arrow.up")
						}
						.popover(
							 isPresented: $exportMenu,
							 attachmentAnchor: .point(.bottomTrailing),
							 content: {
									VStack(alignment: .leading){

										 DatePicker(
												"From",
												selection: $exportStartDate,
												displayedComponents: .date
										 )

										 DatePicker(
												"To",
												selection: $exportEndDate,
												displayedComponents: .date
										 )

										 if let exportURL = staffAttendanceCSVURL(
												startDate: exportStartDate,
												endDate: exportEndDate
										 ) {
												withAnimation {
													 ShareLink(
															item: exportURL
													 ) {
															Label("Export", systemImage: "square.and.arrow.up")
													 }
												}
										 } else {
												Text("No attendance data available in this range.")
													 .foregroundStyle(.secondary)
										 }


									}
									.padding(20)
									.presentationCompactAdaptation(.popover)
							 })

						Button {
							 confirmationShown.toggle()
						} label: {
							 Image(systemName: "trash")
						}
						.confirmationDialog(
							 "Are you sure?",
							 isPresented: $confirmationShown,
							 titleVisibility: .visible
						) {
							 Button("Yes") {
									deleteStaff(staff)
									dismiss()
							 }
							 Button("No") {
									confirmationShown.toggle()
							 }
						}
						.sheet(isPresented: $AISheet) {
							 TheOverview()
						}
				 }
			}
	 }

	 private func deleteStaff(_ staff: StaffModel) {
			do {
				 modelContext.delete(staff)
				 try modelContext.save()
				 dismiss()
			} catch {
				 print(error)
			}
	 }

	 @MainActor
	 func staffAttendanceCSVURL(startDate: Date, endDate: Date) -> URL? {
			let calendar = Calendar.current
			let start = calendar.startOfDay(for: startDate)
			let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!

				 // Filter and sort attendances exactly like your UI Section
			let filteredAttendances = staff.staffAttendances
				 .sorted { $0.attendance.date > $1.attendance.date }
				 .filter { staffAttendance in
						let date = staffAttendance.attendance.date
						return date >= start && date < end
				 }

			guard !filteredAttendances.isEmpty else {
				 print("No attendance records found for this staff in the selected range.")
				 return nil
			}

				 // Build CSV text
			var csvText = "Class Name,Date,Duration (hrs)\n"
			let formatter = DateFormatter()
			formatter.dateStyle = .short
			formatter.timeStyle = .none

			for staffAttendance in filteredAttendances {
				 let attendance = staffAttendance.attendance
				 let className = attendance.classModel?.name ?? "Unknown Class"
				 let date = formatter.string(from: attendance.date)
				 let duration = String(format: "%.2f", Double(staffAttendance.hour) + Double(staffAttendance.minute)/60.0)

				 csvText += "\"\(className)\",\"\(date)\",\"\(duration)\"\n"
			}

				 // Add summary
			csvText += "\nExported range: \(formatter.string(from: startDate)) - \(formatter.string(from: endDate))\n"
			csvText += "Staff: \(staff.name)\n"

				 // Create temporary file URL (you can use this with ShareLink)
			let safeName = staff.name

			let monthFormatter = DateFormatter()
			monthFormatter.dateFormat = "MMM"
			let monthString = monthFormatter.string(from: startDate)

			let fileName = "\(safeName)-\(monthString).csv"
			let tempDir = FileManager.default.temporaryDirectory
			let fileURL = tempDir.appendingPathComponent(fileName)

				 // Write CSV to temp file (required for ShareLink)
			do {
				 try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
				 return fileURL
			} catch {
				 print("Failed to prepare CSV: \(error)")
				 return nil
			}
	 }


}

struct AddStaffView: View {
	 @Environment(\.dismiss) var dismiss
	 @Environment(\.modelContext) var modelContext

	 @State private var name: String = ""
	 @State private var note: String = ""


	 var body: some View {
			NavigationStack {
				 Form {
						Section("Name") {
							 TextField("Novak Djokovic", text: $name)
						}
						Section("Note") {
							 TextField("Role...", text: $note)
						}

				 }
				 .navigationTitle("Add Staff")
				 .toolbar {
						ToolbarItem(placement: .confirmationAction) {
							 Button("Save") {
									let newStaff = StaffModel(
										 name: name,
										 note: note
									)
									modelContext.insert(newStaff)
									do {
										 try modelContext.save()
									} catch {
										 print(error)
									}
									dismiss()
							 }
						}

						ToolbarItem(placement: .cancellationAction) {
							 Button("Cancel") { dismiss() }
						}
				 }
			}
	 }
}



