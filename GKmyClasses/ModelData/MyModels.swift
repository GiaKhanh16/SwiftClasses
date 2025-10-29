import SwiftUI
import SwiftData

@Model
class ClassModel {
	 @Attribute var classID: UUID = UUID()
	 var name: String = ""
	 var classDescription: String = ""
	 @Relationship(deleteRule: .cascade) var attendances: [AttendanceModel] = []

	 init(
			name: String,
			classDescription: String,
			attendances: [AttendanceModel] = []
	 ) {
			self.classID = UUID()
			self.name = name
			self.classDescription = classDescription
			self.attendances = attendances
	 }
}

@Model
class StudentModel {
	 @Attribute var studentID: UUID = UUID()
	 var name: String = ""
	 var age: Int = 0
	 var level: String = ""

	 @Relationship(inverse: \AttendanceModel.students)
	 var attendances: [AttendanceModel] = []

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
	 @Attribute var id: UUID = UUID()
	 var date: Date = Date.now

	 @Relationship(inverse: \ClassModel.attendances)
	 var classModel: ClassModel?

	 @Relationship
	 var students: [StudentModel] = []

	 @Relationship(deleteRule: .cascade, inverse: \StaffAttendanceModel.attendance)
	 var staffAttendances: [StaffAttendanceModel] = []

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
	 @Attribute var staffID: UUID = UUID()
	 var name: String = ""
	 var note: String = ""

	 @Relationship(deleteRule: .cascade, inverse: \StaffAttendanceModel.staff)
	 var staffAttendances: [StaffAttendanceModel] = []

	 init(name: String, note: String, staffAttendances: [StaffAttendanceModel] = []) {
			self.staffID = UUID()
			self.name = name
			self.note = note
			self.staffAttendances = staffAttendances
	 }
}

@Model
class StaffAttendanceModel {
	 @Attribute var id: UUID = UUID()

	 @Relationship var staff: StaffModel?
	 @Relationship var attendance: AttendanceModel?

	 var hour: Int = 0
	 var minute: Int = 0

	 init(staff: StaffModel, attendance: AttendanceModel, hour: Int = 0, minute: Int = 0) {
			self.id = UUID()
			self.staff = staff
			self.attendance = attendance
			self.hour = hour
			self.minute = minute
	 }
	 var staffName: String {
			staff?.name ?? "No Staff"
	 }
	 var staffIDValue: UUID {
			staff?.staffID ?? UUID() // or some default/fallback
	 }
	 var attendanceDate: Date {
			attendance?.date ?? Date.now
	 }
	 var className: String {
			attendance?.classModel?.name ?? "No Class"
	 }

}

