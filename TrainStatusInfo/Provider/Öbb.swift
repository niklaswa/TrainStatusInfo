//
//  Öbb.swift
//  TrainStatusInfo
//
//  Created by niklas on 06.04.22.
//

import Foundation

class Öbb: TrainProvider {
    let url = "https://railnet.oebb.at/assets/modules/fis/combined.json?_time="
    
    struct OperationalMessagesInfo: Decodable {
        let speed: String
    }
    
    struct StationName: Decodable {
        let all: String
    }
    
    struct CurrentStation: Decodable {
        let arrivalForecast: String
        let name: StationName
    }
    
    struct CombinedJson: Decodable {
        let operationalMessagesInfo: OperationalMessagesInfo
        let currentStation: CurrentStation
    }
    
    override func fetchData() {
        let timeInterval = NSDate().timeIntervalSince1970
        let url = URL(string: self.url + String(timeInterval))!
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            let combinedInfo: CombinedJson = try! self.decoder.decode(CombinedJson.self, from: data)
            self.speed = Int(combinedInfo.operationalMessagesInfo.speed)
            self.nextStation = combinedInfo.currentStation.name.all
            
            if (combinedInfo.currentStation.arrivalForecast.contains(":")) {
                let timeParts = combinedInfo.currentStation.arrivalForecast.components(separatedBy: ":")
                self.arrivalDate = Calendar.current.date(bySettingHour: Int(timeParts[0])!, minute: Int(timeParts[1])!, second: 30, of: Date())!
            }
        }
        task.resume()
    }
    
    override func isAvailable(completion: @escaping (Bool)->()) {
        let timeInterval = NSDate().timeIntervalSince1970
        let url = URL(string: self.url + String(timeInterval))!
        URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let data = json["operationalMessagesInfo"] as? [String:Any] {
                        if (data["speed"] as? String?) != nil {
                            completion(true)
                        }
                    }
                }
            } catch {
                completion(false)
            }
        }.resume()
    }
}
