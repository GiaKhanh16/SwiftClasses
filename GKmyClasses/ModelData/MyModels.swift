import SwiftUI
import SwiftData

@Model
class ClassModel {
	 @Attribute(.unique) var classID: UUID
	 var name: String
	 var classDescription: String
	 var staff: String

	 @Relationship var attendances: [AttendanceModel]

	 init(
			name: String,
			classDescription: String,
			staff: String = "",
			attendances: [AttendanceModel] = []
	 ) {
			self.classID = UUID()
			self.name = name
			self.classDescription = classDescription
			self.staff = staff
			self.attendances = attendances
	 }
}

@Model
class StudentModel {
	 @Attribute(.unique) var studentID: UUID
	 var name: String
	 var age: Int
	 var level: String

	 @Relationship(inverse: \AttendanceModel.students)
	 var attendances: [AttendanceModel]

	 init(
			name: String,
			age: Int,
			level: String,
			attendances: [AttendanceModel] = []
	 ) {
			self.studentID = UUID()
			self.name = name
			self.age = age
			self.level = level
			self.attendances = attendances
	 }
}

@Model
class AttendanceModel {
	 @Attribute(.unique) var id: UUID
	 var date: Date

	 @Relationship(inverse: \ClassModel.attendances)
	 var classModel: ClassModel?

	 @Relationship
	 var students: [StudentModel]

			// ✅ Cascade here
	 @Relationship(deleteRule: .cascade, inverse: \StaffAttendanceModel.attendance)
	 var staffAttendances: [StaffAttendanceModel]

	 init(
			date: Date,
			students: [StudentModel] = [],
			staffAttendances: [StaffAttendanceModel] = [],
			classModel: ClassModel? = nil
	 ) {
			self.id = UUID()
			self.date = date
			self.students = students
			self.classModel = classModel
			self.staffAttendances = staffAttendances
	 }
}

@Model
class StaffModel {
	 @Attribute(.unique) var staffID: UUID
	 var name: String
	 var note: String

			// ✅ Must cascade to satisfy uniqueness constraint rule
	 @Relationship(deleteRule: .cascade, inverse: \StaffAttendanceModel.staff)
	 var staffAttendances: [StaffAttendanceModel]

	 init(name: String, note: String, staffAttendances: [StaffAttendanceModel] = []) {
			self.staffID = UUID()
			self.name = name
			self.note = note
			self.staffAttendances = staffAttendances
	 }
}

@Model
class StaffAttendanceModel {
	 @Attribute(.unique) var id: UUID

			// mandatory relationships are fine now
	 @Relationship var staff: StaffModel
	 @Relationship var attendance: AttendanceModel

	 var hour: Int
	 var minute: Int

	 init(staff: StaffModel, attendance: AttendanceModel, hour: Int = 0, minute: Int = 0) {
			self.id = UUID()
			self.staff = staff
			self.attendance = attendance
			self.hour = hour
			self.minute = minute
	 }
}
