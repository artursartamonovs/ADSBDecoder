//
//  AirplaneTracker.swift
//  ADSBDecoder
//
//  Created by Jacky Jack on 20/06/2024.
//

import Foundation

struct Airplane {
    var addressReady:Bool = false
    var Address:Int
    var ICAOready:Bool = false
    var ICAOname:String = ""
    var locationReady:Bool = false
    var lat:Double = 0.0
    var long:Double = 0.0
    var altitudeReady:Bool = false
    var altitude:Int = 0
    var altitudeCount:Int = 0
    var positionDecoder:PositionDecoder = PositionDecoder()
}

class AirPlaneTracker {
    
    var airplanes:[Int:Airplane] = [:]
    
    init () {
        
    }
    
    func addDF17Indentification(_ address: Int, _ ICAOname: String) {
        if (airplanes[address] == nil) {
            airplanes[address] = Airplane(addressReady: true, Address: address,ICAOready: true, ICAOname: ICAOname)
            
        } else {
            if (airplanes[address]?.ICAOname == "") {
                airplanes[address]?.ICAOname = ICAOname
                airplanes[address]?.ICAOready = true
            }
        }
    }
    
    func addDF17AirBornPosition(_ address: Int, _ cpr_lat: Int, _ cpr_long: Int, _ alt: Int, _ even: Bool) {
        
        if airplanes[address] == nil {
            return
        }
        
        //deal with altitude
        //if airplanes[address] != nil {
            if (airplanes[address]?.altitudeReady != true) {
                airplanes[address]?.altitudeReady = true
                airplanes[address]?.altitude = alt
                airplanes[address]?.altitudeCount += 1
            } else {
                airplanes[address]?.altitude = alt
                airplanes[address]?.altitudeCount += 1
            }
        //}
        //do the airborn position
        if (even) {
            airplanes[address]?.positionDecoder.addEvenPosition(UInt32(cpr_lat), UInt32(cpr_long), mstime())
        } else {
            
            airplanes[address]?.positionDecoder.addOddPosition(UInt32(cpr_lat), UInt32(cpr_long), mstime())
        }
        
    }
    
    func getPosition(_ address: Int) -> (Double,Double)? {
        if (airplanes[address] == nil) {
            return nil
        }
        
        if let airplane = airplanes[address] {
            if (airplane.positionDecoder.calcPosition()) {
                return airplane.positionDecoder.getPosition()
            }
        }
        
        return nil
    }
    
    func getAltitude(_ address: Int) -> Int? {
        if (airplanes[address] == nil) {
            return nil
        }
        if let airplane = airplanes[address] {
            if airplane.altitudeReady {
                return airplane.altitude
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func getICAOname(_ address: Int) -> String? {
        if (airplanes[address] == nil) {
            return nil
        }
        if let airplane = airplanes[address] {
            if airplane.ICAOready {
                return airplane.ICAOname
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func printAllICAOnames() {
        let extra = true
        var once=false
        for (address,plane) in airplanes {
            if plane.ICAOready {
                print(String("\(plane.ICAOname) "), terminator: "")
            }
            if (extra) {
                print("Alitude \(plane.altitudeCount) Positions \(plane.positionDecoder.queue.count)")
            }
            //if (!once) {
            //    for i in plane.positionDecoder.queue {
            //        print("\(i.cpr_lat) \(i.cpr_long) \(i.even)")
            //    }
            //    once = true
            //}
        }
    }
    
}
