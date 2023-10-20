//
//  SidebarView.swift
//  MobileSat
//
//  Created by Matthew Fitzgerald on 7/31/23.
//

import CoreData
import SwiftUI
import Foundation
import MapKit
import CoreLocation
import CoreLocationUI

struct SideMenu: View
{
    @EnvironmentObject var locationManager : LocationDataManager

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
                               .environmentObject(self.locationManager)

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


struct SettingsView: View
{
    //@EnvironmentObject var locationManager : LocationDataManager

    var body: some View
    {
        VStack
        {
            Text("This is the Settings Page")
            /*
            LocationButton
            {
                locationManager.requestLocation()
            }
             */
        }
    }
}

struct AccountView: View
{
    var body: some View
    {
        VStack
        {
            Text("This is the Account Page")
        }
    }
}

struct HelpView: View
{
    var body: some View
    {
        VStack
        {
            Text("This is the Help Page")
        }
    }
}

struct AboutView: View
{
    var body: some View
    {
        VStack
        {
            Text("This is the About Page")
        }
    }
}
