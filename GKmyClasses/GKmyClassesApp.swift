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

								 subStatus.isSubscribed = true
							}
							.subscriptionStatusTask(for: "21818455") { taskState in

										if let value = taskState.value {
											 subStatus.isSubscribed = !value
													.filter { $0.state != .revoked && $0.state != .expired }
													.isEmpty
										} else {
											 subStatus.isSubscribed = false
											 }
							}
							.task {
								 for await verificationResult in Transaction.updates {
										guard case .verified(let transaction) = verificationResult else { continue }

										if transaction.productType == .autoRenewable {
											 subStatus.isSubscribed = true
										}

										await transaction.finish()
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





