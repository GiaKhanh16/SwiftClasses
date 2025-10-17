

import SwiftUI
import SwiftData


struct DetailClassView: View {

	 @Query var students: [StudentModel]
	 @Environment(\.modelContext) var modelContext
	 @Environment(\.dismiss) var dismiss
	 @Bindable var classModel: ClassModel
	 @State private var confirmationShown: Bool = false
	 @State private var addStudentBool = false
	 @State private var searchText: String = ""
	 @State private var selectDate = Date()
	 @State private var selectedStudents: [StudentModel] = []
	 @State private var staffString: String = ""
	 @State private var allAttendance: Bool = false
	 @State private var saveWorkItem: DispatchWorkItem?
	 @State private var shareMenu: Bool = false

	 @State private var startDate: Date = Date()
	 @State private var endDate: Date = Date()


	 private func attendanceIndex(for date: Date) -> Int {
			if let index = classModel.attendances.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
				 return index
			} else {
				 let newAttendance = AttendanceModel(
						date: date,
						staff: "", students: []
				 )
				 classModel.attendances.append(newAttendance)
				 return classModel.attendances.count - 1
			}

	 }

	 private var filteredAttendance: AttendanceModel {

			let index = attendanceIndex(for: selectDate)
			return classModel.attendances[index]

	 }

	 private func toggleStudent(_ student: StudentModel) {

			if let index = filteredAttendance.students.firstIndex(where: { $0.studentID == student.studentID }) {

				 filteredAttendance.students.remove(at: index)
				 if let attendanceIndex = student.attendances.firstIndex(where: { $0.id == filteredAttendance.id }) {
						student.attendances.remove(at: attendanceIndex)
				 }

			} else {

				 filteredAttendance.students.append(student)
				 student.attendances.append(filteredAttendance)

			}

			do {
				 try modelContext.save()
			} catch {
				 print("Failed to toggle student: \(error)")
			}
	 }



	 var body: some View {
			Form {
				 Section {
						TextField("Advance morning class", text: $classModel.name)
						TextField("Only 10 UTR and above...", text: $classModel.classDescription)
				 }
				 header: {
						Text("Name and Description")
							 .font(.callout)
							 .fontWeight(.semibold)
				 }

				 Section {
						DatePicker(
							 "Select Date:",
							 selection: $selectDate,
							 displayedComponents: .date
						).onChange(of: selectDate) { _, newDate in
							 let _ = attendanceIndex(for: newDate)
							 staffString = filteredAttendance.staff
							 if filteredAttendance.staff.isEmpty {
									staffString = ""
							 }

						}
				 }

				 Section {
						TextField("Search Students", text: $searchText)
						ForEach(
							 studentList,
							 id: \.studentID
						) { student in
							 HStack {
									VStack(alignment: .leading) {
										 Text(student.name)
												.font(.headline)
										 Text("Age: \(student.age), Level: \(student.level)")
												.font(.subheadline)
												.foregroundStyle(.secondary)
									}

									Spacer()

									Button {
										 withAnimation {
												toggleStudent(student)
										 }
									} label: {
										 if filteredAttendance.students.contains(where: { $0.studentID == student.studentID }) {
												Image(systemName: "checkmark.circle.fill")
													 .foregroundColor(.green)
										 } else {
												Image(systemName: "circle")
													 .foregroundColor(.gray)
										 }

									}
							 }
							 .padding(.vertical, 4)
						}
						Button {
							 addStudentBool.toggle()
						} label: {
							 Label("Add a New Student", systemImage: "plus")
						}



				 } header: {
						Text("Attendance")
							 .font(.callout)
							 .fontWeight(.semibold)
				 } footer: {
						Text("Search for student first before you add a new student.")
							 .font(.caption)
				 }
				 Section {
						TextField("Coaches...", text: $staffString)
							 .onChange(of: staffString) { _, newValue in
									filteredAttendance.staff = newValue

									saveWorkItem?.cancel()

									let workItem = DispatchWorkItem {
										 do {
												try modelContext.save()
												print("Staff saved ✅")
										 } catch {
												print("Failed to save staff: \(error)")
										 }
									}
									saveWorkItem = workItem
									DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: workItem)
							 }


				 } header: {
						Text("Staff")
							 .font(.callout)
							 .fontWeight(.semibold)
				 }

			}
			.navigationTitle("Details")
			.toolbar {


				 Button {
						shareMenu.toggle()
				 } label: {
						Image(systemName: "square.and.arrow.up")
				 }
				 .popover(
						isPresented: $shareMenu,
						attachmentAnchor: .point(.bottomTrailing),
						content: {
							 VStack(alignment: .leading){

									DatePicker(
										 "From",
										 selection: $startDate,
										 displayedComponents: .date
									)

									DatePicker(
										 "To",
										 selection: $endDate,
										 displayedComponents: .date
									)

									if let exportURL = exportAttendanceCSV(
										 context: modelContext,
										 startDate: startDate,
										 endDate: endDate
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
						allAttendance.toggle()
				 } label: {
						Image(systemName: "line.3.horizontal.decrease")
				 }

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
							 deleteClass(classModel)
							 dismiss()
						}
						Button("No") { confirmationShown.toggle() }
				 }
			}
			.sheet(isPresented: $addStudentBool) {
				 AddStudentView()
			}
			.sheet(isPresented: $allAttendance) {
				 AllAttendancesView(attendance: classModel.attendances)
			}
	 }

	 private func deleteClass(_ classModel: ClassModel) {
			do {
				 modelContext.delete(classModel)
				 try modelContext.save()
				 dismiss()
			} catch {
				 print(error)
			}
	 }


	 private var studentList: [StudentModel] {
			if searchText.isEmpty {
				 return 	filteredAttendance.students
			} else {
				 return students.filter {
						$0.name.localizedCaseInsensitiveContains(searchText)
				 }
			}
	 }

	 @MainActor
	 func exportAttendanceCSV(context: ModelContext, startDate: Date, endDate: Date) -> URL? {
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
				 let staff = attendance.staff
				 let students = attendance.students.map { $0.name }.joined(separator: "; ")

				 csvText += "\"\(className)\",\"\(classDesc)\",\"\(date)\",\"\(staff)\",\"\(students)\"\n"
			}

			let summary = "\nExported range: \(formatter.string(from: startDate)) - \(formatter.string(from: endDate))\n"
			csvText += summary

			let safeClassName = representativeClassName
				 .replacingOccurrences(of: " ", with: "")
				 .replacingOccurrences(of: "/", with: "-")
				 .replacingOccurrences(of: ":", with: "-")

			let monthFormatter = DateFormatter()
			monthFormatter.dateFormat = "MMM"
			let monthString = monthFormatter.string(from: startDate)

			let fileName = "\(safeClassName)-\(monthString).csv"
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

#Preview {
	 TabScreen()
}
