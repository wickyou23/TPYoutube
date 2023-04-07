//
//  TPPlayerTime.swift
//  TPYoutube
//
//  Created by Thang Phung on 06/04/2023.
//

import Foundation

struct TPPlayerTime: Equatable {
    let time: Float
    let duration: Float
    
    static var zero: TPPlayerTime {
        TPPlayerTime(time: 0, duration: 0)
    }
}
