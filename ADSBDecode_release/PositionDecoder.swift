//
//  PositionDecoder.swift
//  ADSBDecoder
//
//  Created by Jacky Jack on 14/06/2024.
//

import Foundation
import Collections

struct PositionData {
    var cpr_lat: UInt32
    var cpr_long: UInt32
    var even: Bool
    var cprtime: Int64
}

func cpr_mod(_ a: Int, _ b: Int) -> Int {
    var res:Int = a % b;
    if (res < 0) {
        res += b
    }
    return res;
}

/* The NL function uses the precomputed table from 1090-WP-9-14 */
func cpr_NLFunction(_ _lat: Double) -> Int {
    var lat:Double = _lat
    if (lat < 0) {
        lat = -lat
    } /* Table is simmetric about the equator. */
    if (lat < 10.47047130) {return 59}
    if (lat < 14.82817437) {return 58}
    if (lat < 18.18626357) {return 57}
    if (lat < 21.02939493) {return 56}
    if (lat < 23.54504487) {return 55}
    if (lat < 25.82924707) {return 54}
    if (lat < 27.93898710) {return 53}
    if (lat < 29.91135686) {return 52}
    if (lat < 31.77209708) {return 51}
    if (lat < 33.53993436) {return 50}
    if (lat < 35.22899598) {return 49}
    if (lat < 36.85025108) {return 48}
    if (lat < 38.41241892) {return 47}
    if (lat < 39.92256684) {return 46}
    if (lat < 41.38651832) {return 45}
    if (lat < 42.80914012) {return 44}
    if (lat < 44.19454951) {return 43}
    if (lat < 45.54626723) {return 42}
    if (lat < 46.86733252) {return 41}
    if (lat < 48.16039128) {return 40}
    if (lat < 49.42776439) {return 39}
    if (lat < 50.67150166) {return 38}
    if (lat < 51.89342469) {return 37}
    if (lat < 53.09516153) {return 36}
    if (lat < 54.27817472) {return 35}
    if (lat < 55.44378444) {return 34}
    if (lat < 56.59318756) {return 33}
    if (lat < 57.72747354) {return 32}
    if (lat < 58.84763776) {return 31}
    if (lat < 59.95459277) {return 30}
    if (lat < 61.04917774) {return 29}
    if (lat < 62.13216659) {return 28}
    if (lat < 63.20427479) {return 27}
    if (lat < 64.26616523) {return 26}
    if (lat < 65.31845310) {return 25}
    if (lat < 66.36171008) {return 24}
    if (lat < 67.39646774) {return 23}
    if (lat < 68.42322022) {return 22}
    if (lat < 69.44242631) {return 21}
    if (lat < 70.45451075) {return 20}
    if (lat < 71.45986473) {return 19}
    if (lat < 72.45884545) {return 18}
    if (lat < 73.45177442) {return 17}
    if (lat < 74.43893416) {return 16}
    if (lat < 75.42056257) {return 15}
    if (lat < 76.39684391) {return 14}
    if (lat < 77.36789461) {return 13}
    if (lat < 78.33374083) {return 12}
    if (lat < 79.29428225) {return 11}
    if (lat < 80.24923213) {return 10}
    if (lat < 81.19801349) {return 9}
    if (lat < 82.13956981) {return 8}
    if (lat < 83.07199445) {return 7}
    if (lat < 83.99173563) {return 6}
    if (lat < 84.89166191) {return 5}
    if (lat < 85.75541621) {return 4}
    if (lat < 86.53536998) {return 3}
    if (lat < 87.00000000) {return 2}
    else {return 1}
}

func cpr_NFunction(_ lat: Double, _ isodd: Int) -> Int {
    var nl:Int = cpr_NLFunction(lat) - isodd;
    if (nl < 1) {
        nl = 1
    }
    return nl;
}

func cpr_DlonFunction(_ lat: Double, _ isodd: Int) -> Double {
    return 360.0 / Double(cpr_NFunction(lat, isodd));
}

func mstime() -> Int64 {
    var tv:timeval = timeval(tv_sec: 0, tv_usec: 0)
    var mst:Int64=0;

    gettimeofday(&tv, nil);
    mst = Int64(tv.tv_sec)*1000;
    mst += Int64(tv.tv_usec)/1000;
    return mst;
}

class PositionDecoder {
    
    var long: Double = 0.0
    var lat: Double = 0.0
    var ready: Bool = false
    var newposition: Bool = false
    
    //initialise first values so this values is nonsence
    var queue: Deque<PositionData> = []
    
    init() {
        
    }
    
    func addEvenPosition(_ cpr_lat: UInt32,_ cpr_long: UInt32, _ cprtime: Int64) {
        queue.append(PositionData(cpr_lat:cpr_lat, cpr_long:cpr_long, even:true, cprtime: cprtime))
    }
    
    func addOddPosition(_ cpr_lat: UInt32,_ cpr_long: UInt32, _ cprtime: Int64) {
        queue.append(PositionData(cpr_lat:cpr_lat,cpr_long:cpr_long,even:false, cprtime: cprtime))
    }
    
    func getPosition() -> (Double, Double)? {
        if (ready) {
            return (lat, long)
        }
        return nil
    }
    
    //TODO: allways adds to queue newer frees the queue
    func calcPosition() -> Bool {
        if (queue.count > 2) {
            let el1 = queue[queue.count-1]
            let el2 = queue[queue.count-2]
            if (el1.even == el2.even) {
                //ready = false
                return false
            }
        } else {
            ready = false
            print("Position queue to short to calculate values")
            return false
        }
        
        //last to elements are evan and odd
        let el1 = queue[queue.count-1]
        let el2 = queue[queue.count-2]
        let cpr_even = el1.even ? el1 : el2
        let cpr_odd  = (!el1.even) ? el1 : el2
        
        //print("Position queue is ready to calculate location \(cpr_even) \(cpr_odd)")
        // from here https://github.com/antirez/dump1090/blob/master/dump1090.c#L1718
        let AirDlat0:Double = 360.0/60.0
        let AirDlat1:Double = 360.0/59.0
        
        let lat0 = Int(cpr_even.cpr_lat)
        let lat1 = Int(cpr_odd.cpr_lat)
        let lon0 = Int(cpr_even.cpr_long)
        let lon1 = Int(cpr_odd.cpr_long)
        
        //latitude index
        let j:Int = Int(floor(((59.0*Double(lat0) - 60.0*Double(lat1)) / 131072.0) + 0.5))
        
        var rlat0:Double = AirDlat0 * (Double(cpr_mod(j,60)) + Double(lat0) / 131072.0)
        var rlat1:Double = AirDlat1 * (Double(cpr_mod(j,59)) + Double(lat1) / 131072.0)
        
        if (rlat0 >= 270.0) {
            rlat0 -= 360.0
        }
        if (rlat1 >= 270.0) {
            rlat1 -= 360.0
        }
        
        /* Check that both are in the same latitude zone, or abort. */
        if (cpr_NLFunction(rlat0) != cpr_NLFunction(rlat1)) {
            print("Not same lat?!")
            return false
        }
        
        /* Compute ni and the longitude index m */
        if (cpr_even.cprtime > cpr_odd.cprtime) {
                /* Use even packet. */
                let ni:Int = cpr_NFunction(rlat0,0);
                let m:Int = Int(
                    floor((((Double(lon0) * (Double(cpr_NLFunction(rlat0))-1.0)) -
                                    (Double(lon1) * Double(cpr_NLFunction(rlat0)))) / 131072.0) + 0.5)
                );
                self.long = Double(cpr_DlonFunction(rlat0,0)) * (Double(cpr_mod(m,ni))+Double(lon0)/131072.0);
                self.lat = rlat0;
            } else {
                /* Use odd packet. */
                let ni:Int = cpr_NFunction(rlat1,1);
                let m:Int = Int(floor((((Double(lon0) * (Double(cpr_NLFunction(rlat1))-1.0)) -
                                (Double(lon1) * Double(cpr_NLFunction(rlat1)))) / 131072.0) + 0.5));
                self.long = cpr_DlonFunction(rlat1,1) * (Double(cpr_mod(m,ni))+Double(lon1)/131072.0);
                self.lat = rlat1;
            }
        if (self.long > 180) {
            self.long -= 360
        }
        
        ready = true
        return true
    }
    
    
}
