//
//  ADSBDataQueue.swift
//  LearnMapKit
//
//  Created by Jacky Jack on 05/08/2024.
//

import Foundation
import Collections

struct ADSBLocation {
    let address: Int
    let lat: Double
    let long: Double
    //let alt: Int
}

struct ADSBAltitude {
    let address: Int
    let altitude: Int
}

struct ADSBICAOname {
    let address: Int
    let ICAOname: String
}

enum DataStreamType {
    case EMPTY
    case ADSB_ICAO
    case ADSB_LOCATION
    case ADSB_ALTITUDE
}

//get stream of decoded data, to tagged stream so all can be processed in sequence
class ADSBDataQueue {
    //var icaoQueue: Deque<ADSBICAOname> = []
    var icaoArray: Array<ADSBICAOname> = []
    var altQueue: Deque<ADSBAltitude> = []
    var locQueue: Deque<ADSBLocation> = []
    //var tagQueue: Deque<> = []
    var tagArray: Array<DataStreamType> = []
    
    func getNextTag() -> DataStreamType {
        if tagArray.count < 0 {
            return DataStreamType.EMPTY
        }
        return tagArray[tagArray.count-1]
    }
    
    func addIcaoName(_ address: Int, _ icaoname: String) {
        tagArray.append(DataStreamType.ADSB_ICAO)
        icaoArray.append(ADSBICAOname(address: address, ICAOname: icaoname))
    }
    
    func addAltitude(_ address: Int, _ altitude: Int) {
        tagArray.append(DataStreamType.ADSB_ALTITUDE)
        altQueue.append(ADSBAltitude(address: address, altitude: altitude))
    }
    
    func addLocation(_ address: Int, _ lat: Double, _ long: Double) {
        tagArray.append(DataStreamType.ADSB_LOCATION)
        locQueue.append(ADSBLocation(address: address, lat: lat, long: long))
    }
    
    func getIcaoName() -> ADSBICAOname {
        if tagArray.count < 1 {
            print("ADSB tag Queue is empty")
            return ADSBICAOname(address:0,ICAOname: "TEmpty")
        }
        let tag = tagArray[tagArray.count-1]
        if tag != DataStreamType.ADSB_ICAO {
            print("ADSB Queue empty")
            return ADSBICAOname(address:0,ICAOname: "QEmpty")
        }
        tagArray.removeLast()
        var ret_icao_name = ADSBICAOname(address:0, ICAOname: "Default")
        if let last_icao_name = icaoArray.popLast() {
            ret_icao_name = last_icao_name
        }
        return ret_icao_name
    }
    
    func getAltitude() -> ADSBAltitude {
        if tagArray.count < 1 {
            print("ADSB tag Queue is empty")
            return ADSBAltitude(address:0,altitude:0)
        }
        let tag = tagArray[tagArray.count-1]
        if tag != DataStreamType.ADSB_ALTITUDE {
            print("ADSB Queue empty")
            return ADSBAltitude(address:0,altitude:0)
        }
        tagArray.removeLast()
        return altQueue.popLast()!
    }
    
    func getLocation() -> ADSBLocation {
        if tagArray.count < 1 {
            print("ADSB tag Queue is empry")
            return ADSBLocation(address:0,lat:0.0,long:0.0)
        }
        let tag = tagArray[tagArray.count-1]
        if tag != DataStreamType.ADSB_LOCATION {
            print("ADSB Queue empty")
            return ADSBLocation(address:0,lat:0.0,long:0.0)
        }
        tagArray.removeLast()
        return locQueue.popLast()!
    }
    
    func haveNum(_ num: Int) -> Bool {
        if (tagArray.count > num) {
            return true
        }
        return false
    }
    
    func getCount() -> Int {
        return tagArray.count
    }
}
