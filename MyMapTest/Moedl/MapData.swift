//
//  MapData.swift
//  MyMapTest
//
//  Created by D02020015 on 2021/5/20.
//

import Foundation
import GoogleMaps
import GooglePlaces

struct MapData {
    // An array to hold the list of likely places.
    static var likelyPlaces: [GMSPlace] = []
    // The currently selected place.
    static var selectedPlace: GMSPlace?
}
