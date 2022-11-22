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

extension Satellite //: Identifiable
{
    public var wrappedName : String {name ?? ""}
    public var wrappedTleLine1 : String {tleLine1 ?? ""}
    public var wrappedTleLine2 : String {tleLine2 ?? ""}
    public var wrappedIsFavorite : Bool {isFavorite}
    public var wrappedAge : Date {age ?? Date()}
    //public var id : UUID {UUID()}
}

extension CLLocationCoordinate2D: Identifiable
{
    public var id: String
    {
        "\(latitude)-\(longitude)"
    }
}

class MyMapViewSettings : ObservableObject
{
    @Published var mapType : MKMapType = .standard
}

struct MyMapView : UIViewRepresentable
{
    @Environment(\.managedObjectContext) var objContext
    @FetchRequest(entity: Satellite.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Satellite.name, ascending: true)]) var satellites : FetchedResults<Satellite>
    
    @Binding var region : MKCoordinateRegion
    @EnvironmentObject private var mapSettings : MyMapViewSettings
    
    func calculateGeoCoords(inSatellite : Satellite) -> GeoCoords
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
    
    // UIViewRepresentable wants these functions defined
    func makeUIView(context: Context) -> MKMapView
    {
        let mapView = MKMapView(frame: .zero)
        mapView.setRegion(region, animated: false)
        mapView.mapType = mapSettings.mapType

        for var satellite in satellites
        {
            var coords : GeoCoords = calculateGeoCoords(inSatellite: satellite)
            var newAnnotation : MKPointAnnotation = MKPointAnnotation(__coordinate: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude), title: coords.name, subtitle: nil)
            mapView.addAnnotation(newAnnotation)
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context)
    {
        uiView.setRegion(region, animated: true)
        uiView.mapType = mapSettings.mapType
        
        for var satellite in satellites
        {
            var coords : GeoCoords = calculateGeoCoords(inSatellite: satellite)
            var newAnnotation : MKPointAnnotation = MKPointAnnotation(__coordinate: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude), title: coords.name, subtitle: nil)
            uiView.addAnnotation(newAnnotation)
        }
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
    @Environment(\.managedObjectContext) var objContext
    @FetchRequest(entity: Satellite.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Satellite.name, ascending: true)])
        var satellites : FetchedResults<Satellite>
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.048927, longitude: -111.093735), span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5))
    @ObservedObject var mapSettings = MyMapViewSettings()
    @State var mapType : MKMapType = .standard
    
    //@State private var satellites : [Satellite] = []
    
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
    @State var gQuery : String = "NAME="
    @State var gValue : String = ""
    
    init(/*_ name : String, _ text : Binding<String>*/)
    {
        //Test!
    }
    
    func addSatellite()
    {
        let urlAsString : String = "https://celestrak.org/NORAD/elements/gp.php?" + gQuery + gValue + "&FORMAT=TLE"
        let testURL : String = "https://celestrak.org/NORAD/elements/gp.php?NAME=MICROSAT-R&FORMAT=TLE"
        let url = URL(string: urlAsString)!
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
                        newSatellite.age = Date()
                        
                        try? objContext.save()
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
                Section()
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
                    
                    MyMapView(satellites: _satellites, region: $region)
                    .environmentObject(mapSettings)
                    .frame(width: 400, height: 300)
                }
                
                Section()
                {
                    ScrollView(.horizontal, showsIndicators: true)
                    {
                        HStack{
                            ForEach(satellites)
                            {
                                satellite in
                                if (satellite.isFavorite)
                                {
                                    VStack
                                    {
                                        Text(satellite.wrappedName).font(.system(size:12))
                                        
                                        /*
                                         Text(String(location.mCoordinate.latitude)).font(.system(size:10))
                                         Text(String(location.mCoordinate.longitude)).font(.system(size:10))
                                         */
                                        /*
                                         NavigationLink(destination: DetailView(region: $region, mapType: $mapType, location: location)
                                         .environmentObject(mapSettings))
                                         {
                                         Text("Search Location")
                                         }
                                         .onTapGesture
                                         {
                                         //region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: location.mCoordinate.latitude, longitude: location.mCoordinate.longitude), span: MKCoordinateSpan(latitudeDelta: 7, longitudeDelta: 7))
                                         //region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: location.mCoordinate.latitude, longitude: location.mCoordinate.longitude), span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5))
                                         }
                                         */
                                    }
                                    .padding()
                                    .background(Color.blue.opacity(0.5))
                                    .cornerRadius(10)
                                    .padding()
                                }
                                
                            }
                        }
                    }
                }
                
                Section()
                {
                    Picker("Query Type", selection: $gQuery)
                    {
                        Text("Name").tag("NAME=")
                        Text("International Designator").tag("INTDES=")
                        Text("Group").tag("GROUP=")
                        Text("Catalog Number").tag("CATNR=")
                    }
                    .pickerStyle(.segmented)
                    
                    HStack
                    {
                        Text("Add Satellite:")
                        TextField("Value", text: $gValue)
                    }
                    Button("Add")
                    {
                        addSatellite()
                    }
                }
                
                Section()
                {
                    NavigationLink(destination: ListView(/*satellites: satellites*/))
                    {
                        Text("List Satellites")
                    }
                }
            }
            .navigationTitle("Map")
            .listStyle(.grouped)
        }
    } // NavigationView
}

struct ListView: View
{
    @Environment(\.managedObjectContext) var objContext
    @FetchRequest(entity: Satellite.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Satellite.name, ascending: true)]) var satellites : FetchedResults<Satellite>
    
    var body: some View
    {
        List
        {
            Text("Satellite Search").font(.system(size: 30))
            
            ForEach(satellites)
            {
                satellite in
                VStack
                {
                    HStack
                    {
                        VStack
                        {
                            Text(satellite.wrappedName)
                            //Text(String(satellite.mLongitude))
                            //Text(String(satellite.mLatitude))
                        }
                        if (satellite.isFavorite)
                        {
                            Image("YellowStar")
                                .resizable().aspectRatio(contentMode: .fit).frame(maxWidth: 50, maxHeight: 50)                    .onTapGesture
                            {
                                satellite.isFavorite.toggle()
                                
                                // FIXME: Make ObservableObject that refreshes automatically when modified
                                //satellites.append(Satellite())
                                //satellites.remove(at: satellites.count-1)
                            }
                        }
                        else
                        {
                            Image("GrayStar")
                                .resizable().aspectRatio(contentMode: .fit).frame(maxWidth: 50, maxHeight: 50)                    .onTapGesture
                            {
                                satellite.isFavorite.toggle()
                                
                                // FIXME: Make ObservableObject that refreshes automatically when modified
                                //satellites.append(Satellite())
                                //satellites.remove(at: satellites.count-1)
                            }
                        }
                        Image("Trash")
                            .resizable().aspectRatio(contentMode: .fit).frame(maxWidth: 50, maxHeight: 50)                    .onTapGesture
                        {
                            //satellites.removeAll(where: {$0.name == satellite.wrappedName})
                        }
                    }
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ContentView()
    }
}
 

/*
// Codable: Allows the object to be decoded from one representation and encoded into another.
struct OrbitalDataJSON : Codable
{
    var OBJECT_NAME : String = ""
    var OBJECT_ID : String = ""
    var EPOCH : String = ""
    var MEAN_MOTION : Double = 0
    var ECCENTRICITY : Double = 0
    var INCLINATION : Double = 0
    var RA_OF_ASC_NODE : Double = 0
    var ARG_OF_PERICENTER : Double = 0
    var MEAN_ANOMALY : Double = 0
    var EPHEMERIS_TYPE : Int = 0
    var CLASSIFICATION_TYPE : String = ""
    var NORAD_CAT_ID : Int = 0
    var ELEMENT_SET_NO : Int = 0
    var REV_AT_EPOCH : Int = 0
    var BSTAR : Double = 0
    var MEAN_MOTION_DOT : Double = 0
    var MEAN_MOTION_DDOT : Double = 0
}
*/

/*
func getSatellite2()
{
    let urlAsString : String = "https://celestrak.org/NORAD/elements/gp.php?" + gQuery + gValue + "&FORMAT=JSON-PRETTY"
    let testURL : String = "https://celestrak.org/NORAD/elements/gp.php?NAME=MICROSAT-R&FORMAT=JSON-PRETTY"
    let url = URL(string: urlAsString)!
    let urlSession = URLSession.shared
    
    // jsonQuery is a new task that will run separately to the main thread
    let jsonQuery = urlSession.dataTask(with: url, completionHandler:
    {
        data, response, error -> Void in
        if (error != nil)
        {
            print(error!.localizedDescription)
        }
        
        do {
            let decoder = JSONDecoder()
            // TRICKY: Note the use of [OrbitalData] result as an array
            // as the Celestrak REST API returns JSON results in a JSON array
            let jsonResult = try decoder.decode([OrbitalDataJSON].self, from: data!)
            if (jsonResult != nil)
            {
                var orbitalData : OrbitalDataJSON = jsonResult[0]
                var newSatellite : Satellite = Satellite()
                
                newSatellite.mName = orbitalData.OBJECT_NAME
                newSatellite.mData2 = orbitalData
                
                // TRICKY: Calling a C routine that needs to return values using C pointers
                // In SwiftUI, we simulate C pointers using UnsafeMutablePointer<>
                var age : Double = 0
                var ageP : UnsafeMutablePointer<Double> = .init(&age)
                var lat : Double = 0
                var latP : UnsafeMutablePointer<Double> = .init(&lat)
                var lon : Double = 0
                var lonP : UnsafeMutablePointer<Double> = .init(&lon)
                var alt : Double = 0
                var altP : UnsafeMutablePointer<Double> = .init(&alt)
                
                // TRICKY: Call C function here using the SwiftUI binding header decl.
                orbit_to_lla(nil, nil, nil, ageP, latP, lonP, altP)
                newSatellite.mLatitude = lat
                newSatellite.mLongitude = lon
                
                var isUnique : Bool = ((satellites.first(where: {$0.mName == newSatellite.mName})) == nil)
                if (isUnique)
                {
                    satellites.append(newSatellite)
                }
            }
        } catch DecodingError.dataCorrupted(let context) {
            print(context)
        } catch DecodingError.keyNotFound(let key, let context) {
            print("Key '\(key)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch DecodingError.valueNotFound(let value, let context) {
            print("Value '\(value)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch DecodingError.typeMismatch(let type, let context) {
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch {
            print("error: ", error)
        }
    })
    // resume() tells the task to start running on its own thread
    jsonQuery.resume()
}
*/
