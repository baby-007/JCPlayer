//
//  PlayerDelegate.swift
//  Player_iOS
//
//  Created by LJH on 2020/8/21.
//  Copyright © 2020 Patrick Piemonte. All rights reserved.
//

// MARK: - error types

/// Error domain for all Player errors.
public let PlayerErrorDomain = "PlayerErrorDomain"

/// Error types.
public enum PlayerError: Error, CustomStringConvertible {
    case failed

    public var description: String {
        get {
            switch self {
            case .failed:
                return "failed"
            }
        }
    }
}

// MARK: - PlayerDelegate

/// 播放器 protocol
public protocol PlayerDelegate: AnyObject {
    func playerReady(_ player: JCPlayer)
    func playerPlaybackStateDidChange(_ player: JCPlayer)
    func playerBufferingStateDidChange(_ player: JCPlayer)

    // This is the time in seconds that the video has been buffered.
    // If implementing a UIProgressView, user this value / player.maximumDuration to set progress.
    func playerBufferTimeDidChange(_ bufferTime: Double)

    func player(_ player: JCPlayer, didFailWithError error: Error?)
    
    func player(_ player: JCPlayer, didGetDuration: TimeInterval)
}


/// 播放状态过程 protocol
public protocol PlayerPlaybackDelegate: AnyObject {
    func playerCurrentTimeDidChange(_ player: JCPlayer, _ second: TimeInterval)
    func playerPlaybackWillStartFromBeginning(_ player: JCPlayer)
    func playerPlaybackDidEnd(_ player: JCPlayer)
    func playerPlaybackWillLoop(_ player: JCPlayer)
    func playerPlaybackDidLoop(_ player: JCPlayer) -> Bool
}
