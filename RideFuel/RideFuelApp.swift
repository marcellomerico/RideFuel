//
//  RideFuelApp.swift
//  RideFuel
//
//  Created by Marcello Merico on 06.08.25.
//

import SwiftUI

@main
struct RideFuelApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}

