import SwiftUI
import SwiftData

struct ClassView: View {
	 @Environment(\.modelContext) var modelContext
	 @State private var path: [ClassModel] = []
	 @Query var classes: [ClassModel]

	 var body: some View {
			NavigationStack(path: $path) {   
				 List {
						ForEach(classes) { item in
							 NavigationLink(value: item) {
									VStack(alignment: .leading, spacing: 9) {
										 Text(item.name)
										 Text(item.classDescription)
												.font(.footnote)
												.foregroundStyle(.gray)
									}
							 }
						}
						.onDelete(perform: deleteClass)
				 }
				 .navigationTitle("Classes")
				 .toolbar {
						EditButton()
						Button {
							 withAnimation {
									let newClass = ClassModel(
										 name: "...",
										 classDescription: "...",
										 attendances: []
									)
									path.append(newClass)
									Task {
										 try await Task.sleep(nanoseconds: 500_000_000)
										 modelContext.insert(newClass)
									}

							 }
						} label: {
							 Image(systemName: "plus")
						}
				 }
				 .navigationDestination(for: ClassModel.self) { classModel in
						DetailClassView(classModel: classModel)
							 .toolbar(.hidden, for: .tabBar)


				 }
			}
	 }
	 private func deleteClass(at offsets: IndexSet) {
			for index in offsets {
				 let classToDelete = classes[index]
				 modelContext.delete(classToDelete)
			}
				 try? modelContext.save()
	 }
}






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
	 @State var allAttendance: Bool = false
	 @State private var saveWorkItem: DispatchWorkItem?

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
						allAttendance.toggle()
				 } label: {
						Image(systemName: "testtube.2")
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
	 
}

#Preview {
	 TabScreen()
			.modelContainer(for: [ClassModel.self, StudentModel.self], inMemory: true)
}
