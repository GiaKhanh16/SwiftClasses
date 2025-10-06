	 //
	 //  MyModel.swift
	 //  GKmyClasses
	 //
	 //  Created by Khanh Nguyen on 10/6/25.
	 //

import SwiftUI
import SwiftData

@Model
class AttendanceModel {
	 @Attribute(.unique) var id: UUID
	 var date: Date
	 var staff: String

	 @Relationship(inverse: \ClassModel.attendances)
	 var classModel: ClassModel?

	 @Relationship var students: [StudentModel]

	 init(
			date: Date,
			staff: String,
			students: [StudentModel] = [],
			classModel: ClassModel? = nil
	 ) {
			self.id = UUID()
			self.date = date
			self.staff = staff
			self.students = students
			self.classModel = classModel
	 }
}


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
