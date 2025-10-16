
import SwiftUI
import SwiftData

struct AllAttendancesView: View {
	 var attendance: [AttendanceModel]

	 var body: some View {
			VStack {
				 ForEach(attendance) {item in
						HStack {
							 Text(item.date, style: .date)
							 ForEach(item.students) { student in
									Text(student.name)
							 }
							 Text(item.staff)
						}
				 }
			}
	 }
}
