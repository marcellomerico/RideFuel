//
//  PersistenceController.swift
//  RideFuel
//
//  Created by Marcello Merico on 06.08.25.
//
import Foundation
import CoreData


struct PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Optional: Beispiel-Daten einfügen
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RideFuel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}


