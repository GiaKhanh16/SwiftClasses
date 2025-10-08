import SwiftUI
import SwiftData
import FoundationModels

struct TheOverview: View {
	 @Environment(\.modelContext) private var modelContext
	 @State var userPrompt: String = ""
	 @State private var attendanceText: String = ""
	 @State private var aiAnswer: String = ""
	 @State private var isLoading: Bool = false
	 @State private var isRotating = false
	 @State private var selectedTab: Int = 0

	 var body: some View {
			NavigationStack {
				 VStack(spacing: 0) {

						TabView(selection: $selectedTab) {
							 OverviewPage()
									.tag(0)

							 StatisticView()
									.tag(1)
					}
						.tabViewStyle(.page(indexDisplayMode: .never))
						.animation(.easeInOut, value: selectedTab)

				 }
				 .onAppear {
						attendanceText = exportAttendanceData(context: modelContext)
				 }
				 .navigationTitle(selectedTab == 0 ? "Overview" : "Statistics")
				 .toolbar {
						ToolbarItem(placement: .topBarLeading) {
							 if let fileURL = exportAttendanceCSV(context: modelContext) {
									ShareLink(item: fileURL)
							 } else {
									Text("Export Failed")
							 }
						}
						ToolbarItem(placement: .topBarTrailing) {
							 HStack(spacing: 20) {
									Button {
										 selectedTab = 0
									} label: {
										 Image(systemName: "apple.intelligence")
									}

									Button {
										 selectedTab = 1
									} label: {
										 Image(systemName: "chart.bar")
									}
							 }
						}
				 }
			}
	 }

			// MARK: - Overview Tab
	 @ViewBuilder
	 func OverviewPage() -> some View {
			VStack {
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

			// MARK: - Helpers

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

	 func exportAttendanceCSV(context: ModelContext) -> URL? {
			let fetchDescriptor = FetchDescriptor<AttendanceModel>()
			let attendances = (try? context.fetch(fetchDescriptor)) ?? []

				 // CSV header
			var csvText = "Date,Student Names\n"

			let formatter = DateFormatter()
			formatter.dateStyle = .short
			formatter.timeStyle = .none

			for attendance in attendances {
				 let dateString = formatter.string(from: attendance.date)
				 let studentNames = attendance.students.map { $0.name }.joined(separator: "; ")
						// Wrap in quotes to handle commas inside names
				 csvText += "\"\(dateString)\",\"\(studentNames)\"\n"
			}

				 // Save to temporary file
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
	 TheOverview()
}
