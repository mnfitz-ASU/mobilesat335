//
//  AddListView.swift
//  MobileSat
//
//  Created by Matthew Fitzgerald on 1/14/23.
//
import CoreData
import SwiftUI
import Foundation
import MapKit

struct AddView: View
{
    @Binding var tabSelection: Int
    
    @State var queryType : String = "NAME"
    @State var brightSatellites : [SatelliteSelect] = []
    @State var gpsSatellites : [SatelliteSelect] = []
    
    @Environment(\.managedObjectContext) var objContext
    @FetchRequest(entity: Satellite.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Satellite.name, ascending: true)]) var satellites : FetchedResults<Satellite>
    @Binding var time : Date
    @Binding var value : String
    
    
    func addSatelliteName()
    {
        let nameUrl : String = "https://celestrak.org/NORAD/elements/gp.php?NAME=" + value + "&FORMAT=TLE"
        
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
                    
                    let isUnique : Bool = ((satellites.first(where: {$0.wrappedName == name})) == nil)
                    if (isUnique)
                    {
                        let newSatellite : Satellite = Satellite(context: objContext)
                        newSatellite.name = name
                        newSatellite.tleLine1 = line1
                        newSatellite.tleLine2 = line2
                        newSatellite.date = Date.now
                        
                        newSatellite.icon = "circle.fill"
                        newSatellite.color = "red"
                                    
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
        
        let url = URL(string: brightestUrl)!
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
                        newSatellite.date = Date.now
                        
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
        
        let url = URL(string: gpsUrl)!
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
                        newSatellite.date = Date.now
                        
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
        VStack
        {
            Picker("Search By: ", selection: $queryType)
            {
                Text("Name").tag("NAME")
                Text("Brightest").tag("BRIGHTEST")
                Text("GPS").tag("GPS")
            }
            .pickerStyle(.segmented)
            
            switch queryType
            {
            case "NAME":
                VStack
                {
                    HStack
                    {
                        Text("Satellite Name:")
                        TextField("Name", text: $value)
                    }
                    Button(action:addSatelliteName) {
                        Label("Add", systemImage: "pencil.circle")
                    }
                }
                
            case "BRIGHTEST":
                VStack
                {
                    AddListView(inList: $brightSatellites).onAppear(perform: {
                        self.addSatelliteBrightest()
                    })
                }
            case "GPS":
                VStack
                {
                    AddListView(inList: $gpsSatellites).onAppear(perform: {
                    self.addSatelliteGPS()
                    })
                }
            default:
                Text("Something went wrong.")
            }
        }
    }
}

struct MultipleSelectionRow: View
{
    var name : String
    var isSelected : Bool
    var action: () -> Void

    var body: some View
    {
        Button(action: self.action)
        {
            HStack
            {
                Text(self.name)
                Spacer()
                if self.isSelected
                {
                    Image("GreenCircle")
                    .resizable().aspectRatio(contentMode: .fit).frame(maxWidth: 20, maxHeight: 20)
                }
                else
                {
                    Image("GrayCircle")
                    .resizable().aspectRatio(contentMode: .fit).frame(maxWidth: 20, maxHeight: 20)
                }
            }
        }
    }
}


struct AddListView: View
{
    @Environment(\.managedObjectContext) var objContext
    @FetchRequest(entity: Satellite.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Satellite.name, ascending: true)]) var satellites : FetchedResults<Satellite>
    @Binding var inList : [SatelliteSelect]
    @State var selectedList : [SatelliteSelect] = []
    
    @State var isAlertShown : Bool = false
    
    var body: some View
    {
        VStack
        {
            Button("Add", action: {
                for selected in selectedList
                {
                    let isUnique : Bool = ((satellites.first(where: {$0.wrappedName == selected.name})) == nil)
                    if (isUnique)
                    {
                        let newSatellite : Satellite = Satellite(context: objContext)
                        newSatellite.name = selected.name
                        newSatellite.tleLine1 = selected.tle1
                        newSatellite.tleLine2 = selected.tle2
                        newSatellite.date = Date.now
                        newSatellite.icon = "empty"
                        
                        try? objContext.save()
                    }
                }
                isAlertShown = true
            }) // Add Button
            .disabled(selectedList.isEmpty)
            .alert(isPresented: $isAlertShown) {
                    Alert(
                        title: Text("Satellites Successfully Added"),
                        message: Text("Added " + String(selectedList.count) + " satellites to your List.")
                    )
                }
            
            List
            {
                ForEach(inList, id: \.self)
                {
                    satellite in
                    MultipleSelectionRow(name: satellite.name, isSelected:  selectedList.contains(satellite))
                    {
                        if selectedList.contains(satellite)
                        {
                            selectedList.removeAll(where: { $0 == satellite })
                        }
                        else
                        {
                            selectedList.append(satellite)
                        }
                    }
                }
            }
            .onAppear(perform: {selectedList = []})
            .listStyle(GroupedListStyle())
        }
    }
}
