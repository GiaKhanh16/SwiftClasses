//
//  TestView.swift
//  GKmyClasses
//
//  Created by Khanh Nguyen on 10/8/25.
//

import SwiftUI
import Charts

	 // MARK: - Sample Data
let sampleStudents: [StudentModel] = [
	 StudentModel(name: "Khanh", age: 27, level: "Advanced"),
	 StudentModel(name: "Jeson", age: 24, level: "Beginner"),
	 StudentModel(name: "Anna", age: 22, level: "Intermediate")
]

let sampleClasses: [ClassModel] = [
	 ClassModel(name: "Math", classDescription: "Algebra and Geometry"),
	 ClassModel(name: "Science", classDescription: "Physics and Chemistry"),
	 ClassModel(name: "English", classDescription: "Grammar and Literature")
]

	 // Linking attendances
func generateSampleAttendances() {
	 let attendance1 = AttendanceModel(date: Date(), staff: "Mr. Smith", students: [sampleStudents[0], sampleStudents[1]], classModel: sampleClasses[0])
	 let attendance2 = AttendanceModel(date: Date().addingTimeInterval(-86400), staff: "Ms. Johnson", students: [sampleStudents[0], sampleStudents[2]], classModel: sampleClasses[1])
	 let attendance3 = AttendanceModel(date: Date().addingTimeInterval(-172800), staff: "Mr. Smith", students: [sampleStudents[1], sampleStudents[2]], classModel: sampleClasses[2])

	 sampleStudents[0].attendances = [attendance1, attendance2]
	 sampleStudents[1].attendances = [attendance1, attendance3]
	 sampleStudents[2].attendances = [attendance2, attendance3]

	 sampleClasses[0].attendances = [attendance1]
	 sampleClasses[1].attendances = [attendance2]
	 sampleClasses[2].attendances = [attendance3]
}

	 // MARK: - Stats View
struct StatsView: View {
	 var students: [StudentModel]
	 var classes: [ClassModel]

	 var totalStudents: Int { students.count }
	 var totalClasses: Int { classes.count }
	 var totalAttendances: Int { students.reduce(0) { $0 + $1.attendances.count } }

	 var mostActiveStudent: StudentModel? {
			students.max(by: { $0.attendances.count < $1.attendances.count })
	 }

	 var mostAttendedClass: ClassModel? {
			classes.max(by: { $0.attendances.count < $1.attendances.count })
	 }

	 var body: some View {
			ScrollView {
				 VStack(spacing: 20) {
							 // MARK: Overview Cards
						HStack(spacing: 16) {
							 StatCard(title: "Students", value: "\(totalStudents)", color: .blue)
							 StatCard(title: "Classes", value: "\(totalClasses)", color: .green)
							 StatCard(title: "Attendances", value: "\(totalAttendances)", color: .orange)
						}
						.padding(.horizontal)

							 // MARK: Fun Facts
						VStack(alignment: .leading, spacing: 16) {
							 Text("Fun Facts")
									.font(.title2)
									.bold()
									.padding(.horizontal)

							 if let student = mostActiveStudent {
									FunFactCard(text: "\(student.name) attended the most classes: \(student.attendances.count)")
							 }

							 if let classModel = mostAttendedClass {
									FunFactCard(text: "Most popular class: \(classModel.name) (\(classModel.attendances.count) attendances)")
							 }

							 FunFactCard(text: "Average attendance per class: \(String(format: "%.1f", averageAttendancePerClass()))")

						}

							 // MARK: Attendance Chart
						VStack(alignment: .leading) {
							 Text("Attendance Trend")
									.font(.title2)
									.bold()
									.padding(.horizontal)

							 Chart {
									ForEach(classes, id: \.classID) { classModel in
										 BarMark(
												x: .value("Class", classModel.name),
												y: .value("Attendances", classModel.attendances.count)
										 )
									}
							 }
							 .frame(height: 200)
							 .padding()
						}
				 }
				 .padding(.top)
			}
			.navigationTitle("Statistics")
	 }

	 func averageAttendancePerClass() -> Double {
			guard !classes.isEmpty else { return 0 }
			let total = classes.reduce(0) { $0 + $1.attendances.count }
			return Double(total) / Double(classes.count)
	 }
}

	 // MARK: - Cards
struct StatCard: View {
	 var title: String
	 var value: String
	 var color: Color

	 var body: some View {
			VStack {
				 Text(value)
						.font(.title)
						.bold()
						.foregroundColor(.white)
				 Text(title)
						.foregroundColor(.white.opacity(0.8))
			}
			.frame(maxWidth: .infinity)
			.padding()
			.background(color.gradient)
			.cornerRadius(15)
			.shadow(radius: 5)
	 }
}

struct FunFactCard: View {
	 var text: String

	 var body: some View {
			Text(text)
				 .padding()
				 .frame(maxWidth: .infinity, alignment: .leading)
				 .background(.ultraThinMaterial)
				 .cornerRadius(12)
				 .padding(.horizontal)
	 }
}

	 // MARK: - Preview
struct StatsView_Previews: PreviewProvider {
	 static var previews: some View {
			NavigationStack {
				 StatsView(students: sampleStudents, classes: sampleClasses)
			}
	 }
}
