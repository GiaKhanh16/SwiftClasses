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
	 @Environment(\.modelContext) var modelContext
	 @Bindable var staff: StaffModel

	 @State private var confirmationShown: Bool = false
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
							 if staff.staffAttendances.isEmpty {
									Text("No attendance records yet.")
										 .foregroundStyle(.secondary)
							 } else {
									ForEach(
										 staff.staffAttendances.sorted(by: { $0.attendance.date > $1.attendance.date })
									) { staffAttendance in
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
									deleteStudent(staff)
									dismiss()
							 }
							 Button("No") { confirmationShown.toggle() }
						}

				 }

			}
	 }

	 private func deleteStudent(_ staff: StaffModel) {
			do {
				 modelContext.delete(staff)
				 try modelContext.save()
				 dismiss()
			} catch {
				 print(error)
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



