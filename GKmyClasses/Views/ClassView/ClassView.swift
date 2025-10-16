import SwiftUI
import SwiftData
import StoreKit

struct ClassView: View {
	 @Environment(\.modelContext) var modelContext
	 @State private var path: [ClassModel] = []
	 @Query var classes: [ClassModel]
	 @State private var isSubscribed: Bool = true


	 var body: some View {
			NavigationStack(path: $path) {
				 List {
						ForEach(classes) { item in
							 NavigationLink(value: item) {
									VStack(alignment: .leading, spacing: 9) {
										 Text(item.name)
										 Text(item.classDescription)
												.font(.footnote)
												.foregroundStyle(.gray)
									}
							 }
						}
						.onDelete(perform: deleteClass)
				 }
				 .navigationTitle("Classes")
				 .toolbar {
						ToolbarItem(placement: .topBarTrailing) {
							 Button {
									withAnimation {
										 let newClass = ClassModel(
												name: "...",
												classDescription: "...",
												attendances: []
										 )
										 path.append(newClass)
										 Task {
												try await Task.sleep(nanoseconds: 500_000_000)
												modelContext.insert(newClass)
										 }
									}
							 } label: {
									Image(systemName: "plus")
							 }
						}
				 }
				 .navigationDestination(for: ClassModel.self) { classModel in
						DetailClassView(classModel: classModel)
							 .toolbar(.hidden, for: .tabBar)
				 }
				 .sheet(isPresented: $isSubscribed) {
						Paywall()
							 .interactiveDismissDisabled()
				 }
				 .onInAppPurchaseCompletion { product, result in
						if case .success = result {
							 isSubscribed.toggle()
						}
				 }
			}
	 }

	 private func deleteClass(at offsets: IndexSet) {
			for index in offsets {
				 let classToDelete = classes[index]
				 modelContext.delete(classToDelete)
			}
			try? modelContext.save()
	 }
}

struct Paywall: View {
	 static let subscriptionGroupID = "21805784"

	 var body: some View {
			SubscriptionStoreView(groupID: Self.subscriptionGroupID) {
				 IntroScreen()
			}
	 }
}

#Preview {
	 TabScreen()
			.modelContainer(for: [ClassModel.self, StudentModel.self], inMemory: true)
}
