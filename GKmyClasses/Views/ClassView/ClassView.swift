import SwiftUI
import SwiftData
import StoreKit

struct ClassView: View {
	 @Environment(SubscriptionStatus.self) var subStatus: SubscriptionStatus
	 @Environment(\.modelContext) var modelContext
	 @State private var path: [ClassModel] = []
	 @Query var classes: [ClassModel]
	 var sortedClasses: [ClassModel] {
			classes.reversed()
	 }
	 @State var searchable: String = ""

	 var body: some View {
			@Bindable var subStatus = subStatus
			NavigationStack(path: $path) {
				 List {
						ForEach(filteredStudent) { item in
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
				 .searchable(text: $searchable)
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
				 .sheet(isPresented: $subStatus.notSubscribed) {
						Paywall()
							 .interactiveDismissDisabled()
				 }
			}

	 }
	 
	 private var filteredStudent: [ClassModel] {
			if searchable.isEmpty {
				 return sortedClasses
			} else {
				 return sortedClasses.filter {
						$0.name.localizedCaseInsensitiveContains(searchable)
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
	 static let subscriptionGroupID = "96E04A5E"

	 var body: some View {
			SubscriptionStoreView(groupID: Self.subscriptionGroupID) {
				 IntroScreen()
			}
			.storeButton(.hidden, for: .cancellation)
	 }
}

#Preview {
	 TabScreen()
			.modelContainer(for: [ClassModel.self, StudentModel.self], inMemory: true)
}

