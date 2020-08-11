//
//  FilterFlights.swift
//  Enroute
//
//  Created by Alex Ochigov on 8/11/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI
import MapKit

struct FilterFlights: View {
    @FetchRequest(fetchRequest: Airport.fetchRequest(.all)) var airports: FetchedResults<Airport>
    @FetchRequest(fetchRequest: Airline.fetchRequest(.all)) var airlines: FetchedResults<Airline>
    
    @State var draft: FlightSearch
    @Binding var flightSearch: FlightSearch
    @Binding var isPresented: Bool
    
    var destination: Binding<MKAnnotation?> {
        return Binding<MKAnnotation?>(
            get: { return self.draft.destination },
            set: { annotation in
                if let airport = annotation as? Airport {
                    self.draft.destination = airport
                }
            }
        )
    }
    
    init(flightSearch: Binding<FlightSearch>, isPresented: Binding<Bool>) {
        _flightSearch = flightSearch
        _isPresented = isPresented
        _draft = State(wrappedValue: flightSearch.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Destination", selection: $draft.destination) {
                        ForEach(airports.sorted(), id: \.self) { airport in
                            Text(airport.friendlyName).tag(airport)
                        }
                    }
                    MapView(annotations: airports.sorted(), selection: destination)
                        .frame(minHeight: 400)
                }
                Section {
                        Picker("Origin", selection: $draft.origin) {
                            Text("Any").tag(Airport?.none)
                            ForEach(airports.sorted(), id: \.self) { (airport: Airport?) in
                                Text(airport?.friendlyName ?? "Any").tag(airport)
                            }
                        }
                        Picker("Airline", selection: $draft.airline) {
                            Text("Any").tag(Airline?.none)
                            ForEach(airlines.sorted(), id: \.self) { (airline: Airline?) in
                                Text(airline?.friendlyName ?? "Any").tag(airline)
                            }
                        }
                        Toggle(isOn: $draft.inTheAir) { Text("Enroute Only") }
                    }
                }
                .navigationBarTitle("Filter Flights")
                .navigationBarItems(leading: cancelButton, trailing: doneButton)
        }

    }
    
    var cancelButton: some View {
        Button("Cancel") {
            self.isPresented = false
        }
    }
    
    var doneButton: some View {
        Button("Done") {
            if self.draft.destination != self.flightSearch.destination {
                self.draft.destination.fetchIncomingFlights()
            }
            self.flightSearch = self.draft
            self.isPresented = false
        }
    }
}
