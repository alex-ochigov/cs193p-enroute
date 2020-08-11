//
//  Airport.swift
//  Enroute
//
//  Created by Alex Ochigov on 8/11/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import CoreData
import Combine
import MapKit

extension Airport {
    static func withICAO(_ icao: String, context: NSManagedObjectContext) -> Airport {
        let request = fetchRequest(NSPredicate(format: "icao_ = %@", icao))
        let airports = (try? context.fetch(request)) ?? []
        if let airport = airports.first {
            return airport
        } else {
            let airport = Airport(context: context)
            airport.icao = icao
            AirportInfoRequest.fetch(icao) { airportInfo in
                self.update(from: airportInfo, context: context)
            }
            return airport
        }
    }
    
    static func update(from info: AirportInfo, context: NSManagedObjectContext) {
        if let icao = info.icao {
            let airport = self.withICAO(icao, context: context)
            airport.latitude = info.latitude
            airport.longitude = info.longitude
            airport.name = info.name
            airport.location = info.location
            airport.timezone = info.timezone
            airport.flightsTo.forEach { $0.objectWillChange.send() }
            airport.flightsFrom.forEach { $0.objectWillChange.send() }
            airport.objectWillChange.send()
            
            try? context.save()
        }
    }
    
    var flightsTo: Set<Flight> {
        get { (flightsTo_ as? Set<Flight>) ?? [] }
        set { flightsTo_ = newValue as NSSet }
    }
    
    var flightsFrom: Set<Flight> {
        get { (flightsFrom_ as? Set<Flight>) ?? [] }
        set { flightsFrom_ = newValue as NSSet }
    }
}


extension Airport: Identifiable, Comparable {
    var icao: String {
        get { icao_! } // TODO: maybe protect against when app ships?
        set { icao_ = newValue }
    }

    var friendlyName: String {
        let friendly = AirportInfo.friendlyName(name: self.name ?? "", location: self.location ?? "")
        return friendly.isEmpty ? icao : friendly
    }

    public var id: String { icao }

    public static func < (lhs: Airport, rhs: Airport) -> Bool {
        lhs.location ?? lhs.friendlyName < rhs.location ?? rhs.friendlyName
    }
}

extension Airport {
    static func fetchRequest(_ predicate: NSPredicate) -> NSFetchRequest<Airport> {
        let request = NSFetchRequest<Airport>(entityName: "Airport")
        request.sortDescriptors = [NSSortDescriptor(key: "location", ascending: true)]
        request.predicate = predicate
        return request
    }
}

extension Airport {
    func fetchIncomingFlights() {
         Self.flightAwareRequest?.stopFetching()
         if let context = managedObjectContext {
             Self.flightAwareRequest = EnrouteRequest.create(airport: icao, howMany: 90)
             Self.flightAwareRequest?.fetch(andRepeatEvery: 60)
             Self.flightAwareResultsCancellable = Self.flightAwareRequest?.results.sink { results in
                 for faflight in results {
                     Flight.update(from: faflight, in: context)
                 }
                 do {
                     try context.save()
                 } catch(let error) {
                     print("couldn't save flight update to CoreData: \(error.localizedDescription)")
                 }
             }
         }
     }

     private static var flightAwareRequest: EnrouteRequest!
     private static var flightAwareResultsCancellable: AnyCancellable?
}

extension Airport: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public var title: String? { name ?? icao }
    public var subtitle: String? { location }
}
