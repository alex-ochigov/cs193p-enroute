//
//  FlightFetcher.swift
//  Enroute
//
//  Created by CS193p Instructor.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI
import Combine

// a ViewModel that takes criteria about flights enroute to an airport
// and @Publishes a list of FAFlight objects from FlightAware API
// that matches that criteria

class FlightFetcher: ObservableObject // struct
{
    // create a FlightFetcher with certain search criteria ...
    init(flightSearch: FlightSearch) {
        self.flightSearch = flightSearch
        fetchFlights()
    }

    // ... then update the criteria as desired ...
    var flightSearch: FlightSearch {
        didSet { fetchFlights() }
    }
    
    // ... and retrieve the latest results here ...
    @Published private(set) var latest = [FAFlight]()

    // MARK: - Private Implementation
    
    // fires off a EnrouteRequest to FlightAware
    // to get a list of flights heading toward our flightSearch.destination airport
    // it runs periodically and publishes any FAFlight objects it finds
    // (we also add all mentioned airports and airlines to Airports.all and Airlines.all here)
    private func fetchFlights() {
        flightAwareResultsCancellable = nil
        flightAwareRequest?.stopFetching()
        flightAwareRequest = nil
        let icao = flightSearch.destination
        flightAwareRequest = EnrouteRequest.create(airport: icao, howMany: 90)
        flightAwareRequest?.fetch(andRepeatEvery: 30)
        flightAwareResultsCancellable = flightAwareRequest?.results.sink { [weak self] results in
            Airports.all.fetch(icao) // prefetch
            results.forEach {
                Airports.all.fetch($0.origin) // prefetch
                Airlines.all.fetch($0.airlineCode) // prefetch
            }
            self?.latest = results.sorted()
        }
    }

    private(set) var flightAwareRequest: EnrouteRequest!
    private var flightAwareResultsCancellable: AnyCancellable?
}
