//
//  FlighState.swift
//  LearnMapKit
//
//  Created by Jacky Jack on 30/06/2024.
//

import Foundation
import Collections
import SwiftUI

class FlightTracker:  Identifiable {
    var last_time_seen: Int = 0
    var ICAOaddress = 0
    var ICAOName_avaliable = false
    //@Published var ICAOName = ""
    var ICAOName = ""
    var Position_avaliable = false
    @Published var long:Double = 0.0
    //var long:Double = 0.0
    @Published var lat:Double = 0.0
    //var lat:Double = 0.0
    var FromTo_avaliable = false
    var flightFrom:String = ""
    var flightTo:String = ""
    var id: String { String(ICAOaddress) }
    
    
    enum CodingKeys: String, CodingKey {
        case ICAOName
        case long
        case lat
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.ICAOName, forKey: .ICAOName)
        try container.encode(self.long, forKey: .long)
        try container.encode(self.lat, forKey: .lat)
    }
}



class FlightState: ObservableObject {
    var timer: Timer?
    //default location currently for testing
    var fromFile: Bool = false
    var idx_flight:[Int:Int] = [:]
    @Published var flight:[FlightTracker] = []
    
    //configuration options
    var sourceFile = false
    var default_file_path = "/Users/jackyjack/Downloads/2024_05_27_raw_adsb.txt"
    var process_per_second = 120
    
    var sourceDump1090Server = true
    var dump1090address = "192.168.4.233"
    var dump1090port = 30002
    
    init() {
        print("Init")
        var count = 0
        
        //let ADSBtask = ADSBFileRunner(filename: "")
        
        //let adsb_net = ADSBNetRunner(address: dump1090address, port: dump1090port)
        
        //if sourceFile {
        //    startSourceFile()
        //}
        
        //if sourceDump1090Server {
        //    startDump1090()
        //}
    }
    
    init(filename: String) {
        fileMode(filepath: filename)
        startSourceFile()
    }
    
    init(hostname: String, port: Int) {
        networkMode(hostname: hostname, port: port)
        startDump1090()
    }
    
    func networkMode(hostname: String, port: Int) {
        print("network mode")
        self.dump1090address = hostname
        self.dump1090port = port
        self.sourceDump1090Server = true
        self.sourceFile = false
    }
    
    func networkMode(netconfig: Binding<NetworkConfigure>) {
        print("network mode")
        self.dump1090address = netconfig.servername.wrappedValue
        self.dump1090port = netconfig.serverport.wrappedValue
        self.sourceDump1090Server = true
        self.sourceFile = false
    }
    
    func fileMode(filepath: String) {
        print("file mode")
        self.default_file_path = filepath
        self.sourceFile = true
        self.sourceDump1090Server = false
    }
    
    func defaultMode() {
        print("default mode")
        self.sourceDump1090Server = true
        self.sourceFile = false
    }
    
    func defaultMode(hostname: String, port: Int) {
        print("default mode net")
        self.sourceDump1090Server = true
        self.dump1090address = hostname
        self.dump1090port = port
        self.sourceFile = false
    }
    
    func startSourceFile() {
        print("Start reading ADSB messages from \(self.default_file_path)")
        let adsb_file = ADSBFileRunner(filename: self.default_file_path)
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
                    for _ in 0..<data.getCount() {
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
    
    func startDump1090() {
        print("Start reading ADSB messages from \(dump1090address):\(dump1090port)")
        //let ADSBClient = NetADSBDecoder(host: "192.168.4.201", port: 30002)
        //let ADSBClient = ADSBNetRunner(address: "192.168.4.201", port: 30002)
        let ADSBClient = ADSBNetRunner(address: dump1090address, port: dump1090port)
        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { _ in
            //print("Timer drain queue")
            //print("\(ADSBClient.msgarray.message_array.count)")
            /*if ADSBClient.msgarray.message_array.count > 0 {
                print(ADSBClient.msgarray.message_array.count)
                for i in 0..<ADSBClient.msgarray.message_array.count {
                    print(ADSBClient.msgarray.message_array.popLast()!,terminator: "")
                }
            }*/
            if ADSBClient.adsb_tag_stream.getCount() > 0 {
                //print("Process onse a second")
                for _ in 0..<ADSBClient.adsb_tag_stream.getCount() {
                    let nextTag = ADSBClient.adsb_tag_stream.getNextTag()
                    if nextTag == DataStreamType.ADSB_ALTITUDE {
                        let _ = ADSBClient.adsb_tag_stream.getAltitude()
#warning("Implement this")
                    } else if (nextTag == DataStreamType.ADSB_ICAO) {
                        let icao = ADSBClient.adsb_tag_stream.getIcaoName()
                        print("Tag icao \(icao) count:\(ADSBClient.adsb_tag_stream.icaoArray.count)")
                        self.addIcaoName(icao.address, icao.ICAOname)
                    } else if (nextTag == DataStreamType.ADSB_LOCATION) {
                        print("Tag location")
                        let loc = ADSBClient.adsb_tag_stream.getLocation()
                        self.addLocation(loc.address, loc.lat, loc.long)
                    }
                }
            }
        }
        /*
        DispatchQueue.global(qos: .background).async {
            do {
                try ADSBClient.start()
            } catch let error {
                print("Error: \(error.localizedDescription)")
                ADSBClient.stop()
            }
        }*/
        do {
            print("Start")
            try ADSBClient.start()
        } catch let error {
            print("Error: \(error.localizedDescription)")
            ADSBClient.stop()
        }
    }
    
    func run() {
        print("run")
        if self.sourceFile {
            startSourceFile()
        } else if self.sourceDump1090Server {
            startDump1090()
        }
    }
    
    func addLocation(_ address: Int, _ lat: Double, _ long: Double) {
        /*
        //usign as dictionary
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
                if f.ICAOName_avaliable {
                    print("Update location name: \(f.ICAOName) lat:\(f.lat) long:\(f.long)")
                } else {
                    print("Update location addr: \(address) lat:\(f.lat) long:\(f.long)")
                }
                return
            }
            
        }*/
        //using as array
        /*
        if self.idx_flight[address] == nil {
            let f = FlightTracker()
            f.ICAOaddress = address
            f.last_time_seen = Int(Date().timeIntervalSince1970)
            f.Position_avaliable = true
            f.lat = lat
            f.long = long
            flight.append(f)
            print(idx_flight[address])
            idx_flight[address] = flight.count-1
            print("add new location \(address) ")
        } else {
            if let idx = idx_flight[address] {
                let f = flight[idx]
                f.last_time_seen = Int(Date().timeIntervalSince1970)
                f.Position_avaliable = true
                f.lat = lat
                f.long = long
                if f.ICAOName_avaliable {
                    print("Update location name: \(f.ICAOName) lat:\(f.lat) long:\(f.long)")
                } else {
                    print("Update location addr: \(address) lat:\(f.lat) long:\(f.long)")
                }
                return
            }
        }*/
        if self.idx_flight[address] == nil {
            let f = FlightTracker()
            f.ICAOaddress = address
            f.last_time_seen = Int(Date().timeIntervalSince1970)
            f.Position_avaliable = true
            f.lat = lat
            f.long = long
            flight.append(f)
            //print(idx_flight[address])
            idx_flight[address] = flight.count-1
            print("add new location \(address) ")
        } else {
            if let idx = idx_flight[address] {
                print("Flights loc \(flight.count)")
                let f = flight[idx]
                f.last_time_seen = Int(Date().timeIntervalSince1970)
                f.Position_avaliable = true
                f.lat = lat
                f.long = long
                if f.ICAOName_avaliable {
                    print("Update location name: \(f.ICAOName) lat:\(f.lat) long:\(f.long)")
                } else {
                    print("Update location addr: \(address) lat:\(f.lat) long:\(f.long)")
                }
                flight.append(f)
                return
            }
        }
        //using as List
        //print("No update?")
    }
    
    func addIcaoName(_ address: Int, _ icaoname: String) {
        /*
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
                if  f.ICAOName_avaliable == false {
                    f.ICAOName_avaliable = true
                    f.ICAOName = icaoname
                    print("flight timestamp updated")
                    return
                }
            }
        }*/
        if idx_flight[address] == nil {
            let f = FlightTracker()
            f.ICAOaddress = address
            f.last_time_seen = Int(Date().timeIntervalSince1970)
            f.ICAOName_avaliable = true
            f.ICAOName = icaoname
            flight.append(f)
            idx_flight[address] = flight.count-1
        } else {
            if let idx = idx_flight[address] {
                print("Flights \(flight.count)")
                //let f = flight[idx]
                /*f.last_time_seen = Int(Date().timeIntervalSince1970)
                if  f.ICAOName_avaliable == false {
                    f.ICAOName_avaliable = true
                    f.ICAOName = icaoname
                    print("flight timestamp updated")
                    return
                }*/
            }
        }
        print("icao name")
    }
    
    func addNewFlight() {
        
    }
    
    //loop over and if expired then remove
    func removeExpiredFlight() {
        /*
        for (address,el) in self.flight {
            //if on the map more then 1 minute
            if el.last_time_seen+60 < Int(Date().timeIntervalSince1970) {
                self.flight.removeValue(forKey: address)
            }
        }
        */
    }
}

