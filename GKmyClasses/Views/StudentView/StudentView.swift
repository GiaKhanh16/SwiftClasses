	 //
	 //  StudentView.swift
	 //  GKAttendance
	 //
	 //  Created by Khanh Nguyen on 10/4/25.
	 //
import SwiftUI
import SwiftData

struct StudentView: View {
	 @State private var searchable: String = ""
	 @State private var addStudentBool: Bool = false
	 @Query var students: [StudentModel]
	 var body: some View {
			NavigationStack {
				 List(students) { student in
						NavigationLink(value: student) {
							 VStack(alignment: .leading, spacing: 8) {
									Text(student.name)

									Text(String(student.age))
										 .font(.footnote)
										 .foregroundStyle(.gray)
							 }
						}
				 }
				 .navigationTitle("Students")
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
}

struct StudentDetailView: View {
	 @Environment(\.dismiss) var dismiss
	 @Environment(\.modelContext) var modelContext
	 @Bindable var student: StudentModel

	 @State private var confirmationShown: Bool = false
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
							 if student.attendances.isEmpty {
									Text("No attendance records yet.")
										 .foregroundStyle(.secondary)
							 } else {
									ForEach(student.attendances.sorted(by: { $0.date > $1.date })) { attendance in
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
						}
				 }
				 .listSectionSpacing(.custom(0))
				 .navigationTitle("Details")
				 .toolbar {

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
							 Button("No") { confirmationShown.toggle() }
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



