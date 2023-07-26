//
//  ContentView.swift
//  MobileSat
//
//  Created by Matthew Fitzgerald on 10/23/22.
//

import CoreData
import SwiftUI
import Foundation
import MapKit

class PersistentData : ObservableObject
{
    let container = NSPersistentContainer(name: "CSE335.MobileSat.Satellite")

    init()
    {
        container.loadPersistentStores
        { description, error in
            if let error = error
            {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
}

struct ContentView: View
{
    @Binding var tabSelection : Int
    
    @Environment(\.scenePhase) var scenePhase
    
    @Environment(\.managedObjectContext) var objContext
    @FetchRequest(entity: Satellite.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Satellite.name, ascending: true)])
    var satellites : FetchedResults<Satellite>
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.048927, longitude: -111.093735), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
    @ObservedObject var mapSettings = MyMapViewSettings()
    @State var mapType : MKMapType = .standard
    
    //@State var brightSatellites : [SatelliteSelect] = []
    //@State var gpsSatellites : [SatelliteSelect] = []
    
    /*
     https://celestrak.org/NORAD/elements/gp.php?<QUERY>=<VALUE>&FORMAT=JSON-PRETTY
     where <QUERY> is:
     CATNR: Catalog Number (1 to 9 digits). Allows return of data for a single catalog number.
     INTDES: International Designator (yyyy-nnn). Allows return of data for all objects associated with a particular launch.
     GROUP: Groups of satellites provided on the CelesTrak Current Data page.
     NAME: Satellite Name. Allows searching for satellites by parts of their name.
     SPECIAL: Special data sets for the GEO Protected Zone (GPZ) or GPZ Plus.
     */
    // data structure that store news objects from google news
    
    //@State var queryType : String = "NAME"
    
    @State var time : Date = Date.now
    
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    func updateSatellites()
    {
        var wasUpdated : Bool = false
        repeat
        {
            wasUpdated = false
            for var satellite in satellites
            {
                if (satellite.wrappedDate.addingTimeInterval(86400) <= Date.now)
                {
                    wasUpdated = true
                    print("Satellite: " + satellite.wrappedName + " has expired")
                    let isFavorite = satellite.wrappedIsFavorite
                    let name = satellite.wrappedName
                    
                    let nameUrl : String = "https://celestrak.org/NORAD/elements/gp.php?NAME=" + name + "&FORMAT=TLE"
                    
                    let url = URL(string: nameUrl)!
                    let urlSession = URLSession.shared
                    
                    // stringQuery is a new task that will run separately to the main thread
                    let stringQuery = urlSession.dataTask(with: url, completionHandler:
                                                            {
                        data, response, error -> Void in
                        if (error != nil)
                        {
                            print(error!.localizedDescription)
                        }
                        
                        DispatchQueue.main.async {
                            let tleString : String = String(decoding: data!, as: UTF8.self)
                            let lines = tleString.split(separator: "\r\n")
                            if (lines.count == 3)
                            {
                                let name : String = String(lines[0]).trimmingCharacters(in: .whitespaces)
                                let line1 : String = String(lines[1]).trimmingCharacters(in: .whitespaces)
                                let line2 : String = String(lines[2]).trimmingCharacters(in: .whitespaces)
                                
                                satellite.name = name
                                satellite.tleLine1 = line1
                                satellite.tleLine2 = line2
                                satellite.date = Date.now
                                satellite.isFavorite = isFavorite
                                
                                try? objContext.save()
                                
                            }
                        }
                    })
                    // resume() tells the task to start running on its own thread
                    stringQuery.resume()
                }
                if (wasUpdated)
                {
                    break
                }
            }
        } while (wasUpdated == true)
    }

    var body: some View
    {
        NavigationView
        {
            List
            {
                Picker("Map Style", selection: $mapType)
                {
                    Text("Standard").tag(MKMapType.standard)
                    Text("Satellite").tag(MKMapType.satellite)
                    Text("Hybrid").tag(MKMapType.hybrid)
                }
                .pickerStyle(.segmented)
                .onChange(of: mapType, perform:
                {
                    newMapType in
                    mapSettings.mapType = newMapType
                })
                
                MyMapView(satellites: _satellites, region: $region, time: $time)
                .environmentObject(mapSettings)
                .frame(width: 400, height: 300)
                .onReceive(timer)
                {
                    _ in
                    time = Date.now
                }

                ScrollView(.horizontal, showsIndicators: true)
                {
                    HStack{
                        ForEach(satellites)
                        {
                            satellite in
                            let coords : GeoCoords = calculateGeoCoords(inSatellite: satellite, inTime: time)
                            if (satellite.isFavorite)
                            {
                                VStack
                                {
                                    Text(satellite.wrappedName).font(.system(size:12))
                                    Text("Latitude: " + String(coords.latitude)).font(.system(size:10))
                                    Text("Longitude: " + String(coords.longitude)).font(.system(size:10))
                                    Text("Altitude: " + String(coords.altitude)).font(.system(size:10))
                                }
                                .padding()
                                .background(Color.blue.opacity(0.5))
                                .cornerRadius(10)
                                .onTapGesture
                                {
                                    mapSettings.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude), span: MKCoordinateSpan(latitudeDelta: 7, longitudeDelta: 7))
                                    mapSettings.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                    case .inactive:
                        print("inactive")
                    case .active:
                        print("active")
                        updateSatellites()
                    case .background:
                        print("background")
                }
            }
        }
        .navigationTitle("Map")
        .listStyle(.grouped)

    } // NavigationView
    
}

/*
struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ContentView()
    }
}
*/
