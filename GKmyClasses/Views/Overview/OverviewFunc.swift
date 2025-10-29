import SwiftUI
import SwiftData

@MainActor @Observable
class AttendanceExportViewModel  {

	 func exportClassAttendanceText(for classModel: ClassModel, startDate: Date, endDate: Date) -> String? {
			let calendar = Calendar.current
			let startOfDay = calendar.startOfDay(for: startDate)
			let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate

			let filtered = classModel.attendances.filter {
				 $0.date >= startOfDay && $0.date < endOfDay
			}

			guard !filtered.isEmpty else { return nil }

			let formatter = DateFormatter()
			formatter.dateStyle = .short
			formatter.timeStyle = .none

			var text = ""
			text += "Class Name: \(classModel.name)\n"

			for attendance in filtered {
				 let date = formatter.string(from: attendance.date)
				 let staffNames = attendance.staffAttendances
						.compactMap { $0.staffName }  // use the computed property
						.joined(separator: "; ")
				 let studentNames = attendance.students.map { $0.name }.joined(separator: "; ")

				 if staffNames.isEmpty && studentNames.isEmpty { continue }
				 text += "Date: \(date) |Staff: \(staffNames) |Students: \(studentNames)\n"
			}

			return text
	 }

			// MARK: - Export Staff Attendance
	 func exportStaffAttendanceText(for staff: StaffModel, startDate: Date, endDate: Date) -> String? {
			let calendar = Calendar.current
			let start = calendar.startOfDay(for: startDate)
			let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!

			let filteredAttendances = staff.staffAttendances
				 .sorted { $0.attendanceDate > $1.attendanceDate }
				 .filter { sa in
						let date = sa.attendanceDate
						return date >= start && date < end
				 }

			guard !filteredAttendances.isEmpty else { return nil }

			let formatter = DateFormatter()
			formatter.dateStyle = .short
			formatter.timeStyle = .none

			var text = ""
			text += "Staff Name: \(staff.name)\n"

			for staffAttendance in filteredAttendances {
//				 let attendance = staffAttendance.attendance
				 let className = staffAttendance.className
				 let date = formatter.string(from: staffAttendance.attendanceDate)  // use computed property
				 let duration = String(format: "%.2f", Double(staffAttendance.hour) + Double(staffAttendance.minute)/60.0)
				 text += "Class name: \(className) |Date: \(date) |Duration: \(duration) Hrs \n"
			}

			return text
	 }

	 func exportStudentAttendanceText(for student: StudentModel, startDate: Date, endDate: Date) -> String? {
			let calendar = Calendar.current
			let start = calendar.startOfDay(for: startDate)
			let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!

			let filteredAttendances = student.attendances
				 .filter { $0.date >= start && $0.date < end }
				 .sorted { $0.date > $1.date }

			guard !filteredAttendances.isEmpty else { return nil }

			let formatter = DateFormatter()
			formatter.dateStyle = .short
			formatter.timeStyle = .none

			var text = ""
			text += "Student Name: \(student.name)\n"

			for attendance in filteredAttendances {
				 let className = attendance.classModel?.name ?? "Unknown"
				 let date = formatter.string(from: attendance.date)
				 text += "Class name: \(className) |Date: \(date)\n"
			}

			return text
	 }
}
