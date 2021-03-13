//
//  Pin.swift
//  Virtual Tourist V2
//
//  Created by Norah Almaneea on 13/03/2021.
//

import Foundation
import CoreData

import Foundation
import MapKit

extension Pin {
    var coordinate: CLLocationCoordinate2D {
        set {
            lat = newValue.latitude
            lon = newValue.longitude
        }
        get {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
    
    func compare(to coordinate: CLLocationCoordinate2D) -> Bool {
        return (lat == coordinate.latitude && lon == coordinate.longitude)
    }
}
