//
//  Main.swift
//  MobileSat
//
//  Created by Matthew Fitzgerald on 7/25/23.
//

import CoreData
import SwiftUI
import Foundation
import MapKit

struct MainView: View {
    @State private var tabSelection = 1;
    @State private var isShowing = false;

    @State var time : Date = Date.now
    @State var value : String = ""
    
    @StateObject var locationManager = LocationDataManager()
    
    var body: some View {
        ZStack
        {
            TabView(selection: $tabSelection)
            {
                ContentView(tabSelection: $tabSelection)
                    .tabItem {
                        Label("Home", systemImage: "house")
                            .onTapGesture {
                                tabSelection = 1
                            }
                            .tag(1)
                    }
                    .environmentObject(self.locationManager)
                    .padding()
                
                ListView(tabSelection: $tabSelection, time: $time)
                    .tabItem {
                        Label("List", systemImage: "line.3.horizontal")
                            .onTapGesture {
                                tabSelection = 2
                            }
                            .tag(2)
                    }
                    .environmentObject(self.locationManager)
                    .padding()
                
                
                AddView(tabSelection: $tabSelection, time: $time, value: $value)
                    .tabItem {
                        Label("Add", systemImage: "plus.square")
                            .onTapGesture {
                                tabSelection = 3
                            }
                            .tag(3)
                    }
                    .padding()
                
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .bottom)

            /*
            VStack
            {
                Button(action:
                        {
                    isShowing.toggle()
                }) {
                    if (!isShowing){
                        Label("", systemImage: "arrowshape.turn.up.right")
                    }
                    else
                    {
                        Label("", systemImage: "arrowshape.turn.up.left.fill")
                    }
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                
                SideMenu(isSidebarVisible: $isShowing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environmentObject(self.locationManager)


            }
             */
            
            /*
             .toolbar {
             Button {
             isShowing.toggle()
             } label: {
             Label("Toggle SideBar",
             systemImage: "arrowshape.turn.up.right")
             }
             }
             */
        }
    }
}

struct MainView_Previews: PreviewProvider
{
    static var previews: some View
    {
        MainView()
    }
}
