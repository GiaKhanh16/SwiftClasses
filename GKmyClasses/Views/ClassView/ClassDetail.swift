

import SwiftUI
import SwiftData


struct DetailClassView: View {

	 @Query var students: [StudentModel]
	 @Query var staffs: [StaffModel]
	 @Environment(\.modelContext) var modelContext
	 @Environment(SubscriptionStatus.self) var subModel
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
	 @State private var paywall: Bool = false
	 @State private var endDate: Date = Date()
	 @State private var AISheet: Bool = false

	 private func attendanceIndex(for date: Date) -> Int {
			if let index = classModel.attendances.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
				 return index
			} else {
				 let newAttendance = AttendanceModel(
						date: date,
				    students: []
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

	 private func toggleStaff(_ staff: StaffModel) {
			if let existingLinkIndex = filteredAttendance.staffAttendances.firstIndex(
				 where: { $0.staff.staffID == staff.staffID }
			) {
						// Remove existing StaffAttendanceModel link
				 let existingLink = filteredAttendance.staffAttendances[existingLinkIndex]
				 filteredAttendance.staffAttendances.remove(at: existingLinkIndex)

						// Also remove it from the staff side
				 if let staffIndex = staff.staffAttendances.firstIndex(where: { $0.id == existingLink.id }) {
						staff.staffAttendances.remove(at: staffIndex)
				 }

				 modelContext.delete(existingLink)

			} else {
				 let newLink = StaffAttendanceModel(
						staff: staff,
						attendance: filteredAttendance
				 )
				 filteredAttendance.staffAttendances.append(newLink)
				 staff.staffAttendances.append(newLink)
			}

			do {
				 try modelContext.save()
			} catch {
				 print("Failed to toggle staff: \(error)")
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
						}
				 }

				 Section {
						TextField("Search Attendee", text: $searchText)
						ForEach( studentList, id: \.studentID) { student in
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
						Text("Search first before you add a new one.")
							 .font(.caption)
				 }



				 Section {
						TextField("Search Staff", text: $staffString)
						if staffString.isEmpty {
							 ForEach(filteredAttendance.staffAttendances) { staffAttendance in
									HStack {
										 Text(staffAttendance.staff.name)
												.font(.headline)
										 Spacer()
										 StaffDurationPicker(
												staffAttendance: staffAttendance
										 )
									}
									.padding(.vertical, 4)
							 }

						} else {
							 ForEach(staffList, id: \.staffID) { staff in

									HStack(alignment: .center) {
										 Text(staff.name)
												.font(.headline)
										 Spacer()
										 if let link = filteredAttendance.staffAttendances.first(where: { $0.staff.staffID == staff.staffID }) {
												StaffDurationPicker(staffAttendance: link)
										 }

										 Button {
												withAnimation {
													 toggleStaff(staff)
												}
										 } label: {
												Image(systemName:
																 filteredAttendance.staffAttendances.contains(where: { $0.staff.staffID == staff.staffID })
															? "checkmark.circle.fill"
															: "circle"
												)
												.foregroundColor(
													 filteredAttendance.staffAttendances.contains(where: { $0.staff.staffID == staff.staffID })
													 ? .green
													 : .gray
												)
										 }
										 .offset(y: -1)

									}
									.padding(.vertical, 4)
							 }

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
						if subModel.notSubscribed == false {
							 paywall.toggle()
						} else {
							 AISheet.toggle()
						}

				 } label: {
						Image(systemName: "apple.intelligence")
				 }



				 Button {
//						if subModel.notSubscribed == false {
//							 paywall.toggle()
//						} else {
							 shareMenu.toggle()
//						}

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
				 AddStudentView2 { newStudent in
						toggleStudent(newStudent)
				 }
			}
			.sheet(isPresented: $paywall) {
				 Paywall()
			}
			.sheet(isPresented: $AISheet) {
				 TheOverview()
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

	 private var staffList: [StaffModel] {
				 return staffs.filter {
						$0.name.localizedCaseInsensitiveContains(staffString)
			}
	 }

	 @MainActor
	 func exportAttendanceCSV(context: ModelContext, startDate: Date, endDate: Date) -> URL? {
			let targetClassID = classModel.classID
			let calendar = Calendar.current
			let startOfDay = calendar.startOfDay(for: startDate)
			let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate

			let fetchDescriptor = FetchDescriptor<AttendanceModel>(
				 predicate: #Predicate<AttendanceModel> { attendance in
						attendance.classModel?.classID == targetClassID &&
						attendance.date >= startOfDay &&
						attendance.date < endOfDay
				 }
			)

  
			let filtered = (try? context.fetch(fetchDescriptor)) ?? []

			guard !filtered.isEmpty else {
				 print("No attendance records found in the selected range.")
				 return nil
			}

			var csvText = ""

			if let className = filtered.first?.classModel?.name {
				 csvText += "Class Name: \(className)\n"
			}

			if let classDesc = filtered.first?.classModel?.classDescription, !classDesc.isEmpty {
				 csvText += "Description: \(classDesc)\n"
			}
			let formatter = DateFormatter()
			formatter.dateStyle = .short
			formatter.timeStyle = .none


			csvText += "\nExported range: \(formatter.string(from: startDate)) - \(formatter.string(from: endDate))\n"

			csvText += "\nDate,Staff,Students\n"


			for attendance in filtered {
				 let date = formatter.string(from: attendance.date)
				 let staffNames = attendance.staffAttendances
						.compactMap { $0.staff.name }
						.joined(separator: "; ")
				 let studentNames = attendance.students
						.map { $0.name }
						.joined(separator: "; ")

				 csvText += "\"\(date)\",\"\(staffNames)\",\"\(studentNames)\"\n"
			}



			let monthFormatter = DateFormatter()
			monthFormatter.dateFormat = "MMM"
			let monthString = monthFormatter.string(from: startDate)
			let formatClassName = classModel.name.replacingOccurrences(of: " ", with: "")
			let fileName = "\(formatClassName)\(monthString).csv"
			let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

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



struct AddStudentView2: View {
	 @Environment(\.dismiss) var dismiss
	 @Environment(\.modelContext) var modelContext

	 @State private var name: String = ""
	 @State private var age: String = ""
	 @State private var level: String = ""
	 var onSave: ((StudentModel) -> Void)? = nil

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
				 .navigationTitle("Add Student")
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
										 onSave?(student)
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





