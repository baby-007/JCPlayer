//
//  ArrayPlayer.swift
//  JCMoments
//
//  Created by LJH on 2020/9/15.
//  Copyright © 2020 jingcheng. All rights reserved.
//

import UIKit

//MARK: - 播放相关的协议
protocol PlayerDataSource: AnyObject {
    var playAbleArray: [PlayAbleModel] {get}
}
protocol PlayAbleModel: AnyObject {
    var mediaURL: String { get }
    func mediaID() -> String
}
//MARK: - 预加载下一个视频
class ArrayPlayer {
    weak var dataSource: PlayerDataSource?
    var players = [JCPlayer]()
    var playerIndexs = [Int]()
    var nextNum: Int = 0
    //ui key
    let playUI: String
    //最大数量
    var maxCount: Int = 3
    var startIndex: Int = 0
    
    init(uiKey: String) {
        playUI = uiKey
    }
    ///removeSource : 移除数据源
    ///notUsed : 是否只移除未使用的
    func clear(removeSource: Bool = true, notUsed: Bool = false) {
        if removeSource {
            dataSource = nil
        }
        if !notUsed {
            for p in players {
                p.playerDelegate = nil
                p.playbackDelegate = nil
                if p.playbackState != .stopped {
                    p.stop()
                }
            }
            players.removeAll()
            playerIndexs.removeAll()
        } else if playerIndexs.count > 0 {
            var leaveI: Int?
            var leaveP: JCPlayer?
            for i in 0..<playerIndexs.count {
                if playerIndexs[i] != startIndex {
                    players[i].playerDelegate = nil
                    players[i].playbackDelegate = nil
                    if players[i].playbackState != .stopped {
                        players[i].stop()
                    }
                } else {
                    leaveI = playerIndexs[i]
                    leaveP = players[i]
                }
            }
            if let _leaveI = leaveI, let _leaveP = leaveP {
                playerIndexs = [_leaveI]
                players = [_leaveP]
            } else {
                players.removeAll()
                playerIndexs.removeAll()
            }
        }
    }
    ///关闭其他播放器
    func deferDo(JCPlayer: JCPlayer?, start: Bool = true) {
        guard start, players.count > 0 else {
            return
        }
        for i in 0..<players.count {
            if players[i] != JCPlayer, players[i].playbackState == .playing {
                players[i].playerDelegate = nil
                players[i].playbackDelegate = nil
                players[i].pause()
            }
        }
    }
    
    ///判断是向后加载还是向前
    func resetNextNum(index: Int) {
        nextNum = 0
        for i in playerIndexs {
            if index >= i {
                nextNum += 1
            } else {
                nextNum -= 1
            }
        }
    }
    ///预加载下一个视频
    func loadNext(index: Int, next: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: { [weak self] in
            guard let weakSelf = self else {return }
            //预加载下一个视频
            weakSelf.insertPlayer(index + (next ? 1 : -1), addNext: false, start: false)
        })
    }
    //MARK: - 根据索引获取播放器
    @discardableResult func insertPlayer(_ index: Int, addNext: Bool = true, start: Bool = true) -> JCPlayer? {
        guard let _dataSource = dataSource, index >= 0, index < _dataSource.playAbleArray.count, _dataSource.playAbleArray[index].mediaURL.count > 0 else {
            deferDo(JCPlayer: nil, start: start)
            return nil
        }
        if start {
            startIndex = index
            NSLog("开始\(index)")
        }
        let result: JCPlayer
        let _url = _dataSource.playAbleArray[index].mediaURL
        if let _player = players.first(where: {$0.stringUrl == _url}) {
            result = _player
            resetNextNum(index: index)
            NSLog("已存在\(index)")
            //最大或最小索引
            if addNext {
                if nextNum == playerIndexs.count {
                    //index最大
                    loadNext(index: index, next: true)
                } else if nextNum + playerIndexs.count == 2 {
                    // 1 - (count - 1) + count == 2
                    //index最小
                    loadNext(index: index, next: false)
                }
            }
        } else {
            result = JCPlayer(url: _url)
            result.playUI = playUI
            result.setupPlayer()
            NSLog("加载\(index)")
            if players.count >= maxCount {
                //移除离startIndex“最远”的player
                var removeIndex: Int = 0
                var maxDistance: Int = abs(playerIndexs[removeIndex] - startIndex)
                var temp: Int = 0
                for i in 1..<playerIndexs.count {
                    temp = abs(playerIndexs[i] - startIndex)
                    if maxDistance < temp {
                        maxDistance = temp
                        removeIndex = i
                    }
                }
                
                players[removeIndex].playerDelegate = nil
                players[removeIndex].playbackDelegate = nil
                players[removeIndex].stop()
                NSLog("移除\(playerIndexs[removeIndex])")
                players.remove(at: removeIndex)
                playerIndexs.remove(at: removeIndex)
            }
            
            players.append(result)
            playerIndexs.append(index)
            resetNextNum(index: index)
            if addNext  {
                loadNext(index: index, next: nextNum >= 0)
            }
        }
        
        deferDo(JCPlayer: result, start: start)
        return result
    }
    
    
}
