//
//  ContentView.swift
//  BucketList
//
//  Created by Rumit Singh Tuteja on 6/4/24.
//

import MapKit
import SwiftUI

struct ContentView: View {
    
    // Start position needs to be a camera position and with the coordinate region specified.
    let startPosition = MapCameraPosition.region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 22.7196, longitude: 75.8577), span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25))
    )
    
    @State var viewModel = ViewModel()

    
    fileprivate func displayEditView(_ place: Location) -> EditView {
        return EditView(location: place) { newLocation in
            viewModel.modify(place, newLocation: newLocation)
            viewModel.save()
            
        } onDelete: { deleted in
            viewModel.delete(deleted)
            viewModel.save()
        }
    }
    
    var body: some View {
        if viewModel.isUnlocked {
            NavigationStack {
                MapReader { proxy in
                    Map(initialPosition: startPosition) {
                        ForEach(viewModel.locations) { location in
                            Annotation(location.name, coordinate: location.coordinate) {
                                Image(systemName: "star.circle")
                                    .resizable()
                                    .foregroundColor(.red)
                                    .frame(width: 44, height: 44)
                                    .clipShape(.circle)
                                    .onLongPressGesture() {
                                        viewModel.setSelectedLocation(location)
                                    }
                            }
                            
                        }
                    }
                    .onTapGesture { position in
                        if let coordinate = proxy.convert(position, from: .local) {
                            let location = viewModel.addLocation(at: coordinate)
                            viewModel.save()
                            viewModel.selectedPlace = location
                        }
                    }
                    .sheet(item: $viewModel.selectedPlace) { place in
                        displayEditView(place)
                    }
                }
                .navigationTitle("Bucket List")
                .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            Button("Unlock Places", action: viewModel.authenticate)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(.capsule)
        }
            
    }
}

import LocalAuthentication

extension ContentView {
    
    
    @Observable
    class ViewModel {
        
        private let savePath = URL.documentsDirectory.appending(path: "SavedPlaces")
        private(set) var locations: [Location]
        
        var isUnlocked = false
        var selectedPlace: Location?
        
        init() {
            do {
                let data = try Data(contentsOf: savePath)
                locations = try JSONDecoder().decode([Location].self, from: data)
            } catch {
                locations = []
            }
        }
        
        func addLocation(at point: CLLocationCoordinate2D) -> Location {
            let newLocation = Location(id: UUID(), name: "New location", description: "", latitude: point.latitude, longitude: point.longitude)
            locations.append(newLocation)
            return newLocation
        }
        
        func delete(_ location: Location) {
            if let index = locations.firstIndex(of: location) {
                locations.remove(at: index)
            }
        }
        
        func modify(_ oldLocation: Location, newLocation: Location) {
            if let index = locations.firstIndex(of: oldLocation) {
                locations[index] = newLocation
            }
        }
        
        func setSelectedLocation(_ location: Location) {
            selectedPlace = location
        }
        
        func save() {
            do {
                let data = try JSONEncoder().encode(locations)
                try data.write(to: savePath, options: [.atomic, .completeFileProtection])
            } catch {
                print("Unable to save data")
            }
        }
        
        func authenticate() {
            
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                let reason = "Please authenticate yourself to unlock your places"
                
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                    if success {
                        self.isUnlocked = true
                    } else {
                        print("authentication failed")
                    }
                }
            } else {
                print("biometrics evaluation not found")
            }
        }
    }
}

#Preview {
    ContentView()
}
