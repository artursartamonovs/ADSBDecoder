//
//  ADSBDecode_releaseApp.swift
//  ADSBDecode_release
//
//  Created by Jacky Jack on 08/08/2024.
//

import SwiftUI
import Collections
import ArgumentParser

@main
struct ADSBDecode_releaseApp: App {

    @State var queue: Deque<ADSBLocation> = []
    @State var netconfig: NetworkConfigure = NetworkConfigure()
    
    @StateObject private var flightState = FlightState()
    
    init() {
        
        print("Init app")
        let ADSBClient = NetADSBDecoder(host: "192.168.4.201", port: 30002)
        /*do {
            try ADSBClient.start()
        } catch let error {
            print("Error: \(error.localizedDescription)")
            ADSBClient.stop()
        }*/
        DispatchQueue.global(qos: .background).async {
            do {
                try ADSBClient.start()
            } catch let error {
                print("Error: \(error.localizedDescription)")
                ADSBClient.stop()
            }
         }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(pos_queue: $queue, net_config: $netconfig)
        }.environmentObject(flightState)
        
        WindowGroup("Network", id: "net-config") {
            NetConfigView(net_config: $netconfig)
        }
    }
    
}
