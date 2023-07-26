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

        for satellite in satellites
        {
            let coords : GeoCoords = calculateGeoCoords(inSatellite: satellite, inTime: time)
            let newAnnotation : MKPointAnnotation = MKPointAnnotation(__coordinate: CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude), title: coords.name, subtitle: nil)
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
