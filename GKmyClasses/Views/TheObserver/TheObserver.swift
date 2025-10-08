import SwiftUI
import SwiftData
import FoundationModels

struct TheObserver: View {
	 @Environment(\.modelContext) private var modelContext
	 @State var userPrompt: String = ""
	 @State private var attendanceText: String = "" // raw data export
	 @State private var aiAnswer: String = ""       // AI's response
	 @State private var isLoading: Bool = false
	 @State private var isRotating = false


	 var body: some View {
			NavigationStack {
				 Text("Overview")
						.font(.largeTitle)
						.bold()
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding()

				 bottomTextField()

				 ScrollView(.vertical) {
						VStack(alignment: .leading, spacing: 15) {


							 Text("AI Answer:")
									.bold()
							 Text(aiAnswer)
									.font(.system(size: 16))
						}
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding()
				 }
				 .safeAreaPadding(10)
				 .onAppear {
						attendanceText = exportAttendanceData(context: modelContext)
				 }
			}
	 }

	 func exportAttendanceData(context: ModelContext) -> String {
			let fetchDescriptor = FetchDescriptor<AttendanceModel>()
			let attendances = (try? context.fetch(fetchDescriptor)) ?? []

				 // Set up a DateFormatter for human-readable dates
			let formatter = DateFormatter()
			formatter.dateStyle = .long   // This gives "October 8, 2025"
			formatter.timeStyle = .none

			var summary = ""
			for attendance in attendances {
				 let studentNames = attendance.students.map { $0.name }.joined(separator: ", ")
				 let dateString = formatter.string(from: attendance.date)
				 summary += "Attendance Date: \(dateString) — Attendance Names: \(studentNames)\n"
			}
			return summary
	 }


	 @ViewBuilder
	 func bottomTextField() -> some View {
			HStack(spacing: 20) {
				 TextField("Ask a question...", text: $userPrompt)
						.padding(.vertical, 5)
						.padding(.leading, 15)
						.glassEffect()
				 if isLoading {
						Image(systemName: "apple.intelligence")
							 .font(.title2)
							 .rotationEffect(.degrees(isRotating ? 360 : 0))
							 .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
							 .onAppear {
									isRotating = true
							 }
				 } else {
						Button("Send") {
							 generateAnswer()
						}

				 }
			}
			.padding(.horizontal, 15)
	 }

	 func generateAnswer() {
			isLoading.toggle()
			Task {
				 do {
						let instructions = """
You are an attendance assistant. 
Here is the attendance record in structured format: 
\(attendanceText)

Instructions:
- Search the record and answer freely and confidencely.
"""
						let options = GenerationOptions(temperature: 2.0)
						let session = LanguageModelSession(instructions: instructions)
						let response = try await session.respond(to: userPrompt,     options: options)

						await MainActor.run {
//							 isLoading = false
							 isLoading.toggle()
							 aiAnswer = response.content
							 userPrompt = ""

						}
				 } catch {
						await MainActor.run {
							 aiAnswer = "Error: \(error.localizedDescription)"
						}
				 }
			}
	 }
}

#Preview {
	 TabScreen()
			.modelContainer(for: [ClassModel.self, StudentModel.self], inMemory: true)
}
