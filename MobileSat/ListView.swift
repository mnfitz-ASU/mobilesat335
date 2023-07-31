//
//  ListView.swift
//  MobileSat
//
//  Created by Matthew Fitzgerald on 1/14/23.
//
import CoreData
import SwiftUI
import Foundation
import MapKit

struct ListView: View
{
    @Binding var tabSelection: Int
    
    @Environment(\.managedObjectContext) var objContext
    @FetchRequest(entity: Satellite.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Satellite.name, ascending: true)]) var satellites : FetchedResults<Satellite>
    @Binding var time : Date
    
    var body: some View
    {
        List
        {
            Text("Satellite Search").font(.system(size: 30))
            
            ForEach(satellites)
            {
                satellite in
                let coords : GeoCoords = calculateGeoCoords(inSatellite: satellite, inTime: time)
                VStack
                {
                    HStack
                    {
                        VStack
                        {
                            Text(satellite.wrappedName)
                            Text(String(round(100 * coords.longitude) / 100))
                            Text(String(round(100 * coords.latitude) / 100))
                            Text(String(round(100 * coords.altitude) / 100))
                        }
                        if (satellite.isFavorite)
                        {
                            Image("YellowStar")
                                .resizable().aspectRatio(contentMode: .fit).frame(maxWidth: 50, maxHeight: 50)                    .onTapGesture
                            {
                                satellite.isFavorite.toggle()
                                
                                do
                                {
                                    try objContext.save()
                                }
                                catch
                                {
                                    // error
                                }
                            }
                        }
                        else
                        {
                            Image("GrayStar")
                                .resizable().aspectRatio(contentMode: .fit).frame(maxWidth: 50, maxHeight: 50)                    .onTapGesture
                            {
                                satellite.isFavorite.toggle()
                                
                                do
                                {
                                    try objContext.save()
                                }
                                catch
                                {
                                    // error
                                }
                            }
                        }
                        Image("Trash")
                            .resizable().aspectRatio(contentMode: .fit).frame(maxWidth: 50, maxHeight: 50)                    .onTapGesture
                        {
                            objContext.delete(satellite)
                            do
                            {
                                try objContext.save()
                            }
                            catch
                            {
                                // error
                            }
                        }
                    }
                }
            }
        }
    }
}
