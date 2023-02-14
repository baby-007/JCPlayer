//
//  QueuePlayerDelegate.swift
//  JCMoments
//
//  Created by LJH on 2020/9/7.
//  Copyright © 2020 jingcheng. All rights reserved.
//

/// 播放器 protocol
public protocol QueuePlayerDelegate: AnyObject {
    func playerReady(_ player: QueuePlayer)
    func playerPlaybackStateDidChange(_ player: QueuePlayer)
    func playerBufferingStateDidChange(_ player: QueuePlayer)

    // This is the time in seconds that the video has been buffered.
    // If implementing a UIProgressView, user this value / player.maximumDuration to set progress.
    func playerBufferTimeDidChange(_ bufferTime: Double)

    func player(_ player: QueuePlayer, didFailWithError error: Error?)
    
    func player(_ player: QueuePlayer, didGetDuration: TimeInterval)
}


/// 播放状态过程 protocol
public protocol QueuePlayerPlaybackDelegate: AnyObject {
    func playerCurrentTimeDidChange(_ player: QueuePlayer, _ second: TimeInterval)
    func playerPlaybackWillStartFromBeginning(_ player: QueuePlayer)
    func playerPlaybackDidEnd(_ player: QueuePlayer)
    func playerPlaybackWillLoop(_ player: QueuePlayer)
    func playerPlaybackDidLoop(_ player: QueuePlayer)
}

