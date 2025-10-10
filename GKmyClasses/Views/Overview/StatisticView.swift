import SwiftUI

struct StatisticView: View {
	 var body: some View {
			GridView()
				 .padding()
	 }

	 @ViewBuilder
	 func GridView() -> some View {
			Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 20) {
				 GridRow {
						GridCell(title: "Most Consistent", name: "Alex Kornajcik")
						GridCell(title: "Top Attendance", name: "Mina Patel")
				 }
				 GridRow {
						GridCell(title: "Best Effort", name: "John Doe")
						GridCell(title: "Most Improved", name: "Sarah Kim")
				 }
			}
	 }

	 func GridCell(title: String, name: String) -> some View {
			VStack(alignment: .leading, spacing: 10) {
				 Text(title)
						.font(.caption)
				 Text(name)
						.font(.headline)
			}
			.padding()
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(.ultraThinMaterial)
			.cornerRadius(10)
	 }
}

#Preview {
	 StatisticView()
}
