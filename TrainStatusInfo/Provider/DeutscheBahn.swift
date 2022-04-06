//
//  Öbb.swift
//  TrainStatusInfo
//
//  Created by niklas on 06.04.22.
//

import Foundation

class DeutscheBahn: TrainProvider {
    let statusUrl = "https://iceportal.de/api1/rs/status"
    let tripUrl = "https://iceportal.de/api1/rs/tripInfo/trip"
    
    struct Station: Decodable {
        let evaNr: String
        let name: String
    }

    struct Timetable: Decodable {
        let actualArrivalTime: Int?
    }

    struct Stop: Decodable {
        let station: Station
        let timetable: Timetable
    }

    struct StopInfo: Decodable {
        let actualNext: String
    }

    struct Trip: Decodable {
        let stops: [Stop]
        let stopInfo: StopInfo
    }

    struct TripJson: Decodable {
        let trip: Trip
    }

    struct Status: Decodable {
        let connection: Bool
        let speed: Int
    }
    
    override func fetchData() {
        let urlStatus = URL(string: statusUrl)!
        let taskStatus = URLSession.shared.dataTask(with: urlStatus) {(data, response, error) in
            guard let data = data else { return }
            let status: Status = try! self.decoder.decode(Status.self, from: data)
            self.speed = status.speed
        }
        taskStatus.resume()
        
        let urlTrip = URL(string: tripUrl)!
        let taskTrip = URLSession.shared.dataTask(with: urlTrip) {(data, response, error) in
            guard let data = data else { return }
            let tripJson: TripJson = try! self.decoder.decode(TripJson.self, from: data)
            
            let nextStationId = tripJson.trip.stopInfo.actualNext
            
            
            tripJson.trip.stops.forEach { stop in
                if nextStationId == stop.station.evaNr {
                    self.nextStation = stop.station.name
                    if stop.timetable.actualArrivalTime != nil {
                        self.arrivalDate = Date.init(timeIntervalSince1970: TimeInterval(stop.timetable.actualArrivalTime! / 1000))
                    }
                }
            }
        }
        taskTrip.resume()
    }
    
    override func isAvailable(completion: @escaping (Bool)->()) {
        let urlStatus = URL(string: statusUrl)!
        let task = URLSession.shared.dataTask(with: urlStatus) {(data, response, error) in
            guard let data = data else { return }
            do {
                let status: Status = try self.decoder.decode(Status.self, from: data)
                completion(status.connection)
            } catch {
                completion(false)
            }
        }
        task.resume()
    }
}
