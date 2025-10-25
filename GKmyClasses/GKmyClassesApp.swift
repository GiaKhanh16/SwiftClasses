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
	 @State private var subStatus = SubscriptionStatus()
	 let container: ModelContainer
    var body: some Scene {
			 @Bindable var subStatus = subStatus
        WindowGroup {
					 TabScreen()
					 		.onInAppPurchaseCompletion { product, result in
								 guard case .success(let verificationResult) = result,
											 case .success(_) = verificationResult else { return }

								 subStatus.notSubscribed = false
							}
							.subscriptionStatusTask(for: "96E04A5E") { taskState in
								 let _ = taskState.map { statues in
										if statues.isEmpty {
											 subStatus.notSubscribed = true
										} else {

										}
								 }

							}
        }
				.modelContainer(container)
				.environment(subStatus)
    }
	 init() {
			let schema = Schema([ClassModel.self, StudentModel.self, StaffModel.self.self])
			let config = ModelConfiguration("SwiftClasses", schema: schema)
			do {
				 container = try ModelContainer(for: schema, configurations: config)
			} catch {
				 fatalError("Could not configure the container")
			}

			print(URL.applicationSupportDirectory.path(percentEncoded: false))
	 }
}





