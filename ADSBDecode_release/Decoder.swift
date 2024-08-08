//
//  Decoder.swift
//  ADSBDecoder
//
//  Created by Jacky Jack on 28/05/2024.
//

import Foundation

func BarometricAltitudeFeat(_ altitude: UInt16) -> Int {
    let QBit = (altitude>>4)&0x1
    if QBit == 1 {
        //remove qbit
        let part1:UInt16 = altitude&0xf
        let part2:UInt16 = (altitude>>1)&0x7ff0
        let altitude25 = part1 + part2
        //print("altitude2 \(altitude25) ")
        return Int(altitude25)*25-1000
    }
    return Int(altitude)*100-1000
}

class Decoder {
    var adsb_data: String = ""
    var DataFormat: UInt32 = 0;
    
    init (_ adsb_data: String) {
        //print(adsb_data)
        self.adsb_data = adsb_data
        //get the first 8 bits as integer
        let startI =  adsb_data.startIndex
        let endI = adsb_data.index(startI, offsetBy: 1)
        let firstByteString = adsb_data[startI...endI]
        //print("\(firstByteString)")
        if let ControlMsg = UInt32(firstByteString, radix: 16) {
            //print("ControlMsg = \(ControlMsg)")
            let CM_DataFormat = (ControlMsg&0xF8)>>3
            DataFormat = CM_DataFormat
            //let CM_TranspoderCapability = ControlMsg&(0x7)
        }
        //print("Data Format \(DataFormat)")
    }
    
    func getDataFormat17() -> DataFormat17? {
        
        if (DataFormat != 17) {
            return nil
        }
        //let startI =  adsb_data.index(adsb_data.startIndex, offsetBy: 1)
        //let endI = adsb_data.index(adsb_data.endIndex, offsetBy: -1)
        //let adsbData = adsb_data[startI...endI]
        let ret:DataFormat17 = DataFormat17(adsb_data)
        
        
        
        return ret;
    }
    
    func getDataFormat18() {
        print("Not implemented")
    }
    
}

func ICAOAlphabet(_ code: UInt8) -> String {
    if ((code>=1) && (code<=26)) {
        return String(UnicodeScalar(code+64))
    } else if ((code >= 48)&&(code<=57)) {
        return String(UnicodeScalar(code))
    } else if (code==32) {
        return " "
    }
    return "#"
}

func ICAO2String(_ b1: UInt8, _ b2: UInt8, _ b3: UInt8, _ b4: UInt8, _ b5: UInt8, _ b6: UInt8, _ b7: UInt8, _ b8: UInt8) -> String {
    return ICAOAlphabet(b1)+ICAOAlphabet(b2)+ICAOAlphabet(b3)+ICAOAlphabet(b4)+ICAOAlphabet(b5)+ICAOAlphabet(b6)+ICAOAlphabet(b7)+ICAOAlphabet(b8)
}

class DataFormat17 {
    
    let DataFormat=17 //0:5
    var Capability=0  //5:7
    var AddressAnnounced=0 //8:31
    var TypeCode=0 //32:36
    var MovementField=0//37:43
    var HeadingBit=0//44
    var HeadingField=0//45:51
    //var CPROddEven=0//53
    //var CPRlat=0//54:70
    //var CPRlon=0//71:87
    var ParityIntegrity=0//88-111
    
    //all avaliable message types
    var messageIdentification:ADSBTypeCodeIndentification? = nil
    var messageAirbornPositon:ADSBTypeCodeAirbonePositon? = nil
    
    init(_ adsb_data: String) {
        //print("Dataformat: 17!")
        //print(adsb_data)
        
        var bindata:[UInt8] = []
        
        var startN = adsb_data.startIndex
        var endN = adsb_data.index(startN, offsetBy: 1)
        var count=0//start index value
        while (count<adsb_data.count) {
            let u8 = UInt8(adsb_data[startN...endN], radix: 16)!
            //print(adsb_data[startN...endN])
            bindata.append(u8)
            count += 2
            if (count<adsb_data.count) {
                startN = adsb_data.index(startN, offsetBy: 2)
                endN = adsb_data.index(startN, offsetBy: 1)
            }
        }
        //print(bindata)
        
        //Decode Capability
        let cap = (bindata[0]>>1)&0x7
        //print(String(format: "cap %02x", cap))
        Capability = Int(cap)
        
        //Decode Address Announcement
        let address_ann = UInt32(bindata[1])<<16 + UInt32(bindata[2])<<8 + UInt32(bindata[3])
        //print(String(format: "address %06x", address_ann))
        
        AddressAnnounced = Int(address_ann)
        
        //Decode Type Code
        let tc_byte = bindata[4] >> 3
        //print(String(format: "tc %02d", tc_byte))
        
        TypeCode = Int(tc_byte)
        
        //aircraft indentification and category
        if (tc_byte == 4) {
            let msg = ADSBTypeCodeIndentification(bindata[4...10])
            if decoder_debug_mode {
                print("=====ADSB MESSSGE 04 =======")
                print(msg)
                print("============================")
            }
            
            messageIdentification = msg
        //airborn position
        } else if ((tc_byte >= 8) && (tc_byte <= 18)) {
            let msg = ADSBTypeCodeAirbonePositon(bindata[4...10])
            if decoder_debug_mode {
                print(String(format:"=====ADSB MESSSGE %02d ======= AA:%04d", tc_byte, AddressAnnounced))
                print(msg)
                print("============================")
            }
            
            messageAirbornPositon = msg
        //airborn velocity
        } else if (tc_byte == 19) {
            if decoder_debug_mode {
                print("=====ADSB MESSSGE 19 =======")
                print("=====VELOCITY =======")
            }
        } else {
            if decoder_debug_mode {
                print("=====ADSB MESSSGE UNKNOWN =======")
            }
        }
    }
}

class ADSBTypeCodeIndentification: CustomStringConvertible {
    var TypeCode:Int = 4
    var Category:Int = 0
    var ICAOName:String
    
    init(_ bindata:ArraySlice<UInt8>) {
        let cat = bindata[4]&0x7
        Category = Int(cat)
        let char_0 = bindata[5]>>2
        let char_1 = (bindata[5]&0x3)<<4 + bindata[6]>>4
        let char_2 = (bindata[6]&0xf)<<2 + (bindata[7]>>6)&0x3
        let char_3 = (bindata[7])&0x3f
        let char_4 = bindata[8]>>2
        let char_5 = (bindata[8]&0x3)<<4 + bindata[9]>>4
        let char_6 = (bindata[9]&0xf)<<2 + (bindata[10]>>6)
        let char_7 = bindata[10]&0x3f
        
        //print(char_0, char_1, char_2,char_3,char_4,char_5,char_6,char_7)
        ICAOName = ICAO2String(char_0, char_1, char_2, char_3, char_4, char_5, char_6, char_7)
        //print("ICAO name \(ICAOName)")
    }
    
    var description: String {
        let description = "TypeCode \(TypeCode) Cat \(Category) Flight name \(ICAOName)"
        return description
    }
}

//DF17 message types codes  8 to 18
class ADSBTypeCodeAirbonePositon:CustomStringConvertible {
    var TypeCode:Int = 11
    var SurveillanceStatus: Int = 0
    var SingleAntennaFlag: Int = 0
    var Altitude: Int = 0
    var Time: Int = 0
    var CPRFormat: Int = 0
    var Latitude: Int = 0
    var Longitude: Int = 0
    
    init(_ bindata:ArraySlice<UInt8>) {
        let ss = (bindata[4]>>1)&(0x3)
        SurveillanceStatus = Int(ss)
        let saf = bindata[5]&0x1
        SingleAntennaFlag = Int(saf)
        let altitude = UInt16(bindata[5])<<4 + (UInt16(bindata[6])>>4)&0xf
        //print(altitude)
        Altitude = BarometricAltitudeFeat(altitude)
        let time = (bindata[6]>>3)&0x1
        Time = Int(time)
        let cpr = (bindata[6]>>2)&0x1
        CPRFormat = Int(cpr)
        let lat:UInt32 = UInt32(bindata[6]&0x3)<<15 + UInt32(bindata[7])<<7 + UInt32(bindata[8]>>1)
        Latitude = Int(lat)
        let lon:UInt32 = UInt32(bindata[8]&0x1)<<16 + UInt32(bindata[9])<<8 + UInt32(bindata[10])
        Longitude = Int(lon)
    }
    
    var description: String {
        var description = "SS \(SurveillanceStatus) SAF \(SingleAntennaFlag) Altitude \(Altitude)ft \n"
        description += "Time \(Time) CPR \(CPRFormat)"
        if (CPRFormat == 0) {
            description += "even"
        } else {
            description += "odd"
        }
        description += "\n"
        description += "Lat \(Latitude) Long \(Longitude)"
        return description
    }
}

class DataFormat19:CustomStringConvertible  {
    init(_ bindata:ArraySlice<UInt8>) {
        print("Dataformat: 19")
    }
    
    var description: String {
        return ""
    }
}
