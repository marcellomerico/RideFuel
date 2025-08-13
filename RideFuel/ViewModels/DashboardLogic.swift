//
//  DashboardLogic.swift
//  RideFuel
//
//  Created by Marcello Merico on 13.08.25.
//

import Foundation

enum DashboardLogic {
    enum Period { case day, week, month }
    
    static func greeting(date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Guten Morgen \nUser"
        case 12..<18: return "Guten Tag"
        case 18..<22: return "Guten Abend"
        default: return "Hey"
        }
    }
    
    /// Wählt deterministisch je Periode ein Rezept.
    /// Quelle: übergebene Core Data Objekte (als Array)
    static func pick(_ period: Period, from rezepte: [Rezept], date: Date = Date()) -> Rezept? {
        guard !rezepte.isEmpty else { return nil }
        let cal = Calendar.current
        
        let seed: Int
        switch period {
        case .day:
            seed = cal.ordinality(of: .day, in: .year, for: date) ?? 0
        case .week:
            seed = cal.component(.weekOfYear, from: date)
        case .month:
            seed = cal.component(.month, from: date)
        }
        
        let idx = abs(seed.hashValue) % rezepte.count
        return rezepte[idx]
    }
}
