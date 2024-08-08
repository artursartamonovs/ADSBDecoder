//
//  FlighState.swift
//  LearnMapKit
//
//  Created by Jacky Jack on 30/06/2024.
//

import Foundation
import Collections


class FlightTracker {
    var last_time_seen: Int = 0
    var ICAOName_avaliable = false
    @Published var ICAOName = ""
    var Position_avaliable = false
    @Published var long:Double = 0.0
    @Published var lat:Double = 0.0
    var FromTo_avaliable = false
    var flightFrom:String = ""
    var flightTo:String = ""
}

class FlightState: ObservableObject {
    var timer: Timer?
    //default location currently for testing
    var fromFile: Bool = false
    @Published var flight:[Int:FlightTracker] = [:]
    
    //configuration options
    let sourceFile = false
    let default_file_path = "/Users/jackyjack/Downloads/2024_05_27_raw_adsb.txt"
    let process_per_second = 120
    
    let sourceDump1090Server = true
    let dump1090address = "192.168.4.201"
    let dump1090port = 30002
    
    init() {
        var count = 0
        
        //let ADSBtask = ADSBFileRunner(filename: "")
        let adsb_file = ADSBFileRunner(filename: self.default_file_path)
        //let adsb_net = ADSBNetRunner(address: dump1090address, port: dump1090port)
        
        if sourceFile {
            DispatchQueue.global(qos: .background).sync {
                print("Open file")
                adsb_file.openFile()
                adsb_file.readFile()
            }
            
            DispatchQueue.global(qos: .background).async {
                print("Start decoding data")
                adsb_file.decodeFromFile()
                print("Stop decoding data")
            }
            
            //once a second read some data from decoded queue
            timer = Timer.scheduledTimer(
                withTimeInterval: 1,
                repeats: true
            ) { _ in
                //get the 10 entries if there is
                if adsb_file.jobDone() {
                    print("Decoding done let get some data \(adsb_file.getCount())")
                    //if adsb_file
                    if adsb_file.getCount() > self.process_per_second {
                        let data = adsb_file.getPlainData(self.process_per_second)
                        //print(data.getCount())
                        for idx in 0..<data.getCount() {
                            let nextTag = data.getNextTag()
                            if nextTag == DataStreamType.ADSB_ALTITUDE {
                                let _ = data.getAltitude()
#warning("Implement this")
                            } else if (nextTag == DataStreamType.ADSB_ICAO) {
                                let icao = data.getIcaoName()
                                print("Tag icao \(icao) count:\(data.icaoArray.count)")
                                self.addIcaoName(icao.address, icao.ICAOname)
                            } else if (nextTag == DataStreamType.ADSB_LOCATION) {
                                print("tag location")
                                let loc = data.getLocation()
                                self.addLocation(loc.address, loc.lat, loc.long)
                            }
                        }
                        
                    } else {
                        print("Data stream is empty")
                    }
                }
            }
        }
        
        if sourceDump1090Server {
            let ADSBClient = NetADSBDecoder(host: "192.168.4.201", port: 30002)
            timer = Timer.scheduledTimer(
                withTimeInterval: 1,
                repeats: true
            ) { _ in
                //print("Timer drain queue")
                //print("\(ADSBClient.msgarray.message_array.count)")
                if ADSBClient.msgarray.message_array.count > 0 {
                    print(ADSBClient.msgarray.message_array.count)
                    for i in 0..<ADSBClient.msgarray.message_array.count {
                        print(ADSBClient.msgarray.message_array.popLast()!,terminator: "")
                    }
                }
            }
            
            DispatchQueue.global(qos: .background).async {
                do {
                    try ADSBClient.start()
                } catch let error {
                    print("Error: \(error.localizedDescription)")
                    ADSBClient.stop()
                }
            }
            
        }
    }
    
    init(filename: String) {
        #warning("not implemented at all")
    }
    
    func addLocation(_ address: Int, _ lat: Double, _ long: Double) {
        if flight[address] == nil {
            flight[address] = FlightTracker()
            flight[address]?.last_time_seen = Int(Date().timeIntervalSince1970)
            flight[address]?.Position_avaliable = true
            flight[address]?.lat = lat
            flight[address]?.long = long
            print("new location")
            return
        } else {
            if let f = flight[address] {
                f.last_time_seen = Int(Date().timeIntervalSince1970)
                f.Position_avaliable = true
                f.lat = lat
                f.long = long
                print("Update location \(flight.count)")
                return
            }
            
        }
        print("No update?")
    }
    
    func addIcaoName(_ address: Int, _ icaoname: String) {
        if flight[address] == nil {
            flight[address] = FlightTracker()
            flight[address]?.last_time_seen = Int(Date().timeIntervalSince1970)
            flight[address]?.ICAOName_avaliable = true
            flight[address]?.ICAOName = icaoname
            print("new flight name added \(icaoname)")
            return
        } else {
            if let f = flight[address] {
                f.last_time_seen = Int(Date().timeIntervalSince1970)
                if  f.ICAOName_avaliable == false{
                    f.ICAOName_avaliable = true
                    f.ICAOName = icaoname
                    print("flight timestamp updated")
                    return
                }
            }
        }
        print("no update?!")
    }
    
    func addNewFlight() {
        
    }
    
    //loop over and if expired then remove
    func removeExpiredFlight() {
        for (address,el) in self.flight {
            //if on the map more then 1 minute
            if el.last_time_seen+60 < Int(Date().timeIntervalSince1970) {
                self.flight.removeValue(forKey: address)
            }
        }
    }
    
}

