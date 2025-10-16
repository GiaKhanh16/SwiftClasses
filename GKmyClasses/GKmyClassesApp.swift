//
//  GKmyClassesApp.swift
//  GKmyClasses
//
//  Created by Khanh Nguyen on 10/6/25.
//

import SwiftUI
import SwiftData
import StoreKit
@main
struct GKmyClassesApp: App {
    var body: some Scene {
        WindowGroup {
					 TabScreen()
        }
				.modelContainer(for: [ClassModel.self, StudentModel.self])

    }
}






	 //Try It Free
	 // MARK: - Preview
#Preview {
	 ClassView()
}
