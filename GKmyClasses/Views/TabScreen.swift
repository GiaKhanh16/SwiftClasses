

import SwiftUI
import SwiftData

struct TabScreen: View {
	 var body: some View {
			TabView {
				 Tab("Attendance", systemImage: "calendar") {
						ClassView()
				 }

				 Tab("Students", systemImage: "person.2") {
						StudentView()
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
