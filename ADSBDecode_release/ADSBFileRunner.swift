//
//  ADSBRunner.swift
//  LearnMapKit
//
//  Created by Jacky Jack on 28/06/2024.
//

import Foundation
import Collections

class ADSBFileRunner {
    var filename: URL
    //track all airplanes
    var tracker = AirPlaneTracker()
    var adsb_source: String = ""
    //should make it outside and use here?
    var adsb_tag_stream = ADSBDataQueue()
    private var decoded_status: Bool = false
    
    init(filename:String) {
        self.filename = URL(fileURLWithPath:filename)
    }
    
    init() {
        self.filename = URL(fileURLWithPath:"")
    }
    
    func setFileName(_ filename:String) {
        self.filename = URL(fileURLWithPath: filename)
    }
    
    func openFile() {
        if self.filename == URL(fileURLWithPath:"") {
            print("File name for ADSBRunner not specified")
            return
        }
        print("File location [\(filename.absoluteString)]")

        //check if file excists
        if (checkIfFileExists(filename.path) == false) {
            print("Supplied path \(filename.path) doesnt exists")
            exit(1)
        }
    }
    
    func readFile() {
        //load the file with adsb data
        do {
            adsb_source = try String(contentsOfFile: filename.path)
            print("Loaded \(adsb_source.count) bytes")
        } catch {
            print("Couldn't load text from a file \(filename.path) \(error)")
            exit(1)
        }
        print("If there anything new in file")
    }
    
    func decodeFromFile() {
        for line in self.adsb_source.components(separatedBy: .newlines) {
            var found=false
            do {
                if let tokenMatch = try matchADSBLong.prefixMatch(in: line) {
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
                                    tracker.addDF17Indentification(d17.AddressAnnounced, indentification.ICAOName)
                                    adsb_tag_stream.addIcaoName(d17.AddressAnnounced, tracker.getICAOname(d17.AddressAnnounced)!)
                                }
                            } else if (d17.TypeCode >= 9 && d17.TypeCode <= 18) {
                                if let airbornposition = d17.messageAirbornPositon {
                                    tracker.addDF17AirBornPosition(
                                        d17.AddressAnnounced,
                                        airbornposition.Latitude,
                                        airbornposition.Longitude,
                                        airbornposition.Altitude,
                                        airbornposition.CPRFormat == 0
                                    )
                                    if let position = tracker.getPosition(d17.AddressAnnounced) {
                                        print("position: \(position)")
                                        adsb_tag_stream.addAltitude(d17.AddressAnnounced, tracker.getAltitude(d17.AddressAnnounced)!)
                                        let location = tracker.getPosition(d17.AddressAnnounced)!
                                        adsb_tag_stream.addLocation(d17.AddressAnnounced, location.0, location.1)
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
                print("Unknown adsb data line \(line)")
            }
        }
        self.decoded_status = true
        //try to free the string after decoded
        //adsb_source = ""
        for i in 0..<adsb_tag_stream.icaoArray.count {
            print(adsb_tag_stream.icaoArray[i])
        }
        print("Queue done")
    }
    
    func jobDone() -> Bool {
        return self.decoded_status
    }
    
    func getPlainData(_ num_queries: Int) -> ADSBDataQueue {
        var ret = ADSBDataQueue()
        if adsb_tag_stream.haveNum(num_queries) {
            
            for _ in 0..<num_queries {
                let nextTag = adsb_tag_stream.getNextTag()
                if nextTag == DataStreamType.EMPTY {
                    return ret
                }
                if (nextTag == DataStreamType.ADSB_ALTITUDE) {
                    let alt = adsb_tag_stream.getAltitude()
                    ret.addAltitude(alt.address, alt.altitude)
                } else if (nextTag == DataStreamType.ADSB_ICAO) {
                    let icao = adsb_tag_stream.getIcaoName()
                    ret.addIcaoName(icao.address, icao.ICAOname)
                } else if (nextTag == DataStreamType.ADSB_LOCATION) {
                    let loc = adsb_tag_stream.getLocation()
                    ret.addLocation(loc.address, loc.lat, loc.long)
                }
            }
            return ret
        } else {
            print("Plain data query is empty")
        }
        return ret
    }
    
    func getCount() -> Int {
        return self.adsb_tag_stream.getCount()
    }
}


