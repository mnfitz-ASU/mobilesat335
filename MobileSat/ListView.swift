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

public func decodeColor(inString: String) -> Color
{
    var outColor : Color = .red
    switch inString {
    case "red":
        outColor = .red
        
    case "orange":
        outColor = .orange
        
    case "yellow":
        outColor = .yellow
        
    case "green":
        outColor = .green
        
    case "blue":
        outColor = .blue
        
    case "purple":
        outColor = .purple
        
    default:
        outColor = .red
    }
    
    return outColor
}

struct ColorOptions: View
{
    @State var icon : String = "circle.fill"
    @State var color : String = "red"
    
    @State var satellite : Satellite
    
    @Environment(\.managedObjectContext) var objContext
    
    var edgeTransition: AnyTransition = .move(edge: .trailing)
    var sideBarWidth = UIScreen.main.bounds.size.width * 1
    var bgColor: Color =
    Color(.init(
        red: 100 / 255,
        green: 100 / 255,
        blue: 100 / 255,
        alpha: 1))
    
    var body: some View {
        
        ZStack {
            
            GeometryReader { _ in
                EmptyView()
            }
            .background(.black.opacity(0.4))
            .opacity(satellite.isColorMenu ? 1 : 0)
            .animation(.easeInOut.delay(0.2), value: satellite.isColorMenu)
            //.onTapGesture {
            //    isOptionsVisible.toggle()
            //}
            content
             
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    var content: some View
    {
        HStack(alignment: .top)
        {
            
            ZStack(alignment: .top)
            {
                bgColor
                VStack
                {
                    HStack
                    {   Label("Shape", systemImage:"")
                        
                        Button(action:{
                            icon = "circle.fill"
                        }) {Label("", systemImage: "circle.fill")}
                        
                        Button(action:{
                            icon = "triangle.fill"
                        }) {Label("", systemImage: "triangle.fill")}
                        
                        Button(action:{
                            icon = "square.fill"
                        }) {Label("", systemImage: "square.fill")}
                        
                        Button(action:{
                            icon = "pentagon.fill"
                        }) {Label("", systemImage: "pentagon.fill")}
                        
                        Button(action:{
                            icon = "hexagon.fill"
                        }) {Label("", systemImage: "hexagon.fill")}
                    }
                    HStack
                    {
                        Label("Color", systemImage:"")

                        Button(action:{
                            color = "red"
                        }) {Label("", systemImage: "paintpalette.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.red)}
                        
                        Button(action:{
                            color = "orange"
                        }) {Label("", systemImage: "paintpalette.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.orange)}
                        
                        Button(action:{
                            color = "yellow"
                        }) {Label("", systemImage: "paintpalette.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.yellow)}
                        
                        Button(action:{
                            color = "green"
                        }) {Label("", systemImage: "paintpalette.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.green)}
                        
                        Button(action:{
                            color = "blue"
                        }) {Label("", systemImage: "paintpalette.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.blue)}
                        
                        Button(action:{
                            color = "purple"
                        }) {Label("", systemImage: "paintpalette.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.purple)}
                    }
                    
                    Button(action:{
                        satellite.color = color
                        satellite.icon = icon
                        
                        satellite.isColorMenu = false
                        satellite.isColorMenu = false
                        satellite.isShowOptions = false
                        
                        try? objContext.save()
                    }) {Label("", systemImage: "checkmark.circle")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.green)}
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            //.frame(width: sideBarWidth, height: 200)
            .offset(x: satellite.isColorMenu ? 0 : -sideBarWidth)
            .animation(.default, value: satellite.isColorMenu)
        }
    }
 

struct ListOptions: View
{
    //@Binding var inSatellite: Satellite
    //@Binding var inTime : Date
    
    //@Binding var inCoords : GeoCoords
    @Binding var time : Date

    var satellite : Satellite
    
    @Environment(\.managedObjectContext) var objContext
    
    var edgeTransition: AnyTransition = .move(edge: .trailing)
    var sideBarWidth = UIScreen.main.bounds.size.width * 1
    var bgColor: Color =
    Color(.init(
        red: 200 / 255,
        green: 200 / 255,
        blue: 200 / 255,
        alpha: 1))
    
    var body: some View {
        
        ZStack {
            
            GeometryReader { _ in
                EmptyView()
            }
            .background(.black.opacity(0.4))
            .opacity(satellite.isShowOptions ? 1 : 0)
            .animation(.easeInOut.delay(0.2), value: satellite.isShowOptions)
            //.onTapGesture {
            //    isOptionsVisible.toggle()
            //}
            content
             
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    var content: some View {
        HStack(alignment: .top) {
            
            ZStack(alignment: .top) {
                bgColor
                HStack
                {
                    Button(action:{
                        
                        satellite.isShowOptions = false
                        
                    }) {Label("", systemImage: "arrow.left.to.line").padding([.leading])}
                    
                    //Text(satellite.wrappedName)
                    
                    
                    let coords : GeoCoords = calculateGeoCoords(inSatellite: satellite, inTime: time)
                    
                    VStack(alignment:.leading)
                    {
                        Text("Lat: " + String(round(100 * coords.longitude) / 100))
                        Text("Lon: " + String(round(100 * coords.latitude) / 100))
                        Text("Alt: " + String(round(100 * coords.altitude) / 100))
                    }
                     
                    
                    // Customize tack
                    Button(action:{
                        
                        satellite.isColorMenu = true
                        
                    }){Label("", systemImage: "paintpalette.fill")}
                    
                    // Delete
                    Button(action:{
                        
                        objContext.delete(satellite)
                        do
                        {
                            try objContext.save()
                        }
                        catch
                        {
                            // error
                        }
                         
                    }) {Label("", systemImage: "trash.fill")}
                     
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                ColorOptions(satellite: satellite)
            }
            //.frame(width: sideBarWidth, height: 200)
            .offset(x: satellite.isShowOptions ? 0 : -sideBarWidth)
            .animation(.default, value: satellite.isShowOptions)

            Spacer()
             
        }
    }
 }



struct ListView: View
{
    @Binding var tabSelection: Int
    
    @Environment(\.managedObjectContext) var objContext
    @FetchRequest(entity: Satellite.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Satellite.name, ascending: true)]) var satellites : FetchedResults<Satellite>
    @Binding var time : Date
    
    @EnvironmentObject var locationManager : LocationDataManager
    
    @State private var isPopMapShowing = false
    @State private var isTackSelectShowing = false

    @State private var displayCoords = CLLocationCoordinate2D(latitude: 37, longitude: 121)
    
    
    
    var body: some View
    {
        ScrollView(.vertical, showsIndicators: true)
        {
            VStack(alignment: .leading)
            {
                Text("Satellite Search").font(.system(size: 30))
                
                ForEach(satellites)
                {
                    satellite in
                    
                    ZStack
                    {
                        HStack
                        {
                            Button(action:{
                                
                                satellite.isShowOptions = true
                                
                            }) {Label("", systemImage: "arrow.right.to.line").padding([.leading])}
                            
                            let iconColor : Color = decodeColor(inString: satellite.color ?? "blue")
                            
                            Label("", systemImage: satellite.icon ?? "square")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(iconColor)
                            
                            Text(satellite.wrappedName)
                                .font(.system(size: 16))
                                .padding([.trailing])
                            
                            //let coords : GeoCoords = calculateGeoCoords(inSatellite: satellite, inTime: time)
                                
                            /*
                            VStack
                            {
                                
                                Label(String(round(100 * coords.longitude) / 100), systemImage: "")
                                Label(String(round(100 * coords.latitude) / 100), systemImage: "")
                                Label(String(round(100 * coords.altitude) / 100), systemImage: "")
                            }
                             */
                            /*
                            Button(action:{
                                isPopMapShowing = false
                                isPopMapShowing = true
                                
                                displayCoords.latitude = coords.latitude
                                displayCoords.longitude = coords.longitude
                            }) {Label("", systemImage: "binoculars.fill")}
                            */
                        }
                        //.frame(width: UIScreen.main.bounds.size.width * 1, height: 400)
                        .clipped()
                        .onAppear() {
                            isPopMapShowing = false
                        }
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onEnded({ value in
                                if value.translation.width > 0 {
                                    // right
                                    satellite.isShowOptions = true
                                }
                            }))
                        
                        
                        ListOptions(time: $time, satellite: satellite)
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onEnded({ value in
                        if value.translation.width < 0 {
                        // left
                        satellite.isShowOptions = false
                        try? objContext.save()

                        }
                        }))
                    }
                    //.frame(width: UIScreen.main.bounds.size.width * 1, height: 300)
                    .clipped()
                }
            }
        }
    }
}

