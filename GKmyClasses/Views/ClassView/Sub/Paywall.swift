import SwiftUI
import SwiftData

	 // MARK: - Child View: Duration Picker for Staff
struct StaffDurationPicker: View {
	 @Bindable var staffAttendance: StaffAttendanceModel

	 var body: some View {
			HStack(spacing: -10) { // push pickers closer together
				 Picker("", selection: $staffAttendance.hour) {
						ForEach(0..<24, id: \.self) { Text("\($0) h") }
				 }
				 .accentColor(.primary)
				 .pickerStyle(.menu)
				 .padding(.horizontal, 0)
				 .frame(maxWidth: 70) // narrow width for tighter fit

				 Picker("", selection: $staffAttendance.minute) {
						ForEach([0, 15, 30, 45], id: \.self) { Text("\($0)") }
				 }
				 .accentColor(.primary)
				 .pickerStyle(.menu)
				 .padding(.horizontal, 0)
				 .frame(maxWidth: 60)
			}
			
	 }
}

//
//	 // MARK: - Parent View
//struct StaffDurationListView: View {
//	 @Query var staffs: [StaffModel]
//	 @State private var staffess: [StaffModel] = [
//			StaffModel(name: "Alice", note: "Math Teacher", hour: 1, minute: 0),
//			StaffModel(name: "Bob", note: "Science Teacher", hour: 2, minute: 0),
//			StaffModel(name: "Charlie", note: "English Teacher", hour: 1, minute: 30)
//	 ]
//
//	 var totalMinutes: Int {
//			staffs.reduce(0) { $0 + $1.hour * 60 + $1.minute }
//	 }
//
//	 var body: some View {
//			VStack(spacing: 20) {
//
//				 ForEach(staffess, id: \.staffID) { staff in
//						HStack {
//							 Text(staff.name)
//									.bold()
//
//							 Spacer()
//							 StaffDurationPicker(staff: staff)
//						}
//				 }
//
//
//			}
//			.padding()
//	 }
//}
//
//	 // MARK: - Preview
//struct StaffDurationListView_Previews: PreviewProvider {
//	 static var previews: some View {
//			StaffDurationListView()
//				 .modelContainer(for: StaffModel.self)
//	 }
//}
//
//
//struct ContentView2: View {
//	 @State private var selectedFruit = "Apple"
//	 let fruits = ["Apple", "Banana", "Orange"]
//
//	 var body: some View {
//			VStack {
//				 Picker(selection: $selectedFruit) {
//						ForEach(fruits, id: \.self) { fruit in
//							 Text(fruit)
//									.font(.body) // Customize text within the menu
//									.accentColor(.orange)
//									.tag(fruit)
//						}
//				 } label: {
//						HStack {
//							 Text("Choose a fruit:")
//							 Text(selectedFruit)
//									.fontWeight(.bold) // Customize text of the picker label
//						}
//						.padding()
//						.background(Color.yellow.opacity(0.2))
//						.cornerRadius(8)
//				 }
//				 .pickerStyle(.menu)
//			}
//	 }
//}
