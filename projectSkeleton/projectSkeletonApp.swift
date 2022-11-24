//
//  projectSkeletonApp.swift
//  projectSkeleton
//
//  Created by Matthew Fitzgerald on 10/23/22.
//

import SwiftUI

@main
struct projectSkeletonApp: App {
    //Core data
    @StateObject var persistentData = PersistentData()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistentData.container.viewContext)
        }
    }
}
