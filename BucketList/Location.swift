//
//  Location.swift
//  BucketList
//
//  Created by Rumit Singh Tuteja on 6/4/24.
//

import Foundation
import MapKit

struct Location: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var description: String
    var latitude: Double
    var longitude: Double
    // CLLocationCoordinate doesnt automatically work with codable, hence lat and long stored separately.
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static func == (_ lhs: Location, _ rhs: Location) -> Bool {
        lhs.id == rhs.id
    }
    
    #if DEBUG
    static var example = Location(id: UUID(), name: "New location", description: "", latitude: 22.7196, longitude: 75.8577)
    #endif
}
