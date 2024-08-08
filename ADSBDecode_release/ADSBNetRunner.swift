//
//  ADSBNetRunner.swift
//  LearnMapKit
//
//  Created by Jacky Jack on 05/08/2024.
//

import Foundation

class ADSBNetRunner {
    var address = ""
    var port = 0
    var tracker = AirPlaneTracker()
    var adsb_tag_stream = ADSBDataQueue()
    var ADSBClient:NetADSBDecoder!
    var timer: Timer?
    
    init(address:String, port:Int) {
        self.address = address
        self.port = port
    }
    
    func start() {
        var found: Bool = false
        let ADSBClient = NetADSBDecoder(host: self.address, port: self.port)
        var _adsb_tag_stream = ADSBDataQueue()
        var _tracker = AirPlaneTracker()
        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { _ in
            //print("Timer drain queue")
            //print("\(ADSBClient.msgarray.message_array.count)")
            if ADSBClient.msgarray.message_array.count > 0 {
                print(ADSBClient.msgarray.message_array.count)
                for i in 0..<ADSBClient.msgarray.message_array.count {
                    found = false
                    //print(ADSBClient.msgarray.message_array.popLast()!,terminator: "")
                    if let msg = ADSBClient.msgarray.message_array.popLast() {
                        do {
                            if let tokenMatch = try matchADSBLong.prefixMatch(in: msg) {
                                //print("\(String(tokenMatch.output))")
                                found = true
                                let str = String(tokenMatch.output)
                                let startIndex = str.index(str.startIndex, offsetBy: 1)
                                let endIndex = str.index(str.endIndex, offsetBy: -2)
                                let decoder = Decoder(String(str[startIndex...endIndex]))
                                if decoder.DataFormat == 17 {
                                    if let d17 = decoder.getDataFormat17() {
                                        if (d17.TypeCode == 4) {
                                            if let indentification = d17.messageIdentification {
                                                _tracker.addDF17Indentification(d17.AddressAnnounced, indentification.ICAOName)
                                                _adsb_tag_stream.addIcaoName(d17.AddressAnnounced, _tracker.getICAOname(d17.AddressAnnounced)!)
                                            }
                                        } else if (d17.TypeCode >= 9 && d17.TypeCode <= 18) {
                                            if let airbornposition = d17.messageAirbornPositon {
                                                _tracker.addDF17AirBornPosition(
                                                    d17.AddressAnnounced,
                                                    airbornposition.Latitude,
                                                    airbornposition.Longitude,
                                                    airbornposition.Altitude,
                                                    airbornposition.CPRFormat == 0
                                                )
                                                if let position = _tracker.getPosition(d17.AddressAnnounced) {
                                                    print("position: \(position)")
                                                    _adsb_tag_stream.addAltitude(d17.AddressAnnounced, _tracker.getAltitude(d17.AddressAnnounced)!)
                                                    let location = _tracker.getPosition(d17.AddressAnnounced)!
                                                    _adsb_tag_stream.addLocation(d17.AddressAnnounced, location.0, location.1)
                                                }
                                            }
                                        }
                                    }
                                }
                            };
                        } catch {
                            print("Error")
                        }
                        
                        if (found == false) {
                            print("Unknown adsb data line \(msg)")
                        }
                    }
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
    
    func getDataOut() {
        
    }
    
    func stop() {
        
    }
    
    func getCount() -> Int {
        return self.adsb_tag_stream.getCount()
    }
}
