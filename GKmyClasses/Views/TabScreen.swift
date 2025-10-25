

import SwiftUI
import SwiftData

struct TabScreen: View {
	 var body: some View {
			TabView {
				 Tab("Attendance", systemImage: "list.bullet.clipboard") {
						ClassView()
				 }

				 Tab("Attendees", systemImage: "figure.run") {
						StudentView()
				 }
				 Tab("Staff", systemImage: "person.3.fill") {
						StaffView()
				 }
			}
	 }
}


#Preview {
	 TabScreen()
			.modelContainer(
				 for: ClassModel.self
			)

}
