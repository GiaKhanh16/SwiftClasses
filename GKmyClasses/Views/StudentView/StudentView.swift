import SwiftUI
import SwiftData

struct StudentView: View {
	 @State private var searchable: String = ""
	 @State private var addStudentBool: Bool = false
	 @Query var students: [StudentModel]
	 var body: some View {
			NavigationStack {
				 List(filteredStudent) { student in
						NavigationLink(value: student) {
							 VStack(alignment: .leading, spacing: 8) {
									Text(student.name)

									Text(String(student.age))
										 .font(.footnote)
										 .foregroundStyle(.secondary)
							 }
						}
				 }
				 .navigationTitle("Attendees")
				 .toolbar {
						Button {
							 withAnimation {
									addStudentBool.toggle()
							 }
						} label: {
							 Image(systemName: "plus")
						}
				 }
				 .navigationDestination(for: StudentModel.self) { student in
						StudentDetailView(student: student)
							 .toolbar(.hidden, for: .tabBar)
				 }
				 .searchable(text: $searchable)
				 .sheet(isPresented: $addStudentBool) {
						AddStudentView()

				 }
			}
	 }
	 var filteredStudent: [StudentModel] {
			if searchable.isEmpty {
				 return students
			} else {
				 return students.filter {
						$0.name.localizedCaseInsensitiveContains(searchable)
				 }
			}
	 }
}



struct StudentDetailView: View {
	 @Environment(\.dismiss) var dismiss
	 @Environment(\.modelContext) var modelContext
	 @Environment(SubscriptionStatus.self) var subModel
	 @Bindable var student: StudentModel

	 @State private var displayedCount = 5
	 @State private var confirmationShown = false
	 @State private var filterTogg = false

			// Active filter dates
	 @State private var startDate = Date.distantPast
	 @State private var endDate = Date.distantFuture

	 @State private var exportStartDate = Date()
	 @State private var exportEndDate = Date()

			// Temporary picker dates
	 @State private var tempStartDate = Date()
	 @State private var tempEndDate = Date()


	 @State private var exportMenu: Bool = false
	 @State private var paywall: Bool = false
	 @State private var AISheet: Bool = false

	 var body: some View {
			VStack {
				 Form {
						Section("Name") {
							 TextField("John Doe", text: $student.name)
						}
						Section("Age") {
							 TextField("Age", value: $student.age, formatter: NumberFormatter())
									.keyboardType(.numberPad)
						}
						Section("Level") {
							 TextField("Intermediate", text: $student.level)
						}

						Section("Attendance History") {
									// 1. Sort attendances (latest first)
							 let sortedAttendances = student.attendances.sorted(by: { $0.date > $1.date })

									// 2. Apply active date range
							 let filteredAttendances = sortedAttendances.filter { attendance in
									return attendance.date >= startDate && attendance.date <= endDate
							 }

									// 3. Limit count
							 let displayedAttendances = filteredAttendances.prefix(displayedCount)

									// 4. Display
							 if filteredAttendances.isEmpty {
									Text("No attendance records in this date range.")
										 .foregroundStyle(.secondary)
							 } else {
									ForEach(displayedAttendances) { attendance in
										 if let classModel = attendance.classModel {
												VStack(alignment: .leading, spacing: 4) {
													 Text(classModel.name)
															.font(.headline)
													 Text(attendance.date, style: .date)
															.font(.subheadline)
															.foregroundStyle(.secondary)
												}
										 }
									}
							 }

									// 5. Show More
							 if filteredAttendances.count > displayedCount {
									Button("Show More") {
										 displayedCount += 5
									}
							 }
						}
				 }
				 .listSectionSpacing(.custom(0))
				 .navigationTitle("Details")
				 .sheet(isPresented: $AISheet) {
						TheOverview()
				 }
				 .toolbar {

						Button {
									AISheet.toggle()

						} label: {
							 Image(systemName: "apple.intelligence")
						}

						Button {
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

									HStack {
										 Button("Apply") {
												startDate = tempStartDate
												endDate = tempEndDate
												filterTogg = false
										 }
										 .buttonStyle(.borderedProminent)

										 Spacer()

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
							 if subModel.notSubscribed == false {
									paywall.toggle()
							 } else {
									exportMenu.toggle()
							 }

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


										 if let exportURL = exportAttendanceCSV(
												context: modelContext,
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
									deleteStudent(student)
									dismiss()
							 }
							 Button("No") {
									confirmationShown.toggle()
							 }
						}
				 }
			}
	 }

	 private func deleteStudent(_ student: StudentModel) {
			do {
				 modelContext.delete(student)
				 try modelContext.save()
				 dismiss()
			} catch {
				 print(error)
			}
	 }


	 @MainActor
	 private func exportAttendanceCSV(context: ModelContext, startDate: Date, endDate: Date) -> URL? {
			let fetchDescriptor = FetchDescriptor<AttendanceModel>()
			let attendances = (try? context.fetch(fetchDescriptor)) ?? []

				 // Filter by range
			let calendar = Calendar.current
			let filtered = attendances.filter { attendance in
				 (attendance.date >= calendar.startOfDay(for: startDate)) &&
				 (attendance.date < calendar.date(byAdding: .day, value: 1, to: endDate)!)
			}


			guard !filtered.isEmpty else {
				 print("No attendance records found in the selected range.")
				 return nil
			}

			var csvText = "Class Name,Class Description,Date,Staff,Student Names\n"
			let formatter = DateFormatter()
			formatter.dateStyle = .short
			formatter.timeStyle = .none

			let representativeClassName = filtered.first?.classModel?.name ?? "Class"

			for attendance in filtered {
				 let className = attendance.classModel?.name ?? "Unknown Class"
				 let classDesc = attendance.classModel?.classDescription ?? ""
				 let date = formatter.string(from: attendance.date)
				 let students = attendance.students.map { $0.name }.joined(separator: "; ")

				 csvText += "\"\(className)\",\"\(classDesc)\",\"\(date)\",\"\(students)\"\n"
			}

			let summary = "\nExported range: \(formatter.string(from: startDate)) - \(formatter.string(from: endDate))\n"
			csvText += summary

			let _ = representativeClassName
				 .replacingOccurrences(of: " ", with: "")
				 .replacingOccurrences(of: "/", with: "-")
				 .replacingOccurrences(of: ":", with: "-")

			let monthFormatter = DateFormatter()
			monthFormatter.dateFormat = "MMM"
			let monthString = monthFormatter.string(from: startDate)

			let fileName = "AttendanceExport\(monthString).csv"
			let tempDir = FileManager.default.temporaryDirectory
			let fileURL = tempDir.appendingPathComponent(fileName)

			do {
				 try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
				 print("✅ CSV exported to: \(fileURL.path)")
				 return fileURL
			} catch {
				 print("❌ Failed to write CSV: \(error)")
				 return nil
			}
	 }
}


struct AddStudentView: View {
	 @Environment(\.dismiss) var dismiss
	 @Environment(\.modelContext) var modelContext

	 @State private var name: String = ""
	 @State private var age: String = ""
	 @State private var level: String = ""


	 var body: some View {
			NavigationStack {
				 Form {
						Section("Name") {
							 TextField("John Doe", text: $name)
						}
						Section("Age") {
							 TextField("15", text: $age)
									.keyboardType(.numberPad)
						}
						Section("Level") {
							 TextField("Intermediate", text: $level)
						}
						
				 }
				 .navigationTitle("Add")
				 .toolbar {
						ToolbarItem(placement: .confirmationAction) {
							 Button("Save") {
									if let intAge = Int(age) {
										 let student = StudentModel(

												name: name,
												age: intAge,
												level: level
										 )
										 modelContext.insert(student)

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



