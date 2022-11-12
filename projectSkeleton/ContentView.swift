//
//  ContentView.swift
//  Project Skeleton
//
//  Created by Matthew Fitzgerald on 10/23/22.
//

import SwiftUI
import Foundation
import MapKit

// Codable: Allows the object to be decoded from one representation and encoded into another.
struct OrbitalData : Codable
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

class Satellite : Identifiable
{
    var id : UUID = UUID()
    var mName : String = ""
    var mLatitude : Double = 0
    var mLongitude : Double = 0
    var mData : OrbitalData = OrbitalData()
    var mIsFavorite : Bool = false
    
    func UpdateData()
    {
        // ADD ME!!
    }
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
    @Binding var region : MKCoordinateRegion
    let satellites : [Satellite]
    @EnvironmentObject private var mapSettings : MyMapViewSettings
    
    // UIViewRepresentable wants these functions defined
    func makeUIView(context: Context) -> MKMapView
    {
        let mapView = MKMapView(frame: .zero)
        mapView.setRegion(region, animated: false)
        mapView.mapType = mapSettings.mapType

        for var satellite in satellites
        {
            // ADD ME
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context)
    {
        uiView.setRegion(region, animated: true)
        uiView.mapType = mapSettings.mapType
        
        for var satellite in satellites
        {
            // ADD ME
        }
    }
}

struct ContentView: View
{
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.048927, longitude: -111.093735), span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5))
    @ObservedObject var mapSettings = MyMapViewSettings()
    @State var mapType : MKMapType = .standard
    
    @State private var satellites : [Satellite] = []
    @State private var favorites : [Satellite] = []
    
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

    func getSatellite()
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
                let jsonResult = try decoder.decode([OrbitalData].self, from: data!)
                if (jsonResult != nil)
                {
                    var orbitalData : OrbitalData = jsonResult[0]
                    var newSatellite : Satellite = Satellite()
                    
                    newSatellite.mName = orbitalData.OBJECT_NAME
                    newSatellite.mData = orbitalData
                    //newSatellite.mLatitude = {INSERT CODE}
                    //newSatellite.mLongitude = {INSERT CODE}
                    
                    satellites.append(newSatellite)
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
                
                MyMapView(region: $region, satellites: satellites)
                .environmentObject(mapSettings)
                .frame(width: 400, height: 300)
                
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
                    Text("Search Satellite:")
                    TextField("Value", text: $gValue)
                }
                Button("Search")
                {
                    getSatellite()
                    print("Finish")
                }
                
                ScrollView(.horizontal, showsIndicators: true)
                {
                    HStack{
                        ForEach(favorites)
                        {
                            favorite in
                            // ADD FAVORITES HERE
                        }
                    }
                }
            }
            .navigationTitle("Map")
            .listStyle(.grouped)
        }
    } // NavigationView
}


struct AddView: View
{
    @Binding var satellites : [Satellite]
    
    @State var mSatellite : Satellite = Satellite()
    @State var mWasAdded : String = ""
    
    func AddSatellite(inSatellite : Satellite) -> Bool
    {
        // ADD SATELLITE SEARCH HERE
        
        let searchIndex = satellites.firstIndex(where: {$0.mName == inSatellite.mName})
        let isUnique: Bool = (searchIndex == nil)
        if (isUnique)
        {
            satellites.append(inSatellite)
        }
        return isUnique
    }
    
    var body: some View
    {
        VStack
        {
            Text("Add Satellite").font(.system(size: 30))
            
            VStack(alignment: .leading)
            {
                HStack()
                {
                    Text("Name: ")
                    TextField("Name", text: $mSatellite.mName)
                }
            }
            .padding()
            
            Button("Add Satellite")
            {
                var isAdded : Bool = AddSatellite(inSatellite: mSatellite)
                if (isAdded)
                {
                    mWasAdded = "Satellite " + mSatellite.mName + " was successfully Added."
                }
                else
                {
                    mWasAdded = "Satellite " + mSatellite.mName + " can't be added!"
                }
            }
            .padding()
            .background(Color.blue.opacity(0.5))
            .cornerRadius(10)
            .padding()
            
            Text("Result: " + mWasAdded).bold()
        }
    }
}

struct DeleteView: View
{
    @Binding var satellites : [Satellite]
    @Binding var favorites : [Satellite]
                    
    @State var mName : String = ""
    @State var mWasDeleted : String = "Nothing Deleted"
    
    func DeleteRecord(inName: String) -> Bool
    {
        let index = satellites.firstIndex(where: {$0.mName == inName})
        let isFound : Bool = (index != nil)
        if (isFound)
        {
            satellites.remove(at: index!)
        }
        return isFound
    }
    
    var body: some View
    {
        VStack
        {
            Text("Delete Satellite").font(.system(size: 30))

            VStack(alignment: .leading)
            {
                HStack
                {
                    Text("Name: ")
                    TextField("Name", text: $mName)
                }
            }
            .padding()
            
            Button("Delete Satellite")
            {
                let isDeleted : Bool = DeleteRecord(inName: mName)
                if (isDeleted){
                    mWasDeleted = "Satellite " + mName + " was successfully Deleted"
                }
                else{
                    mWasDeleted = "Nothing Deleted"
                }
            }
            .padding()
            .background(Color.blue.opacity(0.5))
            .cornerRadius(10)
            .padding()
            
            Text("Result: " + mWasDeleted).bold()
        }
    }
}

struct SearchView: View
{
    @Binding var satellites : [Satellite]
    @Binding var favorites : [Satellite]
    
    var body: some View
    {
        VStack
        {
            Text("Satellite Search").font(.system(size: 30))
            // ADD SATELLITE LIST AND FAVORITES BUTTON
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
