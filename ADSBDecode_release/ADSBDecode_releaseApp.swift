//
//  ADSBDecode_releaseApp.swift
//  ADSBDecode_release
//
//  Created by Jacky Jack on 08/08/2024.
//

import SwiftUI
import Collections
import ArgumentParser

struct CommandLineArgs: ParsableCommand {
    @Option(name: .shortAndLong) var hostname: String? = nil
    @Option(name: .shortAndLong) var port: Int? = nil
    @Option(name: .shortAndLong) var inputfile: String? = nil
    @Flag(name: .shortAndLong) var debug:Bool = false
    @Flag(name: .shortAndLong) var version:Bool = false
}

@main
struct ADSBDecode_releaseApp: App {

    var network_mode = false
    var file_mode = false
    @State var queue: Deque<ADSBLocation> = []
    @State var netconfig: NetworkConfigure = NetworkConfigure()
    @State var new_config: Bool = false
    
    //@StateObject private var flightState:FlightState = FlightState()
    //@State var flightState:FlightState = FlightState()
    var flightState:FlightState = FlightState()
    //@Published var list_of_plains:[FlightTracker]?
    //@StateObject var flightState:FlightState = FlightState()
    
    
    var default_hostname = "192.168.4.233"
    var default_port = 30002
    var default_input_file = ""
    
    init() {
        print("Init ")
        if let args = CommandLineArgs.parseNotExit()
        {
            if args.hostname != nil {
                default_hostname = args.hostname!
                network_mode = true
            }
            if args.port != nil {
                default_port = args.port!
                network_mode = true
            }
            
            if args.inputfile != nil {
                default_input_file = args.inputfile!
                file_mode = true
            }
        }
        
        if network_mode {
            netconfig.servername = default_hostname
            netconfig.serverport = default_port
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(net_config: $netconfig).onAppear(perform: {
                if network_mode {
                    print("Network mode")
                    flightState.networkMode(hostname: self.default_hostname, port: self.default_port)
                } else if (file_mode){
                    print("Run file mode")
                    flightState.fileMode(filepath: self.default_input_file)
                } else {
                    print("Run default mode")
                    flightState.defaultMode(hostname: default_hostname, port: default_port)
                }
                 flightState.run()
            })
        }.environmentObject(flightState)
        
        /*WindowGroup("Network", id: "net-config") {
            NetConfigView(net_config: $netconfig)
        }*/
    }
    
}

extension ParsableArguments {
    static func parseNotExit(
        _ arguments: [String]? = nil
      ) -> Self! {
        do {
          return try parse(arguments)
        } catch {
          print("Ignore error")
          return nil
        }
      }
}
