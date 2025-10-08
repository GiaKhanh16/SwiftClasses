

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
				 Tab("Overview", systemImage: "apple.intelligence") {
						TheObserver()
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
