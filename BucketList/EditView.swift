//
//  EditView.swift
//  BucketList
//
//  Created by Rumit Singh Tuteja on 6/4/24.
//

import SwiftUI

struct EditView: View {
    
    @State var viewModel: ViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Place name", text: $viewModel.name)
                    TextField("Description", text: $viewModel.description)
                }
                
                Section("Nearby…") {
                    switch viewModel.loadingState {
                    case .loaded:
                        ForEach(viewModel.pages, id: \.pageid) { page in
                            Text(page.title)
                                .font(.headline)
                            + Text(": ") +
                            Text(page.description)
                                .italic()
                        }
                    case .loading:
                        Text("Loading…")
                    case .failed:
                        Text("Please try again later.")
                    }
                }
            }
            .navigationTitle("Place details")
            .toolbar {
                Button("Save") {
                    viewModel.save()
                    dismiss()
                }
                
                Button("Delete") {
                    viewModel.delete()
                    dismiss()
                }
            }
            .task {
                await viewModel.fetchNearbyPlaces()
            }
        }
    }
    
    init(location: Location, onSave: @escaping (Location) -> (), onDelete: @escaping (Location) -> ()) {
        self.viewModel = ViewModel(location: location, onSave: onSave, onDelete: onDelete)
    }
}


extension EditView {
    @Observable
    class ViewModel {
        enum LoadingStates {
            case loading, loaded, failed
        }

        var location: Location
                 
        var name: String
        var description: String
        
        let onSave: (Location) -> ()
        let onDelete: (Location) -> ()
                
        private(set) var loadingState = LoadingStates.loading
        private(set) var pages = [Page]()
        
        init(location: Location, onSave: @escaping (Location) -> (), onDelete: @escaping (Location) -> ()) {
            self.location = location
            self.onSave = onSave
            self.onDelete = onDelete
            name = location.name
            description = location.description
        }
        
        func save() {
            var newLocation = location
            newLocation.name = name
            newLocation.description = description
            newLocation.id = UUID()
            
            onSave(newLocation)
        }
        
        func delete() {
            onDelete(location)
        }
        
        func fetchNearbyPlaces() async {
            let urlString = "https://en.wikipedia.org/w/api.php?ggscoord=\(location.latitude)%7C\(location.longitude)&action=query&prop=coordinates%7Cpageimages%7Cpageterms&colimit=50&piprop=thumbnail&pithumbsize=500&pilimit=50&wbptterms=description&generator=geosearch&ggsradius=10000&ggslimit=50&format=json"
            
            guard let url = URL(string: urlString) else {
                print("Bad URL: \(urlString)")
                return
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let items = try JSONDecoder().decode(Result.self, from: data)
                pages = items.query.pages.values.sorted()
                loadingState = .loaded
            } catch {
                loadingState = .failed
            }
        }
    }
}

#Preview {
    EditView(location: .example) { _ in } onDelete: { _ in }
}
