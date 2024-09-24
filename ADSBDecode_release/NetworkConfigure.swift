//
//  File.swift
//  LearnMapKit
//
//  Created by Jacky Jack on 19/07/2024.
//

import Foundation
import SwiftUI

class NetworkConfigure {
    var servername: String = "192.168.4.201"
    var serverport: Int = 30002
    
    var default_values: Bool = true
    
    func setPort(_ port: Int) {
        default_values = false
        self.serverport = port
    }
    
    func setHost(_ hostname: String) {
        default_values = false
        self.servername = hostname
    }
}
