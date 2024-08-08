//
//  ADSBRegEx.swift
//  ADSBDecoder
//
//  Created by Jacky Jack on 30/06/2024.
//

import Foundation
import RegexBuilder

let matchADSBLong = Regex {
    Anchor.startOfLine
    "*"
    
        Repeat(
            CharacterClass(
                ("a"..."f"),
                ("0"..."9")
            )
            ,count:28)
    
    ";"
}

let matchADSBShort = Regex {
    Anchor.startOfLine
    "*"
    Repeat(
        CharacterClass(
            ("a"..."f"),
            ("0"..."9")
        )
        ,count:14)
    ";"
}
