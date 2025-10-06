	 //
	 //  ClassView.swift
	 //  GKAttendance
	 //
	 //  Created by Khanh Nguyen on 10/4/25.
	 //
import SwiftUI
import SwiftData

struct ClassView: View {
	 @State private var addClassBool: Bool = false
	 @Query var classes: [ClassModel]

	 var body: some View {
			NavigationStack {
				 List(classes) { item in
						NavigationLink(value: item) {
							 VStack(alignment: .leading, spacing: 9) {
									Text(item.name)
									Text(item.classDescription)
										 .font(.footnote)
										 .foregroundStyle(.gray)
							 }
						}
				 }
				 .navigationTitle("Classes")
				 .toolbar {
						Button {
							 withAnimation {
									addClassBool.toggle()
							 }
						} label: {
							 Image(systemName: "plus")
						}
				 }
				 .navigationDestination(for: ClassModel.self) { classModel in
						DetailClassView(classModel: classModel)
							 .toolbar(.hidden, for: .tabBar)
				 }
				 .sheet(isPresented: $addClassBool) {
						AddClassView()
				 }
			}
	 }
}

struct AddClassView: View {
	 @State private var nameText: String = ""
	 @State private var descriptionText: String = ""

	 @Environment(\.dismiss) var dismiss
	 @Environment(\.modelContext) var modelContext

	 var body: some View {
			NavigationStack {
				 Form {
						Section("Name") {
							 TextField("Advance morning class", text: $nameText)
						}
						Section("Description") {
							 TextField("Only 10 UTR and above...", text: $descriptionText)
						}
				 }
				 .navigationTitle("Add")
				 .toolbar {
						Button {
							 addClass()
							 dismiss()
						} label: {
							 Image(systemName: "checkmark")
						}
				 }
			}
	 }

	 func addClass() {
			let newClass = ClassModel(
				 name: nameText,
				 classDescription: descriptionText,
				 attendances: []
			)
			modelContext.insert(newClass)

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

	 @State var allAttendance: Bool = false

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
				 Section("Name and Description") {
						TextField("Advance morning class", text: $classModel.name)
						TextField("Only 10 UTR and above...", text: $classModel.classDescription)
				 }

				 Section {
						DatePicker(
							 "Select Date:",
							 selection: $selectDate,
							 displayedComponents: .date
						).onChange(of: selectDate) { _, newDate in
							 _ = attendanceIndex(for: newDate)
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
							 filteredAttendance.students.append(StudentModel(name: "Khanh", age: 15, level: "Strong"))
						} label: {
							 Label("Add a New Student", systemImage: "plus")
						}
						Button {
							 filteredAttendance.students.append(StudentModel(name: "Alex", age: 15, level: "Strong"))
						} label: {
							 Label("Add a New Student", systemImage: "plus")
						}


				 } header: {
						Text("Students List")
							 .font(.headline)
				 } footer: {
						Text("Search for student first before you add a new student.")
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
