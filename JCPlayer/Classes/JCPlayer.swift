//
//  Player.swift
//  Player_iOS
//
//  Created by LJH on 2020/8/21.
//  Copyright © 2020 Patrick Piemonte. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import CoreGraphics

// MARK: - Player
class JPlayer: AVPlayer {
    deinit {
        NSLog("JPlayer deinit")
    }
}

class JAVURLAsset: AVURLAsset {
    deinit {
        NSLog("JAVURLAsset deinit")
    }
}

class JAVPlayerItem: AVPlayerItem {
    deinit {
        NSLog("JAVPlayerItem deinit")
    }
}
/// Player, simple way to play and stream media
open class JCPlayer: NSObject {
    // types
    
    /// Video fill mode options for `Player.fillMode`.
    ///
    /// - resize: Stretch to fill.
    /// - resizeAspectFill: Preserve aspect ratio, filling bounds.
    /// - resizeAspectFit: Preserve aspect ratio, fill within bounds.
    public typealias FillMode = AVLayerVideoGravity

    /// Asset playback st·ates.
    public enum PlaybackState: Int, CustomStringConvertible {
        case stopped = 0
        case playing
        case paused
        case failed

        public var description: String {
            get {
                switch self {
                case .stopped:
                    return "Stopped"
                case .playing:
                    return "Playing"
                case .failed:
                    return "Failed"
                case .paused:
                    return "Paused"
                }
            }
        }
    }

    /// Asset buffering states.
    public enum BufferingState: Int, CustomStringConvertible {
        case unknown = 0
        case ready
        case delayed

        public var description: String {
            get {
                switch self {
                case .unknown:
                    return "Unknown"
                case .ready:
                    return "Ready"
                case .delayed:
                    return "Delayed"
                }
            }
        }
    }
    
    // properties
    
    /// Player delegate.
    open weak var playerDelegate: PlayerDelegate?

    /// Playback delegate.
    open weak var playbackDelegate: PlayerPlaybackDelegate?
    // Avoid playing in unexpected UI
    open var playUI: String?
    // configuration
    open var stringUrl: String
    /// Local or remote URL for the file asset to be played.
    ///
    /// - Parameter url: URL of the asset.
    open var url: URL? {
        didSet {
            if let url = self.url {
                setup(url: url)
            }
        }
    }

    /// For setting up with AVAsset instead of URL
    /// Note: This will reset the `url` property. (cannot set both)
    open var asset: AVAsset? {
        get { return _asset }
        set { _ = newValue.map { setupAsset($0) } }
    }

    /// Specifies how the video is displayed within a player layer’s bounds.
    /// The default value is `AVLayerVideoGravityResizeAspect`. See `PlayerFillMode`.
    open var fillMode: JCPlayer.FillMode {
        get {
            return self._playerView.playerFillMode
        }
        set {
            self._playerView.playerFillMode = newValue
        }
    }

    /// Determines if the video should autoplay when streaming a URL.
    //open var autoplay: Bool = true

    /// Mutes audio playback when true.
    open var muted: Bool {
        get {
            return self._avplayer.isMuted
        }
        set {
            self._avplayer.isMuted = newValue
        }
    }

    /// Volume for the player, ranging from 0.0 to 1.0 on a linear scale.
    open var volume: Float {
        get {
            return self._avplayer.volume
        }
        set {
            self._avplayer.volume = newValue
        }
    }

    /// Pauses playback automatically when resigning active.
    open var playbackPausesWhenResigningActive: Bool = true

    /// Pauses playback automatically when backgrounded.
    open var playbackPausesWhenBackgrounded: Bool = true

    /// Resumes playback when became active.
    open var playbackResumesWhenBecameActive: Bool = true

    /// Resumes playback when entering foreground.
    open var playbackResumesWhenEnteringForeground: Bool = true

    open var isViewLoaded: Bool = false
    // state
    
    open var isPlaying: Bool {
        get {
            guard let asset = self._asset else {
                return false
            }
            return asset.tracks(withMediaType: .video).count != 0
        }
    }

    /// Playback automatically loops continuously when true.
    open var playbackLoops: Bool {
        get {
            return self._avplayer.actionAtItemEnd == .none
        }
        set {
            if newValue {
                self._avplayer.actionAtItemEnd = .none
            } else {
                self._avplayer.actionAtItemEnd = .pause
            }
        }
    }

    /// Playback freezes on last frame frame when true and does not reset seek position timestamp..
    open var playbackFreezesAtEnd: Bool = false
    /// Current playback state of the Player.
    open var playbackState: PlaybackState = .stopped {
        didSet {
            if playbackState != oldValue {
                self.executeClosureOnMainQueueIfNecessary {
                    self.playerDelegate?.playerPlaybackStateDidChange(self)
                }
            }
        }
    }

    /// Current buffering state of the Player.
    open var bufferingState: BufferingState = .unknown {
        didSet {
            if bufferingState != oldValue {
                self.executeClosureOnMainQueueIfNecessary {
                    self.playerDelegate?.playerBufferingStateDidChange(self)
                }
            }
        }
    }

    /// Playback buffering size in seconds.
    open var bufferSizeInSeconds: Double = 5

    /// Playback is not automatically triggered from state changes when true.
    //open var playbackEdgeTriggered: Bool = true

    open var duration: TimeInterval = 0
    open var watchTime: TimeInterval = 0
    /// Maximum duration of playback.
    open var maximumDuration: TimeInterval {
        get {
            if let playerItem = self._playerItem {
                let time = CMTimeGetSeconds(playerItem.duration)
                return time.isNaN ? 0 : time
            } else {
                return 0
            }
        }
    }

    /// Media playback's current time interval in seconds.
    open var currentTimeInterval: TimeInterval {
        get {
            if let playerItem = self._playerItem {
                let time = CMTimeGetSeconds(playerItem.currentTime())
                return time.isNaN ? 0 : time
            } else {
                //CMTime.indefinite
                return 0
            }
        }
    }
    
    /// Media playback's current time.
    open var currentTime: CMTime {
        get {
            if let playerItem = self._playerItem {
                return playerItem.currentTime()
            } else {
                return kCMTimeZero
            }
        }
    }

    /// The natural dimensions of the media.
    open var naturalSize: CGSize {
        get {
            if let playerItem = self._playerItem,
                let track = playerItem.asset.tracks(withMediaType: .video).first {

                let size = track.naturalSize.applying(track.preferredTransform)
                return CGSize(width: abs(size.width), height: abs(size.height))
            } else {
                return CGSize.zero
            }
        }
    }

    /// self.view as PlayerView type
    public var playerView: PlayerView {
        get {
            return self._playerView
        }
    }

    /// Return the av player layer for consumption by things such as Picture in Picture
    open func playerLayer() -> AVPlayerLayer? {
        return self._playerView.playerLayer
    }

    /// Indicates the desired limit of network bandwidth consumption for this item.
    open var preferredPeakBitRate: Double = 0 {
        didSet {
            self._playerItem?.preferredPeakBitRate = self.preferredPeakBitRate
        }
    }

    /// Indicates a preferred upper limit on the resolution of the video to be downloaded.
    @available(iOS 11.0, tvOS 11.0, *)
    open var preferredMaximumResolution: CGSize {
        get {
            return self._playerItem?.preferredMaximumResolution ?? CGSize.zero
        }
        set {
            self._playerItem?.preferredMaximumResolution = newValue
            self._preferredMaximumResolution = newValue
        }
    }

    // MARK: - private instance vars

    internal var _asset: AVAsset? {
        didSet {
            if let _ = self._asset {
                self.setupPlayerItem(nil)
            }
        }
    }
    internal lazy var _avplayer: JPlayer = {
        let avplayer = JPlayer()
        NSLog("JCPlayer init")
        avplayer.actionAtItemEnd = .pause
        avplayer.automaticallyWaitsToMinimizeStalling = true
        return avplayer
    }()
    internal var _playerItem: AVPlayerItem?

    internal var _playerObservers = [NSKeyValueObservation]()
    internal var _playerItemObservers = [NSKeyValueObservation]()
    internal var _playerLayerObserver: NSKeyValueObservation?
    internal var _playerTimeObserver: Any?

    internal var _playerView: PlayerView = PlayerView(frame: .zero)
    internal var _seekTimeRequested: CMTime?
    internal var _lastBufferTime: Double = 0
    internal var _preferredMaximumResolution: CGSize = .zero
    internal var _pauseTime: CMTime?
    internal var _playEnd = false
    // Boolean that determines if the user or calling coded has trigged autoplay manually.
    //internal var _hasAutoplayActivated: Bool = true

    // MARK: - object lifecycle

    public init(url: String) {
        stringUrl = url
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupPlayer() {
        guard let _url = URL(string: stringUrl) else {
            return
        }
        self.isViewLoaded = true
        self.url = _url
        self.playerView.playerBackgroundColor = .clear
        self.playbackLoops = true //循环
        self.fillMode = .resize
        self.addPlayerLayerObservers()
        self.addPlayerObservers()
//        self.addApplicationObservers()
    }

    deinit {
        self._avplayer.pause()
        self.setupPlayerItem(nil)

        self.removePlayerObservers()

        self.playerDelegate = nil
        self.removeApplicationObservers()

        self.playbackDelegate = nil
        self.removePlayerLayerObservers()
        self._playerView.player = nil
    }

    // MARK: - view lifecycle

//    open override func loadView() {
//        super.loadView()
//        self._playerView.frame = self.view.bounds
//        self.view = self._playerView
//    }

//    open override func viewDidLoad() {
//        super.viewDidLoad()
//        if let url = self.url {
//            setup(url: url)
//        } else if let asset = self.asset {
//            setupAsset(asset)
//        }
//
//        self.addPlayerLayerObservers()
//        self.addPlayerObservers()
//        self.addApplicationObservers()
//    }

//    open override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        if self.playbackState == .playing {
//            self.pause()
//        }
//    }

}

// MARK: - performance

extension JCPlayer {

    /// Total time spent playing.
    public var totalDurationWatched: TimeInterval {
        get {
            var totalDurationWatched = 0.0
            if let accessLog = self._playerItem?.accessLog(), accessLog.events.isEmpty == false {
                for event in accessLog.events where event.durationWatched > 0 {
                    totalDurationWatched += event.durationWatched
                }
            }
            let result = max(0, totalDurationWatched - watchTime)
            watchTime = totalDurationWatched
            return result
        }
    }

    /// Time weighted value of the variant indicated bitrate. Measure of overall stream quality.
    var timeWeightedIBR: Double {
        var timeWeightedIBR = 0.0
        let totalDurationWatched = self.totalDurationWatched
           
        if let accessLog = self._playerItem?.accessLog(), totalDurationWatched > 0 {
            for event in accessLog.events {
                if event.durationWatched > 0 && event.indicatedBitrate > 0 {
                    let eventTimeWeight = event.durationWatched / totalDurationWatched
                    timeWeightedIBR += event.indicatedBitrate * eventTimeWeight
                }
            }
        }
        return timeWeightedIBR
    }

    /// Stall rate measured in stalls per hour. Normalized measure of stream interruptions caused by stream buffer depleation.
    var stallRate: Double {
        var totalNumberOfStalls = 0
        let totalHoursWatched = self.totalDurationWatched / 3600
        
        if let accessLog = self._playerItem?.accessLog(), totalDurationWatched > 0 {
            for event in accessLog.events {
                totalNumberOfStalls += event.numberOfStalls
            }
        }
        return Double(totalNumberOfStalls) / totalHoursWatched
    }

}

// MARK: - actions

extension JCPlayer {

    /// Begins playback of the media from the beginning.
    open func playFromBeginning() {
        self.playbackDelegate?.playerPlaybackWillStartFromBeginning(self)
        self._playEnd = false
        self._avplayer.seek(to: kCMTimeZero)
        self.playFromCurrentTime()
    }

    /// Begins playback of the media from the current time.
    open func playFromCurrentTime() {
        //if !self.autoplay {
            // External call to this method with autoplay disabled. Re-activate it before calling play.
            //self._hasAutoplayActivated = true
        //}
        self._playEnd = false
        self.play()
    }
    
    /// Begins playback of the media from the last pause.
    open func playFromLastTime(fromLast: Bool = true) {
        self.playbackDelegate?.playerPlaybackWillStartFromBeginning(self)
        //self._avplayer.seek(to: self._pauseTime)
        //let validTime = CMTimeGetSeconds(self._pauseTime ?? .zero)
        //NSLog("_pauseTime\(validTime)")
        
        if fromLast, !self._playEnd, let _pauseTime = self._pauseTime {
            self._avplayer.seek(to: _pauseTime, toleranceBefore: CMTimeMakeWithSeconds(40, 100), toleranceAfter: kCMTimePositiveInfinity)
        } else {
            self._pauseTime = nil
            self._avplayer.seek(to: kCMTimeZero)
        }
        self.playFromCurrentTime()
    }
    
    open func replay() {
        switch (self.playbackState.rawValue) {
        case PlaybackState.stopped.rawValue:
            self.playFromBeginning()
        case PlaybackState.paused.rawValue:
            self.playFromCurrentTime()
        case PlaybackState.playing.rawValue:
            self.pause()
        case PlaybackState.failed.rawValue:
            self.pause()
        default:
            self.pause()
        }
    }

    fileprivate func play() {
        guard checkCanPlay() else {return }
        //if self.autoplay || self._hasAutoplayActivated {
        do {
            
//            if #available(iOS 11.0, *) {
//                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longForm, options: [])
//                } else if #available(iOS 10.0, *) {
//                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
//                } else {
//                    // Compiler error: 'setCategory' is unavailable in Swift
//                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
//                }
            
//            try AVAudioSession.sharedInstance().setCategory(.playback, mode:.default , options: [])
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            NSLog("AVAudioSession.sharedInstance().setCategory(.playback)\n \(error)")
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            NSLog("AVAudioSession.sharedInstance().setActive(true\n \(error)")
        }
//        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .interruptSpokenAudioAndMixWithOthers)
        self.playbackState = .playing
        self.playerView.reframePlayerView()
        self._avplayer.play()
        //}
    }
    static private func rootWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            let keyWindow = UIApplication.shared.connectedScenes
            .lazy
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first { $0.isKeyWindow }
            return keyWindow
        } else {
            return UIApplication.shared.keyWindow
        }
    }
    
    static private func topViewControllerWithRootViewController(_ rootViewController: UIViewController) -> UIViewController? {
        if let tabBarController = rootViewController as? UITabBarController {
            guard let root = tabBarController.selectedViewController else {
                return tabBarController
            }
            return topViewControllerWithRootViewController(root)
        }
        else if let naviController = rootViewController as? UINavigationController {
            guard let root = naviController.visibleViewController else { return naviController }
            return topViewControllerWithRootViewController(root)
        }
        else if rootViewController is UIPageViewControllerDataSource, let pageController = rootViewController.childViewControllers.first as? UIPageViewController, let firstPage = pageController.viewControllers?.first {
            return topViewControllerWithRootViewController(firstPage)
        }
        else if let root = rootViewController.presentedViewController {
            return topViewControllerWithRootViewController(root)
        }
        else {
            return rootViewController
        }
    }
    
    static private func topViewController() -> UIViewController? {
        guard let root = rootWindow()?.rootViewController else {
            return nil
        }
        return topViewControllerWithRootViewController(root)
    }
    
    func checkCanPlay() -> Bool {
        if let uikey = playUI, let vc = JCPlayer.topViewController(), uikey != "\(type(of: vc).self)" {
            //NSLog("checkCanPlay pause \(uikey) != \(type(of: vc).self)")
            return false
        }
        return true
    }
    /// Pauses playback of the media.
    open func pause() {
        if self.playbackState != .playing {
            return
        }
        self._avplayer.pause()
        self.playbackState = .paused
        //记录播放进度，便于事后继续播放
        self._pauseTime = self.currentTime
    }

    /// Stops playback of the media.
    open func stop() {
        if self.playbackState == .stopped {
            return
        }

        self._avplayer.pause()
        self.playbackState = .stopped
        self.playbackDelegate?.playerPlaybackDidEnd(self)
        self._pauseTime = nil
    }

    /// Updates playback to the specified time.
    ///
    /// - Parameters:
    ///   - time: The time to switch to move the playback.
    ///   - completionHandler: Call block handler after seeking/
    open func seek(to time: CMTime, completionHandler: ((Bool) -> Swift.Void)? = nil) {
        if let playerItem = self._playerItem {
            return playerItem.seek(to: time, completionHandler: completionHandler)
        } else {
            self._seekTimeRequested = time
        }
    }

    /// Updates the playback time to the specified time bound.
    ///
    /// - Parameters:
    ///   - time: The time to switch to move the playback.
    ///   - toleranceBefore: The tolerance allowed before time.
    ///   - toleranceAfter: The tolerance allowed after time.
    ///   - completionHandler: call block handler after seeking
    open func seekToTime(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: ((Bool) -> Swift.Void)? = nil) {
        if let playerItem = self._playerItem {
            return playerItem.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
        }
    }

    /// Captures a snapshot of the current Player asset.
    ///
    /// - Parameter completionHandler: Returns a UIImage of the requested video frame. (Great for thumbnails!)
    open func takeSnapshot(completionHandler: ((_ image: UIImage?, _ error: Error?) -> Void)? ) {
        guard let asset = self._playerItem?.asset else {
            self.executeClosureOnMainQueueIfNecessary {
                completionHandler?(nil, nil)
            }
            return
        }

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let currentTime = self._playerItem?.currentTime() ?? kCMTimeZero

        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: currentTime)]) { (requestedTime, image, actualTime, result, error) in
            guard let image = image else {
                self.executeClosureOnMainQueueIfNecessary {
                    completionHandler?(nil, error)
                }
                return
            }
            
            switch result {
            case .succeeded:
                let uiimage = UIImage(cgImage: image)
                self.executeClosureOnMainQueueIfNecessary {
                    completionHandler?(uiimage, nil)
                }
                break
            case .failed, .cancelled:
                fallthrough
            @unknown default:
                self.executeClosureOnMainQueueIfNecessary {
                    completionHandler?(nil, nil)
                }
                break
            }
        }
    }

}

// MARK: - loading funcs

extension JCPlayer {

    fileprivate func setup(url: URL) {
        guard isViewLoaded else { return }
        
        // ensure everything is reset beforehand
        if self.playbackState == .playing {
            self.pause()
        }

        // Reset autoplay flag since a new url is set.
        //self._hasAutoplayActivated = false
        //if self.autoplay {
            //self.playbackState = .playing
        //} else {
            self.playbackState = .stopped
        //}

        self.setupPlayerItem(nil)

        let asset = JAVURLAsset(url: url, options: .none)
        NSLog("JCAVURLAsset init")
        self.setupAsset(asset)
    }
    
    fileprivate func setupAsset(_ asset: AVAsset, loadableKeys: [String] = ["tracks", "playable", "duration"]) {
        guard isViewLoaded else { return }

        if self.playbackState == .playing {
            self.pause()
        }

        self.bufferingState = .unknown

        self._asset = asset

        self._asset?.loadValuesAsynchronously(forKeys: loadableKeys, completionHandler: { () -> Void in
            guard let asset = self._asset else {
                return
            }
            
            for key in loadableKeys {
                var error: NSError? = nil
                if key == "tracks" {
                    if let track = asset.tracks(withMediaType: .video).first {
                    let size = track.naturalSize.applying(track.preferredTransform)
                        let _size = CGSize(width: abs(size.width), height: abs(size.height))
                        self.executeClosureOnMainQueueIfNecessary {
                            self.playerView.originalSize = _size
                            self.playerView.reframePlayerView()
                        }
                    }
                }
                
                let status = asset.statusOfValue(forKey: key, error: &error)
                if status == .failed {
                    self.playbackState = .failed
                    self.executeClosureOnMainQueueIfNecessary {
                        self.playerDelegate?.player(self, didFailWithError: error)
                    }
                    return
                }
            }

            if !asset.isPlayable {
                self.playbackState = .failed
                self.executeClosureOnMainQueueIfNecessary {
                    self.playerDelegate?.player(self, didFailWithError: PlayerError.failed)
                }
                return
            }
            let playerItem = JAVPlayerItem(asset:asset)
            NSLog("JCAVPlayerItem init")
            self.setupPlayerItem(playerItem)
        })
    }

    fileprivate func setupPlayerItem(_ playerItem: AVPlayerItem?) {

        self.removePlayerItemObservers()

        if let currentPlayerItem = self._playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentPlayerItem)
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: currentPlayerItem)
        }

        self._playerItem = playerItem

        self._playerItem?.preferredPeakBitRate = self.preferredPeakBitRate
        if #available(iOS 11.0, tvOS 11.0, *) {
            self._playerItem?.preferredMaximumResolution = self._preferredMaximumResolution
        }

        if let seek = self._seekTimeRequested, self._playerItem != nil {
            self._seekTimeRequested = nil
            self.seek(to: seek)
        }

        if let updatedPlayerItem = self._playerItem {
            self.addPlayerItemObservers()
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: updatedPlayerItem)
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlayToEndTime(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: updatedPlayerItem)
        }

        self._avplayer.replaceCurrentItem(with: self._playerItem)

        // update new playerItem settings
        if self.playbackLoops {
            self._avplayer.actionAtItemEnd = .none
        } else {
            self._avplayer.actionAtItemEnd = .pause
        }
    }

}

// MARK: - NSNotifications

extension JCPlayer {

    // MARK: - UIApplication

    internal func addApplicationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillResignActive(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }

    internal func removeApplicationObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - AVPlayerItem handlers

    @objc internal func playerItemDidPlayToEndTime(_ aNotification: Notification) {
        self.executeClosureOnMainQueueIfNecessary {
            if self.playbackLoops {
                self.playbackDelegate?.playerPlaybackWillLoop(self)
//                self._avplayer.seek(to: CMTime.zero)
//                CMTimeMake(value: 50, timescale: 100)
//                CMTimeMakeWithSeconds(60, preferredTimescale: 100)
                self._avplayer.seek(to: kCMTimeZero, toleranceBefore: kCMTimeZero, toleranceAfter: CMTimeMakeWithSeconds(30, 100))
                self._pauseTime = nil
                self._playEnd = true
                guard self.checkCanPlay() else {return }
                
                if !(self.playbackDelegate?.playerPlaybackDidLoop(self) ?? false) {
                    self._avplayer.play()
                }
            } else if self.playbackFreezesAtEnd {
                self.stop()
            } else {
                self._avplayer.seek(to: kCMTimeZero, completionHandler: { _ in
                    self.stop()
                })
            }
        }
    }

    @objc internal func playerItemFailedToPlayToEndTime(_ aNotification: Notification) {
        self.playbackState = .failed
    }

    // MARK: - UIApplication handlers

    @objc internal func handleApplicationWillResignActive(_ aNotification: Notification) {
        if self.playbackState == .playing && self.playbackPausesWhenResigningActive {
            self.pause()
        }
    }

    @objc internal func handleApplicationDidBecomeActive(_ aNotification: Notification) {
        if self.playbackState == .paused && self.playbackResumesWhenBecameActive {
            self.play()
        }
    }

    @objc internal func handleApplicationDidEnterBackground(_ aNotification: Notification) {
        if self.playbackState == .playing && self.playbackPausesWhenBackgrounded {
            self.pause()
        }
    }

    @objc internal func handleApplicationWillEnterForeground(_ aNoticiation: Notification) {
        if self.playbackState != .playing && self.playbackResumesWhenEnteringForeground {
            self.play()
        }
    }

}

// MARK: - KVO

extension JCPlayer {

    // MARK: - AVPlayerItemObservers

    internal func addPlayerItemObservers() {
        guard let playerItem = self._playerItem else {
            return
        }

        self._playerItemObservers.append(playerItem.observe(\.isPlaybackBufferEmpty, options: [.new, .old]) { [weak self] (object, change) in
                if object.isPlaybackBufferEmpty {
                    self?.bufferingState = .delayed
                }

                switch object.status {
                case .readyToPlay:
                        self?._playerView.player = self?._avplayer
                case .failed:
                    self?.playbackState = PlaybackState.failed
                default:
                    break
                }
        })

        self._playerItemObservers.append(playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new, .old]) { [weak self] (object, change) in
            guard let strongSelf = self else {
                return
            }
            
            if object.isPlaybackLikelyToKeepUp {
                strongSelf.bufferingState = .ready
                if strongSelf.playbackState == .playing {
                    strongSelf.playFromCurrentTime()
                }
            }

            switch object.status {
            case .failed:
                strongSelf.playbackState = PlaybackState.failed
                break
            case .unknown:
                fallthrough
            case .readyToPlay:
                fallthrough
            @unknown default:
                strongSelf._playerView.player = self?._avplayer
                break
            }
        })
        /*
        self._playerItemObservers.append(playerItem.observe(\.isPlaybackBufferFull, options: [.new, .old]) { [weak self] (object, change) in
                if object.isPlaybackBufferFull {
                    self?.bufferingState = .ready
                }
        })*/
        
        self._playerItemObservers.append(playerItem.observe(\.duration, options: [.new, .old]) { [weak self] (object, change) in
            guard let strongSelf = self else {
                return
            }
            let time = object.duration
            if time.flags.contains(.valid) {
                let validTime = CMTimeGetSeconds(time)
                strongSelf.duration = validTime
                strongSelf.playerDelegate?.player(strongSelf, didGetDuration: validTime)
            }
        })
            
        self._playerItemObservers.append(playerItem.observe(\.loadedTimeRanges, options: [.new, .old]) { [weak self] (object, change) in
            guard let strongSelf = self else {
                return
            }

            let timeRanges = object.loadedTimeRanges
            if let timeRange = timeRanges.first?.timeRangeValue {
                let bufferedTime = CMTimeGetSeconds(CMTimeAdd(timeRange.start, timeRange.duration))
                if strongSelf._lastBufferTime != bufferedTime {
                    strongSelf._lastBufferTime = bufferedTime
                    strongSelf.executeClosureOnMainQueueIfNecessary {
                        strongSelf.playerDelegate?.playerBufferTimeDidChange(bufferedTime)
                    }
                }
            }

            let currentTime = CMTimeGetSeconds(object.currentTime())
            let passedTime = strongSelf._lastBufferTime <= 0 ? currentTime : (strongSelf._lastBufferTime - currentTime)

            if (passedTime >= strongSelf.bufferSizeInSeconds ||
                strongSelf._lastBufferTime == strongSelf.maximumDuration ||
                timeRanges.first == nil) &&
                strongSelf.playbackState == .playing {
                strongSelf.play()
            }
        })
    }

    internal func removePlayerItemObservers() {
        for observer in self._playerItemObservers {
            observer.invalidate()
        }
        self._playerItemObservers.removeAll()
    }

    // MARK: - AVPlayerLayerObservers

    internal func addPlayerLayerObservers() {
        self._playerLayerObserver = self._playerView.playerLayer.observe(\.isReadyForDisplay, options: [.new, .old]) { [weak self] (object, change) in
            self?.executeClosureOnMainQueueIfNecessary {
                if let strongSelf = self {
                    strongSelf.playerDelegate?.playerReady(strongSelf)
                }
            }
        }
    }

    internal func removePlayerLayerObservers() {
        self._playerLayerObserver?.invalidate()
        self._playerLayerObserver = nil
    }

    @objc func otherAudioComein(_ sender: Notification) {
        var thisType: AVAudioSession.InterruptionType?
        if let type = sender.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber {
            thisType = AVAudioSession.InterruptionType(rawValue: type.uintValue)
        } else if let type = sender.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt {
            thisType = AVAudioSession.InterruptionType(rawValue: type)
        }
        guard let _thisType = thisType else {
            return
        }
        if _thisType == .began {
            self.pause()
        }
    }
    // MARK: - AVPlayerObservers

    internal func addPlayerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(otherAudioComein(_:)), name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
        self._playerTimeObserver = self._avplayer.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 100), queue: DispatchQueue.main, using: { [weak self] timeInterval in
            guard let strongSelf = self else {
                return
            }
            strongSelf.playbackDelegate?.playerCurrentTimeDidChange(strongSelf, CMTimeGetSeconds(timeInterval))
            
            if strongSelf._playerItem?.status == .readyToPlay, let ready = strongSelf._playerItem?.isPlaybackLikelyToKeepUp {
                strongSelf.bufferingState = ready ? .ready : .delayed
            }
        })

        if #available(iOS 10.0, tvOS 10.0, *) {
            self._playerObservers.append(self._avplayer.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] (object, change) in
                switch object.timeControlStatus {
                case .paused:
                    self?.playbackState = .paused
                case .playing:
                    self?.playbackState = .playing
                case .waitingToPlayAtSpecifiedRate:
                    fallthrough
                @unknown default:
                    break
                }
            })
        }

    }

    internal func removePlayerObservers() {
        if let observer = self._playerTimeObserver {
            self._avplayer.removeTimeObserver(observer)
        }
        for observer in self._playerObservers {
            observer.invalidate()
        }
        self._playerObservers.removeAll()
    }

}

// MARK: - queues

extension JCPlayer {

    internal func executeClosureOnMainQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async(execute: closure)
        }
    }

}
