//
//  Utils.swift
//  ADSBDecoder
//
//  Created by Jacky Jack on 30/06/2024.
//

import Foundation

//return true if file excists
func checkIfFileExists(_ fname: String) -> Bool {
    let fm = FileManager.default
    if fm.fileExists(atPath: fname) {
        return true
    }
    return false
}

//get current run directory
func getCurrentDirPath() -> String {
    return Process().currentDirectoryPath
}

