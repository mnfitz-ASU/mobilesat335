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

struct SideMenu: View
{
    @Binding var isShowing: Bool
    var content: AnyView
    var edgeTransition: AnyTransition = .move(edge: .leading)
    var body: some View {
        ZStack(alignment: .bottom) {
            if (isShowing) {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isShowing.toggle()
                    }
                content
                    .transition(edgeTransition)
                    .background(
                        Color.clear
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
        .animation(.easeInOut, value: isShowing)
    }
}

struct MainView: View {
    @State private var tabSelection = 1;
    @State private var isShowing = false;

    @State var time : Date = Date.now
    @State var value : String = ""
    
    var body: some View {
        
        TabView(selection: $tabSelection)
        {
            ContentView(tabSelection: $tabSelection)
                .tabItem {
                    Label("Home", systemImage: "house")
                        .onTapGesture {
                                tabSelection = 1
                        }
                        .tag(1)
                }.padding()
            
            ListView(tabSelection: $tabSelection, time: $time)
                .tabItem {
                    Label("List", systemImage: "line.3.horizontal")
                        .onTapGesture {
                                tabSelection = 2
                        }
                        .tag(2)
                }.padding()
            
            
            AddView(tabSelection: $tabSelection, time: $time, value: $value)
                .tabItem {
                    Label("Add", systemImage: "plus.square")
                        .onTapGesture {
                                tabSelection = 3
                        }
                        .tag(3)
                }.padding()
             
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding()
    }
}

struct MainView_Previews: PreviewProvider
{
    static var previews: some View
    {
        MainView()
    }
}
