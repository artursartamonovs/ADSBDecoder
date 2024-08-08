//
//  NetConfigView.swift
//  LearnMapKit
//
//  Created by Jacky Jack on 19/07/2024.
//

import SwiftUI

struct NetConfigView: View {
    @State private var server_name: String = ""
    @State private var server_port: String = ""
    @Environment(\.dismissWindow) private var dismissWindow
    
    @Binding var net_config: NetworkConfigure
    
    var body: some View {
        VStack {
            HStack {
                    Text("Server")
                    TextField("Server", text: $server_name)
            }
            HStack {
                    Text("Port")
                    TextField("Port", text: $server_port)
            }
            HStack {
                    Button(action:{
                        print("Cancel")
                        dismissWindow(id:"net-config")
                    }) {
                        Text("Cancel")
                    }
                    Button(action: {
                        print("Save config")
                        net_config.servername = server_name
                        // is there better way?
                        net_config.serverport = Int(server_port)!
                        dismissWindow(id:"net-config")
                    }) {
                        Text("Save")
                    }
            }
        }
    }
}

//#Preview {
    //NetConfigView(net_config: net_config)
//}
