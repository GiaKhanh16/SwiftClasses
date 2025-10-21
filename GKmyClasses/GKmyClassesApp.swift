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
				.modelContainer(for: [ClassModel.self, StudentModel.self])
				.environment(subStatus)
    }
}






	 //Try It Free
	 // MARK: - Preview
#Preview {
	 ClassView()
}
