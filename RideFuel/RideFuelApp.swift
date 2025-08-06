//
//  RideFuelApp.swift
//  RideFuel
//
//  Created by Marcello Merico on 06.08.25.
//

import SwiftUI

@main
struct RideFuelApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
