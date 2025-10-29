import SwiftUI
import SwiftData
import FoundationModels

	 // MARK: - DataSourceType Enum
enum DataSourceType {
	 case staff(StaffModel)
	 case student(StudentModel)
	 case classAttendance(ClassModel)
}

	 // MARK: - Overview Entry Point
struct TheOverview: View {
	 var exportType: DataSourceType
	 @Environment(\.modelContext) private var modelContext

	 var body: some View {
			NavigationStack {
				 Group {
						if #available(iOS 26.0, *) {
							 AppleIntelView(exportType: exportType)
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
			}
	 }
}

	 // MARK: - AppleIntelView
@available(iOS 26.0, *)
struct AppleIntelView: View {
	 @Environment(SubscriptionStatus.self) var subModel
	 @Environment(\.modelContext) private var modelContext

	 @State  var userPrompt: String = ""
	 @State  var attendanceText: String = ""
	 @State  var isLoading: Bool = false
	 @State  var isRotating: Bool = false
	 @State  var wallToggle: Bool = false
	 @State  var aiAnswer: [String] = []
	 @State  var startDate: Date = Date()
	 @State  var endDate: Date = Date()
	 @State  var isNil: Bool = false

	  var exportVM = AttendanceExportViewModel()
	  var model = SystemLanguageModel.default
	 var exportType: DataSourceType

	 var body: some View {
			NavigationStack {
				 VStack(spacing: 0) {
						switch model.availability {
							 case .available:
									OverviewPage()
							 case .unavailable(let reason):
									UnavailableView(message: "AI unavailable: \(reason)")
						}
				 }
				 .sheet(isPresented: $wallToggle) { Paywall() }
			}
	 }

			// MARK: - OverviewPage
	 @ViewBuilder
	 func OverviewPage() -> some View {
			VStack {
				 VStack {
						DatePicker("From", selection: $startDate, displayedComponents: .date)
						DatePicker("To", selection: $endDate, displayedComponents: .date)
				 }
				 .padding()

						// Compute attendance text locally (no state mutation)
				 let attendanceOutput = exportAttendanceData(startDate: startDate, endDate: endDate)

				 if let answer = attendanceOutput {
						
				 } else {
						Text("No attendance data available in this range.")
							 .foregroundStyle(.secondary)
							 .padding()
				 }

				 HStack(spacing: 20) {
						TextField("Question on your attendances", text: $userPrompt)
							 .padding(.vertical, 5)
							 .padding(.leading, 15)
							 .glassEffect()

						if isLoading {
							 Image(systemName: "apple.intelligence")
									.font(.title2)
									.rotationEffect(.degrees(isRotating ? 360 : 0))
									.animation(.linear(duration: 1)
										 .repeatForever(autoreverses: false), value: isRotating)
									.onAppear { isRotating = true }
						} else {
							 Button {
										 attendanceText = attendanceOutput ?? "No Data"
										 generateAnswer()
							 } label: {
									Text("Send")
										 .foregroundStyle(.blue)
							 }
									// 👇 disable when no data
							 .disabled(attendanceOutput == nil)
						}
				 }
				 .padding(.horizontal, 15)
				 .padding(.bottom, 5)

				 ScrollView(.vertical) {
						VStack(alignment: .leading, spacing: 10) {
							 HStack {
									Text("AI Answer:")
										 .bold()
										 .padding(.leading, 10)
									Spacer()
									Text("Clear")
										 .font(.footnote)
										 .foregroundStyle(.secondary)
										 .onTapGesture { aiAnswer.removeAll() }
							 }

							 if !aiAnswer.isEmpty {
									ForEach(aiAnswer, id: \.self) { answer in
										 Text(answer)
												.padding()
												.background(.ultraThinMaterial)
												.cornerRadius(10)
												.font(.system(size: 16))
												.lineSpacing(6)
									}
							 }
						}
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding()
				 }
			}
			.padding(.top, 20)
	 }


			// MARK: - UnavailableView
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

	 private func exportAttendanceData(startDate: Date, endDate: Date) -> String? {
			switch exportType {
				 case .staff(let staff):
						return exportVM.exportStaffAttendanceText(for: staff, startDate: startDate, endDate: endDate)
				 case .student(let student):
						return exportVM.exportStudentAttendanceText(for: student, startDate: startDate, endDate: endDate)
				 case .classAttendance(let classModel):
						return exportVM.exportClassAttendanceText(for: classModel, startDate: startDate, endDate: endDate)
			}
	 }
			// MARK: - Generate AI Answer
	 private func generateAnswer() {
			isLoading = true
			isRotating = false

			Task {
				 do {
						let instructions = """
								You are an attendance assistant.
								Here is the attendance record:
								\(attendanceText)
								
								Instructions:
								- Search the record and answer informatively and confidently.
								"""
						let options = GenerationOptions(temperature: 1.0)
						let session = LanguageModelSession(instructions: instructions)
						let response = try await session.respond(to: userPrompt, options: options)

						await MainActor.run {
							 aiAnswer.append(response.content)
							 userPrompt = ""
							 isLoading = false
							 isRotating = false
						}
				 } catch {
						await MainActor.run {
							 aiAnswer.append("Error: \(error.localizedDescription)")
							 isLoading = false
							 isRotating = false
						}
				 }
			}
	 }
}
