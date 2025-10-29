//
//  IntroSheet.swift
//  SwiftClasses
//
//  Created by Khanh Nguyen on 10/10/25.
//

import SwiftUI

struct IntroScreen: View {
			/// Visibility Status
	 @AppStorage("isFirstTime") private var isFirstTime: Bool = true

			/// Animation States
	 @State private var animateTitle: Bool = false
	 @State private var animateSubtitle: Bool = false
	 @State private var animatePoints: [Bool] = Array(repeating: false, count: 3)
	 @State private var animateFooter: Bool = false

	 var body: some View {
			VStack(spacing: 15) {

				 VStack(alignment: .leading) {
						Text("SwiftClasses")
							 .font(.system(size: 30, weight: .semibold, design: .default))
							 .foregroundStyle(.primary)
							 .padding(.top, 35 )
							 .blurSlide(animateTitle)

				 }
				 .frame(maxWidth: .infinity, alignment: .leading)
				 .monospaced()
				 .padding(15)

				 Spacer().frame(height: 20)
				 VStack(alignment: .leading, spacing: 30) {
						PointView(symbol: "list.bullet.clipboard", title: "Manage Attendances", subTitle: "Manage classes, students and staff.")
							 .blurSlide(animatePoints[0])

						PointView(symbol: "apple.intelligence", title: "Apple Intelligence", subTitle: "Ask Apple Intelligence questions on your attendances.")
							 .blurSlide(animatePoints[1])

						PointView(symbol: "square.and.arrow.up", title: "Collaboration", subTitle: "Export into CSV file.")
							 .blurSlide(animatePoints[2])

						PointView(symbol: "lock.circle.dotted", title: "Data Privacy", subTitle: "All data is secured on your local machine.")
							 .blurSlide(animatePoints[2])
				 }
				 .frame(maxWidth: .infinity, alignment: .leading)
				 .padding(.leading, 10)

				 Spacer(minLength: 10)

			}
		
			.task {
				 await runAnimations()
			}
	 }

			/// Point View
	 @ViewBuilder
	 func PointView(symbol: String, title: String, subTitle: String) -> some View {
			HStack(spacing: 20) {
				 Image(systemName: symbol)
						.font(.title)
						.foregroundStyle(.secondary)

				 VStack(alignment: .leading, spacing: 6) {
						Text(title)
							 .font(.headline)


						Text(subTitle)
							 .font(.subheadline)
				 }
			}
	 }

			/// Animation Helpers
	 func delayedAnimation(_ delay: Double, action: @escaping () -> ()) async {
			try? await Task.sleep(for: .seconds(delay))
			withAnimation(.smooth) {
				 action()
			}
	 }

	 func runAnimations() async {
			guard !animateTitle else { return }

			await delayedAnimation(0.32) {
				 animateTitle = true
			}

			await delayedAnimation(0.26) {
				 animateSubtitle = true
			}

			try? await Task.sleep(for: .seconds(0.26))

			for index in animatePoints.indices {
				 let delay = Double(index) * 0.14
				 await delayedAnimation(delay) {
						animatePoints[index] = true
				 }
			}

			await delayedAnimation(0.26) {
				 animateFooter = true
			}
	 }


}

	 /// Blur + Slide effect
extension View {
	 @ViewBuilder
	 func blurSlide(_ show: Bool) -> some View {
			self
				 .compositingGroup()
				 .blur(radius: show ? 0 : 10)
				 .opacity(show ? 1 : 0)
				 .offset(y: show ? 0 : 100)
	 }
}

#Preview {
	 IntroScreen()
			.preferredColorScheme(.dark)
}



	 //				 VStack(alignment: .leading, spacing: 15) {
	 //						Button(action: {
	 //							 isFirstTime = false
	 //						}, label: {
	 //							 Text("Got it!")
	 //									.fontWeight(.bold)
	 //									.foregroundColor(.primary)
	 //									.frame(maxWidth: .infinity)
	 //									.padding(.vertical, 14)
	 //									.background(.thickMaterial, in: .rect(cornerRadius: 12))
	 //									.contentShape(.rect)
	 //
	 //						})
	 //				 }
	 //				 .padding(15)
	 //				 .blurSlide(animateFooter)
