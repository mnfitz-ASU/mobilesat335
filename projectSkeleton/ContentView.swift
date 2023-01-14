//
//  ContentView.swift
//  Project Skeleton
//
//  Created by Matthew Fitzgerald on 10/23/22.
//

import CoreData
import SwiftUI
import Foundation
import MapKit

struct OrbitalDataTLE : Codable
{
    var satName : String = ""
    var line1 : String = ""
    var line2 : String = ""
}

struct GeoCoords
{
    var name : String = ""
    var latitude : Double = 0
    var longitude : Double = 0
    var altitude : Double = 0
}

extension Satellite
{
    public var wrappedName : String {name ?? ""}
    public var wrappedTleLine1 : String {tleLine1 ?? ""}
    public var wrappedTleLine2 : String {tleLine2 ?? ""}
    public var wrappedIsFavorite : Bool {isFavorite}
    public var wrappedAge : Date {age ?? Date()}
}

struct SatelliteSelect : Identifiable, Hashable
{
    var name : String = ""
    var tle1 : String = ""
    var tle2 : String = ""
    var age : Date = Date.now
    var isSelected : Bool = false
    var id : UUID = UUID()
}

extension CLLocationCoordinate2D: Identifiable
{
    public var id: String
    {
        "\(latitude)-\(longitude)"
    }
}

func calculateGeoCoords(inSatellite : Satellite, inTime : Date) -> GeoCoords
{
    // TRICKY: Calling a C routine that needs to return values using C pointers
    // In SwiftUI, we simulate C pointers using UnsafeMutablePointer<>
    
    let nameCStr = Array(inSatellite.wrappedName.utf8CString)
    let line1CStr = Array(inSatellite.wrappedTleLine1.utf8CString)
    let line2CStr = Array(inSatellite.wrappedTleLine2.utf8CString)

    var age : Double = 0
    var ageP : UnsafeMutablePointer<Double> = .init(&age)
    var lat : Double = 0
    var latP : UnsafeMutablePointer<Double> = .init(&lat)
    var lon : Double = 0
    var lonP : UnsafeMutablePointer<Double> = .init(&lon)
    var alt : Double = 0
    var altP : UnsafeMutablePointer<Double> = .init(&alt)
    
    // TRICKY: Call C function here using the SwiftUI binding header decl.
    orbit_to_lla(nameCStr, line1CStr, line2CStr, ageP, latP, lonP, altP)
    
    var coords : GeoCoords = GeoCoords()
    coords.name = inSatellite.wrappedName
    coords.latitude = lat
    coords.longitude = lon
    coords.altitude = alt
    return coords
}

class MyMapViewSettings : ObservableObject
{
    @Published var mapType : MKMapType = .standard
    @Published var region : MKCoordinateRegion? = nil
}

struct MyMapView : UIViewRepresentable
{
    @Environment(\.managedObjectContext) var objContext
    @FetchRequest(entity: Satellite.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Satellite.name, ascending: true)]) var satellites : FetchedResults<Satellite>
    
    @Binding var region : MKCoordinateRegion
    @Binding var time : Date
    @EnvironmentObject private var mapSettings : MyMapViewSettings
    @State var updateView : Int = 0
    
    // UIViewRepresentable wants these functions defined
    func makeUIView(context: Context) -> MKMapView
    {
        let mapView = MKMapView(frame: .zero)
        mapView.setRegion(region, animated: false)
        mapView.mapType = mapSettings.mapType
        
        mapView.removeAnnotations(mapView.annotations)

        for var satellite in satellites
        {
            var coords : GeoCoords = calculateGeoCoords(inSatellite: satellite, inTime: time)
            var newAnnotation : MKPointAnnotation = MKPointAnnotation(__coordinate: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude), title: coords.name, subtitle: nil)
            mapView.addAnnotation(newAnnotation)
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context)
    {
        if (mapSettings.region != nil)
        {
            uiView.setRegion(mapSettings.region!, animated: true)
            mapSettings.region = nil
        }
        uiView.mapType = mapSettings.mapType
        
        uiView.removeAnnotations(uiView.annotations)

        for var satellite in satellites
        {
            if (satellite.isFavorite)
            {
                //uiView.remove
                var coords : GeoCoords = calculateGeoCoords(inSatellite: satellite, inTime: time)
                var newAnnotation : MKPointAnnotation = MKPointAnnotation(__coordinate: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude), title: coords.name, subtitle: nil)
                uiView.addAnnotation(newAnnotation)
            }
        }
    }
    
    func refresh()
    {
        updateView += 1
    }
}

class PersistentData : ObservableObject
{
    let container = NSPersistentContainer(name: "CSE335.projectSkeleton.Satellite")

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
    
    @Environment(\.scenePhase) var scenePhase
    
    @Environment(\.managedObjectContext) var objContext
    @FetchRequest(entity: Satellite.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Satellite.name, ascending: true)])
    var satellites : FetchedResults<Satellite>
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.048927, longitude: -111.093735), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
    @ObservedObject var mapSettings = MyMapViewSettings()
    @State var mapType : MKMapType = .standard
    
    @State var brightSatellites : [SatelliteSelect] = []
    @State var gpsSatellites : [SatelliteSelect] = []
    
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
    @State var queryType : String = "NAME"
    @State var value : String = ""
    @State var time : Date = Date.now
    
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
        
    func addSatelliteName()
    {
        let nameUrl : String = "https://celestrak.org/NORAD/elements/gp.php?NAME=" + value + "&FORMAT=TLE"
        
        var url = URL(string: nameUrl)!
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
                    
                    let isUnique : Bool = ((satellites.first(where: {$0.wrappedName == name})) == nil)
                    if (isUnique)
                    {
                        var newSatellite : Satellite = Satellite(context: objContext)
                        newSatellite.name = name
                        newSatellite.tleLine1 = line1
                        newSatellite.tleLine2 = line2
                        newSatellite.age = Date.now
                        
                        try? objContext.save()
                    }
                }
            }
        })
        // resume() tells the task to start running on its own thread
        stringQuery.resume()
    }
    
    func addSatelliteBrightest()
    {
        let brightestUrl : String = "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=tle"

        var url = URL(string: brightestUrl)!
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
                let linesX3 = tleString.split(separator: "\r\n")
                
                brightSatellites.removeAll()
                
                for i in stride(from: 0, to: linesX3.count-1, by: 3)
                {
                    let name : String = String(linesX3[i+0]).trimmingCharacters(in: .whitespaces)
                    let line1 : String = String(linesX3[i+1]).trimmingCharacters(in: .whitespaces)
                    let line2 : String = String(linesX3[i+2]).trimmingCharacters(in: .whitespaces)
                    
                    let isUnique : Bool = ((satellites.first(where: {$0.wrappedName == name})) == nil)
                    if (isUnique)
                    {
                        var newSatellite : SatelliteSelect = SatelliteSelect()
                        newSatellite.name = name
                        newSatellite.tle1 = line1
                        newSatellite.tle2 = line2
                        newSatellite.age = Date.now
                        
                        brightSatellites.append(newSatellite)
                    }
                }
            }
        })
        // resume() tells the task to start running on its own thread
        stringQuery.resume()
    }
    
    func addSatelliteGPS()
    {
        let gpsUrl : String = "https://celestrak.org/NORAD/elements/gp.php?GROUP=gps-ops&FORMAT=tle"

        var url = URL(string: gpsUrl)!
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
                let linesX3 = tleString.split(separator: "\r\n")
                
                gpsSatellites.removeAll()
                
                for i in stride(from: 0, to: linesX3.count-1, by: 3)
                {
                    let name : String = String(linesX3[i+0]).trimmingCharacters(in: .whitespaces)
                    let line1 : String = String(linesX3[i+1]).trimmingCharacters(in: .whitespaces)
                    let line2 : String = String(linesX3[i+2]).trimmingCharacters(in: .whitespaces)
                    
                    let isUnique : Bool = ((satellites.first(where: {$0.wrappedName == name})) == nil)
                    if (isUnique)
                    {
                        var newSatellite : SatelliteSelect = SatelliteSelect()
                        newSatellite.name = name
                        newSatellite.tle1 = line1
                        newSatellite.tle2 = line2
                        newSatellite.age = Date.now
                        
                        gpsSatellites.append(newSatellite)
                    }
                }
            }
        })
        // resume() tells the task to start running on its own thread
        stringQuery.resume()
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
                }
                
                Picker("Search By: ", selection: $queryType)
                {
                    Text("Name").tag("NAME")
                    Text("Brightest").tag("BRIGHTEST")
                    Text("GPS").tag("GPS")
                }
                .pickerStyle(.segmented)
                /*
                .onChange(of: queryType, perform:
                {
                    newQueryType in
                    queryType = newQueryType
                })
                 */
                
                switch queryType
                {
                case "NAME":
                    HStack
                    {
                        Text("Satellite Name:")
                        TextField("Name", text: $value)
                    }
                    Button("Add")
                    {
                        addSatelliteName()
                    }
                    
                case "BRIGHTEST":
                    NavigationLink(destination: AddListView(inList: $brightSatellites).onAppear(perform: {
                        self.addSatelliteBrightest()
                    }))
                    {
                        Text("Search Brightest")
                    }
                    
                case "GPS":
                    NavigationLink(destination: AddListView(inList: $gpsSatellites).onAppear(perform: {
                        self.addSatelliteGPS()
                    }))
                    {
                        Text("Search GPS")
                    }
                    
                default:
                    Text("Something went wrong.")
                }
                
                NavigationLink(destination: ListView(time: $time))
                {
                    Text("List Satellites")
                }
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                    case .inactive:
                        print("inactive")
                    case .active:
                        print("active")
                    case .background:
                        print("background")
                }
            }
        }
        .navigationTitle("Map")
        .listStyle(.grouped)
    } // NavigationView
}

struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ContentView()
    }
}
