//
//  PlayType.swift
//  JCMoments
//
//  Created by LJH on 2020/7/7.
//  Copyright © 2020 jingcheng. All rights reserved.
//

import Foundation
//MARK: 播放媒体类型
struct PlayType: OptionSet {
    let rawValue: UInt
    static let video = PlayType(rawValue: 1)
//    static let audio = PlayType(rawValue: 1 << 1)
    
    ///添加新类型 (或)
    mutating func add(type: PlayType) {
        self = PlayType(rawValue: self.rawValue | type.rawValue)
    }
    ///包含某个类型
    func contains(type: PlayType) -> Bool {
        return (self.rawValue & type.rawValue) != 0
    }
}
