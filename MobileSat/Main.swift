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
    @Binding var isSidebarVisible: Bool
    var edgeTransition: AnyTransition = .move(edge: .leading)
    var sideBarWidth = UIScreen.main.bounds.size.width * 0.8
    var bgColor: Color =
          Color(.init(
                  red: 52 / 255,
                  green: 70 / 255,
                  blue: 182 / 255,
                  alpha: 1))

   var body: some View {
       ZStack {
           GeometryReader { _ in
               EmptyView()
           }
           .background(.black.opacity(0.6))
           .opacity(isSidebarVisible ? 1 : 0)
           .animation(.easeInOut.delay(0.2), value: isSidebarVisible)
           .onTapGesture {
               isSidebarVisible.toggle()
           }
           content
       }
       .edgesIgnoringSafeArea(.all)
   }

   var content: some View {
       HStack(alignment: .top) {
           ZStack(alignment: .top) {
               bgColor
               NavigationView
               {
                   List
                   {
                       NavigationLink {
                           SettingsView()
                       } label: {
                           Label("Settings", systemImage: "gearshape.fill")
                       }
                       
                       NavigationLink {
                           AccountView()
                       } label: {
                           Label("Account", systemImage: "person.fill")
                       }
                       
                       NavigationLink {
                           HelpView()
                       } label: {
                           Label("Help", systemImage: "questionmark.circle")
                       }
                       
                       NavigationLink {
                           AboutView()
                       } label: {
                           Label("About", systemImage: "info.circle")
                       }
                   }
               }
           }
           .frame(width: sideBarWidth)
           .offset(x: isSidebarVisible ? 0 : -sideBarWidth)
           .animation(.default, value: isSidebarVisible)

           Spacer()
       }
   }
}

struct MainView: View {
    @State private var tabSelection = 1;
    @State private var isShowing = false;

    @State var time : Date = Date.now
    @State var value : String = ""
    
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
                    .padding()
                
                ListView(tabSelection: $tabSelection, time: $time)
                    .tabItem {
                        Label("List", systemImage: "line.3.horizontal")
                            .onTapGesture {
                                tabSelection = 2
                            }
                            .tag(2)
                    }
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

            }
            
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
