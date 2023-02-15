//
//  GlobalArrayPlayer.swift
//  JCMoments
//
//  Created by LJH on 2020/9/15.
//  Copyright © 2020 jingcheng. All rights reserved.
//


import Foundation
import UIKit

struct GlobalVideoParameter {
    ///是否铺满
    var fillScreen: Bool = false
    ///强制播放
    var forcePlay: Bool?
    ///将暂停状态视为播放状态（用于点击时若暂停则停止播放）
    var pauseAsPlay: Bool?
    ///静音
    var mute: Bool = false
    ///进度条颜色
    var progressColor: UIColor?
    var progressBackColor: UIColor?
    //隐藏加载动画
    var hiddenLoading = false
    ///循环播放
    var repeatPlay: Bool = true
    var showFrame: CGRect?
    var progressFrame: CGRect?
    var progresInGivenView = true
    var fromLast = true
    ///播放视图的图层关系
    weak var belowView: UIView?
//    weak var contentView: (UIView & AVURLPlayerControlDelegate)?
}

class GlobalArrayPlayer {
    ///通用视频播放管理单例
    static let shared = GlobalArrayPlayer()
    
    lazy var arrayPlayer: ArrayPlayer = {
       let temp = ArrayPlayer(uiKey: playUI)
        return temp
    }()
    
    ///断点续播 不停止当前的播放器 而是转移播放界面
    var continuePlay = false
    var currentID: String?
    
    var playUI: String = "PlaySelectVideoController"
    
    ///静音
    var mute: Bool = false
    var canPlay: Bool = true
    var isPlayStatus: ((Bool) -> Void)?
    
    var isLoadStatus: ((Bool) -> Void)?
    
    var loadDuration: ((TimeInterval) -> Void)?
    var showStop = false
    var tryPlayNext: (() -> Bool)?
    
    weak var videoModel: PlayAbleModel?
//    var start: (() -> Void)?
    ///视频播放器
    var player: JCPlayer? {
        didSet {
            let dur = player?.duration ?? 0
            if dur > 0 {
                duration = dur
                loadDuration?(duration)
            }
        }
    }
    let defaultParameter = GlobalVideoParameter()
    var progressView: UIView?
    
//    lazy var videoContentView: GlobalPlayerContent = {
//        let temp = GlobalPlayerContent()
//        temp.playTimeChanged = { [weak self](progress) in
//            if let weakSelf = self {
//                weakSelf.progressView.set(progress: progress)
//            }
//        }
//        temp.playStatusChanged = { [weak self](isPlay) in
//            self?.isPlayStatus?(isPlay)
//        }
//        temp.addSubview(progressView)
//        return temp
//    }()
    
//    var playIcon: UIImageView?
    
    var duration: TimeInterval = 15
    var isLoading = false {
        didSet {
            
        }
    }
    
    init() {
//        NotificationCenter.default.addObserver(self, selector: #selector(resignActive(_:)), name: NSNotification.Name(rawValue: JCMomentConnector.pauseJCNotification), object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func resignActive(_ notification: Notification) {
        if let info = notification.userInfo, let play = info["play"] as? Bool, play {
            startPlay()
        } else {
            pausePlay()
        }
    }
    func start() {
        isLoading = true
    }
    
    func finished() {
        isPlayStatus?(true)
        isLoading = false
    }
    func player(index: Int) -> JCPlayer? {
        return arrayPlayer.insertPlayer(index)
    }
    func playIn(view: UIView, avPlayer: JCPlayer?, frame: CGRect, model: PlayAbleModel?, parameter: GlobalVideoParameter? = nil) {
        guard let _player = avPlayer else {
            pausePlay()
            self.videoModel = model
            return
        }
        _player.playerDelegate = self
        _player.playbackDelegate = self
        self.player?.playerDelegate = self
        self.player?.playbackDelegate = self
        _player.playUI = playUI
        self.player?.playUI = playUI
        defer {
            continuePlay = false
            self.player?.playerDelegate = self
            self.player?.playbackDelegate = self
            isLoading = player?.bufferingState != .ready
        }
        let sameUrl = self.player?.stringUrl == _player.stringUrl
        let sameView = self.player?.playerView.superview == view
        if sameUrl, sameView {
            if player?.playbackState != .playing, canPlay {
                //isLoading = player?.bufferingState != .ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: {
                    if self.player?.playbackState != .playing, self.canPlay {
                        self.player?.replay()
                    }
                })
            } else if !canPlay {
                self.pausePlay()
            }
            self.videoModel = model
            return
        } else if continuePlay, sameUrl, !sameView {
            continuePlay(view: view, frame: frame, parameter: parameter ?? defaultParameter)
            self.videoModel = model
            return
        }
        
        if self.player != nil {
            stopPlay()
        }
        self.videoModel = model
        let para = parameter ?? defaultParameter
        preparePlay(view: view, avPlayer: _player, frame: frame, parameter: para)
        paly(fromLast: para.fromLast)
    }
    
    func paly(fromLast: Bool = true) {
//        if let content = player?.controlView as? VideoContentView {
//            content.start()
//        } else if let content = player?.controlView as? GlobalPlayerContent {
//            content.start()
//        }
        if canPlay {
            start()
            player?.playFromLastTime(fromLast: fromLast)
            NSLog("canPlay start")
        }
    }
    
    func rePlay() {
        if canPlay {
            player?.replay()
        }
    }
    func preparePlay(view: UIView, avPlayer: JCPlayer, frame: CGRect, parameter: GlobalVideoParameter) {
        avPlayer.muted = parameter.mute || mute
        avPlayer.playbackLoops = parameter.repeatPlay
        avPlayer.playerView.frame = frame
        if parameter.fillScreen {
            avPlayer.fillMode = .resizeAspectFill
        }
        player = avPlayer
//        let showRect = parameter.showFrame ?? frame
        
        if let below = parameter.belowView {
            view.insertSubview(player!.playerView, belowSubview: below)
        } else {
            view.addSubview(player!.playerView)
        }
        if parameter.progresInGivenView {
            
        }
    }
    //MARK: - 断点续播
    func continuePlay(view: UIView, frame: CGRect, parameter: GlobalVideoParameter) {
        guard let _player = player else {
            return
        }
//        if let content = parameter.contentView {
            //时间转移
            //修改JCAV
//            content.player?(_player, didGetDuration: videoContentView.duration)
//            _player.controlView = content
//        }
        
//        player(_player, didGetDuration: duration)
        
        _player.playerView.removeFromSuperview()
        if let below = parameter.belowView {
            view.insertSubview(_player.playerView, belowSubview: below)
        } else {
            view.addSubview(_player.playerView)
        }
        if parameter.progresInGivenView {

            
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            _player.playerView.frame = frame
        }) { (end) in
            _player.playerView.reframePlayerView()
        }
        
        NSLog("continuePlay")
    }
    func resetFrameIfNeed(_ frame: CGRect) {
        if continuePlay {
            player?.playerView.frame = frame
        }
    }
    func reframe(view: UIView, frame: CGRect, parameter: GlobalVideoParameter) {
        guard let _playerView = player?.playerView, _playerView.superview == view else {
            return
        }
        _playerView.frame = frame
        if parameter.progresInGivenView {
            
        }
    }
    func stopPlay() {
        NSLog("stopPlay0")
        guard !continuePlay else { return }
//        videoContentView.finished()
        finished()
        player?.playerDelegate = nil
        player?.playbackDelegate = nil
        //player?.stop()
        player?.pause()
        player?.playerView.removeFromSuperview()
//        player?.controlView = nil
        player = nil
        NSLog("stopPlay")
    }
    ///sendData 是否发送统计数据
    ///notUsed true:只清除当前没有用的播放器，false:清除全部播放器
    func clear(notUsed: Bool = false) {
        stopPlay()
        arrayPlayer.clear(notUsed: notUsed)
    }
    
    func removePlayer(from: UIView) {
        guard !continuePlay, let superView = player?.playerView.superview, superView == from   else { return }
//        player?.playerView.removeFromSuperview()
//        progressView.removeFromSuperview()
//        playIcon.removeFromSuperview()
        stopPlay()
    }
    
    func stopPlayer(ifNotIn view: UIView) {
        guard !continuePlay, let superView = player?.playerView.superview, superView != view   else { return }
        stopPlay()
    }
    
    func pausePlay(showStop: Bool = false) {
        if !continuePlay {
            self.showStop = showStop
            player?.pause()
        }
    }
    func startPlay() {
        canPlay = true
        if player?.playbackState != .playing {
            self.player?.replay()
        }
    }
    func isPuase() -> Bool {
        //修改JCAV
        return  player?.playbackState == .paused
    }
    func isPlaying() -> Bool {
        return  player?.playbackState == .playing
    }
    func isMute() -> Bool {
        return mute
    }
    func mutePlay(_ mute: Bool) {
        self.mute = mute
        player?.muted = mute
    }
}

extension GlobalArrayPlayer: PlayerDelegate {
    func playerReady(_ player: JCPlayer) {}
    func playerPlaybackStateDidChange(_ player: JCPlayer) {
        if showStop && player.playbackState == .paused {
            showStop = false
            isPlayStatus?(false)
        } else if player.playbackState != .paused {
            showStop = false
            isPlayStatus?(true)
        }
//        isPlayStatus?(player.playbackState != .paused)
    }
    func playerBufferingStateDidChange(_ player: JCPlayer) {
        isLoading = player.bufferingState != .ready
        isLoadStatus?(player.bufferingState != .ready)
    }

    // This is the time in seconds that the video has been buffered.
    // If implementing a UIProgressView, user this value / player.maximumDuration to set progress.
    func playerBufferTimeDidChange(_ bufferTime: Double) {}

    func player(_ player: JCPlayer, didFailWithError error: Error?) {
        if let reason = error?.localizedDescription, reason.count > 0 {
            
        }
    }
    
    func player(_ player: JCPlayer, didGetDuration: TimeInterval) {
        duration = didGetDuration
        loadDuration?(didGetDuration)
        
    }
}

extension GlobalArrayPlayer: PlayerPlaybackDelegate {
    func playerCurrentTimeDidChange(_ player: JCPlayer, _ second: TimeInterval) {
    }
    func playerPlaybackWillStartFromBeginning(_ player: JCPlayer) {
        isLoading = player.bufferingState != .ready
    }
    func playerPlaybackDidEnd(_ player: JCPlayer) {}
    func playerPlaybackWillLoop(_ player: JCPlayer) {}
    func playerPlaybackDidLoop(_ player: JCPlayer)  -> Bool {
        //播放下一个
        return self.tryPlayNext?() ?? false
    }
}

