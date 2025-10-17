import SwiftUI
import SwiftData
import FoundationModels

struct TheOverview: View {
	 
	 @Environment(\.modelContext) private var modelContext
	 var body: some View {
			NavigationStack {
				 VStack {
						if #available(iOS 26.0, *) {
							 AppleIntelView()
						} else {
							 VStack(spacing: 20) {
									Image(systemName: "exclamationmark.triangle.fill")
										 .font(.largeTitle)
										 .foregroundStyle(.yellow)
									Text("This feature is available on iOS 26 or later.")
										 .font(.headline)
										 .multilineTextAlignment(.center)
										 .padding()
							 }
							 .padding()
						}
				 }
				 .navigationTitle("Overview")
				 .toolbar {

				 }
			}
	 }
	 
	 func exportAttendanceCSV(context: ModelContext) -> URL? {
			let fetchDescriptor = FetchDescriptor<AttendanceModel>()
			let attendances = (try? context.fetch(fetchDescriptor)) ?? []

			var csvText = "Date,Student Names\n"

			let formatter = DateFormatter()
			formatter.dateStyle = .short
			formatter.timeStyle = .none

			for attendance in attendances {
				 let dateString = formatter.string(from: attendance.date)
				 let studentNames = attendance.students.map { $0.name }.joined(separator: "; ")
				 csvText += "\"\(dateString)\",\"\(studentNames)\"\n"
			}

			let fileName = "AttendanceExport.csv"
			let tempDir = FileManager.default.temporaryDirectory
			let fileURL = tempDir.appendingPathComponent(fileName)

			do {
				 try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
				 return fileURL
			} catch {
				 print("Failed to create CSV file: \(error)")
				 return nil
			}
	 }
}

@available(iOS 26.0, *)
struct AppleIntelView: View {
	 @Environment(\.modelContext) private var modelContext
	 @State var userPrompt: String = ""
	 @State private var attendanceText: String = ""
	 @State private var aiAnswer: String = ""
	 @State private var isLoading: Bool = false
	 @State private var isRotating = false
	 @State private var selectedTab: Int = 0
	 private var model = SystemLanguageModel.default

	 var body: some View {
			NavigationStack {
				 VStack(spacing: 0) {
						switch model.availability {
							 case .available:
									OverviewPage()
										 .onAppear {
												attendanceText = exportAttendanceData(context: modelContext)
										 }

							 case .unavailable(.deviceNotEligible):
									UnavailableView(message: "Your device is not eligible for Apple Intelligence.")

							 case .unavailable(.appleIntelligenceNotEnabled):
									UnavailableView(message: "Please enable Apple Intelligence in Settings to use this feature.")

							 case .unavailable(.modelNotReady):
									UnavailableView(message: "The AI model is not ready yet. It may be downloading or initializing.")

							 case .unavailable(let other):
									UnavailableView(message: "AI unavailable: \(other)")
						}
				 }
				 .onAppear {
						attendanceText = exportAttendanceData(context: modelContext)
				 }
			}
	 }

			// MARK: - Overview Tab
	 @ViewBuilder
	 func OverviewPage() -> some View {
			VStack {
				 HStack(spacing: 20) {
							 TextField("Question on your attendances", text: $userPrompt)
									.padding(.vertical, 5)
									.padding(.leading, 15)
									.glassEffect()

						if isLoading {
							 Image(systemName: "apple.intelligence")
									.font(.title2)
									.rotationEffect(.degrees(isRotating ? 360 : 0))
									.animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
									.onAppear { isRotating = true }
						} else {
							 Button{ generateAnswer() } label: {
									Text("Send").foregroundStyle(.blue)
							 }
						}
				 }
				 .padding(.horizontal, 15)
				 .padding(.bottom, 5)
				 ScrollView(.vertical) {
						VStack(alignment: .leading, spacing: 10) {
							 Text("AI Answer:")
									.bold()
									.padding(.leading, 10)
							 if !aiAnswer.isEmpty {
									Text(aiAnswer)
										 .padding()
										 .background(.ultraThinMaterial)
										 .cornerRadius(10)
										 .font(.system(size: 16))
										 .lineSpacing(6)
							 }
						}
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding()
				 }
			}.padding(.top, 20)
	 }

	 @ViewBuilder
	 func UnavailableView(message: String) -> some View {
			VStack(spacing: 20) {
				 Image(systemName: "exclamationmark.triangle.fill")
						.font(.largeTitle)
						.foregroundStyle(.yellow)
				 Text(message)
						.font(.headline)
						.multilineTextAlignment(.center)
						.padding()
			}
			.padding()
	 }

	 func exportAttendanceData(context: ModelContext) -> String {
			let fetchDescriptor = FetchDescriptor<AttendanceModel>()
			let attendances = (try? context.fetch(fetchDescriptor)) ?? []

			let formatter = DateFormatter()
			formatter.dateStyle = .long
			formatter.timeStyle = .none

			var summary = ""
			for attendance in attendances {
				 let studentNames = attendance.students.map { $0.name }.joined(separator: ", ")
				 let dateString = formatter.string(from: attendance.date)
				 summary += "Attendance Date: \(dateString) — Attendance Names: \(studentNames)\n"
			}
			return summary
	 }



	 func generateAnswer() {
			isLoading = true
			isRotating = false
			Task {
				 do {
						let instructions = """
								You are an attendance assistant. 
								Here is the attendance record in structured format: 
								\(attendanceText)
								
								Instructions:
								- Search the record and answer freely and confidently.
								"""
						let options = GenerationOptions(temperature: 2.0)
						let session = LanguageModelSession(instructions: instructions)
						let response = try await session.respond(to: userPrompt, options: options)

						await MainActor.run {
							 aiAnswer = response.content
							 userPrompt = ""
							 isLoading = false
							 isRotating = false
						}
				 } catch {
						await MainActor.run {
							 aiAnswer = "Error: \(error.localizedDescription)"
							 isLoading = false
							 isRotating = false
						}
				 }
			}
	 }
}

#Preview {
	 if #available(iOS 26.0, *) {
			TheOverview()
	 } else {
	 }
}


