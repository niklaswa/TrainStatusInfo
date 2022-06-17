//
//  TrainProvider.swift
//  TrainStatusInfo
//
//  Created by niklas on 06.04.22.
//

import Foundation

class TrainProvider {
    var speed: Int?
    var nextStation: String?
    var arrivalDate: Date?
    
    let decoder = JSONDecoder()
    
    func fetchData() {}
    func isAvailable(completion: @escaping (Bool)->()) {}
    func getPossibleSSIDs() -> [String] { return [] }
}
