//
//  Rezept+CoreDataProperties.swift
//  RideFuel
//
//  Created by Marcello Merico on 07.08.25.
//
//

import Foundation
import CoreData


extension Rezept {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Rezept> {
        return NSFetchRequest<Rezept>(entityName: "Rezept")
    }

    @NSManaged public var beschreibung: String?
    @NSManaged public var bildURL: String?
    @NSManaged public var eiweis: Double
    @NSManaged public var fett: Double
    @NSManaged public var id: UUID?
    @NSManaged public var kcal: Int16
    @NSManaged public var kohlenhydrate: Double
    @NSManaged public var name: String?
    @NSManaged public var zutaten: NSSet?

}

// MARK: Generated accessors for zutaten
extension Rezept {

    @objc(addZutatenObject:)
    @NSManaged public func addToZutaten(_ value: Zutat)

    @objc(removeZutatenObject:)
    @NSManaged public func removeFromZutaten(_ value: Zutat)

    @objc(addZutaten:)
    @NSManaged public func addToZutaten(_ values: NSSet)

    @objc(removeZutaten:)
    @NSManaged public func removeFromZutaten(_ values: NSSet)

}

extension Rezept : Identifiable {

}
