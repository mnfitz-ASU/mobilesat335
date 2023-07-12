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
    
    var body: some View
    {
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
        .navigationBarTitle("Select Satellites to Add", displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action:
            {
                for selected in selectedList
                {
                    let isUnique : Bool = ((satellites.first(where: {$0.wrappedName == selected.name})) == nil)
                    if (isUnique)
                    {
                        var newSatellite : Satellite = Satellite(context: objContext)
                        newSatellite.name = selected.name
                        newSatellite.tleLine1 = selected.tle1
                        newSatellite.tleLine2 = selected.tle2
                        newSatellite.date = Date.now
                        
                        try? objContext.save()
                    }
                }
            })
            {
                Text("OK")
            }
        )
    }
}
