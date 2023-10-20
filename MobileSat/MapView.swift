//
//  MapView.swift
//  MobileSat
//
//  Created by Matthew Fitzgerald on 7/12/23.
//
import CoreData
import SwiftUI
import Foundation
import MapKit
import CoreLocation
import CoreLocationUI

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
    public var wrappedDate : Date {date ?? Date()-86400}
}

struct SatelliteSelect : Identifiable, Hashable
{
    var name : String = ""
    var tle1 : String = ""
    var tle2 : String = ""
    var date : Date = Date.now
    var isSelected : Bool = false
    var id : UUID = UUID()
}

class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var image: UIImage?
    var satellite : Satellite
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, image: UIImage?, satellite: Satellite) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.image = UIImage(systemName: satellite.icon!)
        
        self.satellite = satellite
    }
}
struct CustomAnnotationView: View {
        
    let annotation : CustomAnnotation
    
    var body: some View
    {
        ZStack
        {
            VStack(spacing: 0)
            {
                
                Image(uiImage: annotation.image!)
                /*
                Image(systemName: annotation.satellite.icon!)
                    .font(.title)
                    .foregroundColor(decodeColor(inString: annotation.satellite.color!))
                */
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.caption)
                    .foregroundColor(decodeColor(inString: annotation.satellite.color!))
                    .offset(x: 0, y: -5)
            }
            Text(annotation.title!)
                .font(.headline)
            Text(annotation.subtitle!)
                .font(.subheadline)
            
        }
    }
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
    let ageP : UnsafeMutablePointer<Double> = .init(&age)
    var lat : Double = 0
    let latP : UnsafeMutablePointer<Double> = .init(&lat)
    var lon : Double = 0
    let lonP : UnsafeMutablePointer<Double> = .init(&lon)
    var alt : Double = 0
    let altP : UnsafeMutablePointer<Double> = .init(&alt)
    
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
    
    var region : MKCoordinateRegion
    @Binding var time : Date
     
    @EnvironmentObject private var mapSettings : MyMapViewSettings
    @State var updateView : Int = 0
    
    @EnvironmentObject var locationManager : LocationDataManager

    
    //@Binding var isLocShared : Bool
    //@Binding var phoneLocation : CLLocationCoordinate2D
    
    // UIViewRepresentable wants these functions defined
    func makeUIView(context: Context) -> MKMapView
    {
        let mapView = MKMapView(frame: .zero)
        mapView.setRegion(region, animated: false)
        mapView.mapType = mapSettings.mapType
        
        mapView.removeAnnotations(mapView.annotations)

        for satellite in satellites
        {
            let coords : GeoCoords = calculateGeoCoords(inSatellite: satellite, inTime: time)
            
            let annotation = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude), title: coords.name, subtitle: nil, image: UIImage(systemName: satellite.icon!)
, satellite: satellite)
            mapView.addAnnotation(annotation)
            mapView.selectAnnotation(annotation, animated: true)
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
        
        let isLocKnown : Bool = ((locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways) && locationManager.location != nil)
        if (isLocKnown)
        {
            let phoneAnnotation : MKPointAnnotation = MKPointAnnotation(__coordinate: CLLocationCoordinate2D(latitude: locationManager.location!.latitude, longitude: locationManager.location!.longitude), title: "You", subtitle: "You are Here")
            uiView.addAnnotation(phoneAnnotation)
        }
        
        /*
        if (isLocShared)
        {
            var phoneAnnotation : MKPointAnnotation = MKPointAnnotation(__coordinate: CLLocationCoordinate2D(latitude: phoneLocation.latitude, longitude: phoneLocation.longitude), title: "You", subtitle: "You are Here")
            uiView.addAnnotation(phoneAnnotation)
        }
         */
        
        for satellite in satellites
        {
            //if (satellite.isFavorite)
            //{
                //uiView.remove
                let coords : GeoCoords = calculateGeoCoords(inSatellite: satellite, inTime: time)
            let annotation = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude), title: coords.name, subtitle: nil, image: UIImage(systemName: satellite.icon!), satellite: satellite)
                //var newAnnotation : MKPointAnnotation = MKPointAnnotation(__coordinate: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude), title: coords.name, subtitle: nil)
                uiView.addAnnotation(annotation)
                uiView.selectAnnotation(annotation, animated: true)
            //}
        }
    }
    
    func refresh()
    {
        updateView += 1
    }
}
