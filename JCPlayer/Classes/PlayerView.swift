//
//  PlayerView.swift
//  JCMoments
//
//  Created by LJH on 2020/8/21.
//  Copyright © 2020 jingcheng. All rights reserved.
//

import UIKit
import AVFoundation
// MARK: - PlayerView
public class PlayerView: UIView {

    // MARK: - overrides

    public override class var layerClass: AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }

    // MARK: - internal properties

    internal var playerLayer: AVPlayerLayer {
        get {
            return self.layer as! AVPlayerLayer
        }
    }

    internal var player: AVPlayer? {
        get {
            return self.playerLayer.player
        }
        set {
            DispatchQueue.main.async {
                self.playerLayer.player = newValue
                self.playerLayer.isHidden = (self.playerLayer.player == nil)
            }
            
        }
    }

    // MARK: - public properties

    public var playerBackgroundColor: UIColor? {
        get {
            if let cgColor = self.playerLayer.backgroundColor {
                return UIColor(cgColor: cgColor)
            }
            return nil
        }
        set {
            self.playerLayer.backgroundColor = newValue?.cgColor
        }
    }

    public var playerFillMode: JCPlayer.FillMode {
        get {
            return self.playerLayer.videoGravity
        }
        set {
            self.playerLayer.videoGravity = newValue
        }
    }

    public var isReadyForDisplay: Bool {
        get {
            return self.playerLayer.isReadyForDisplay
        }
    }

    public var selfSetFrame: Bool = false
    public var didSetFrame: Bool = false
    public var originalSize: CGSize?
    // MARK: - object lifecycle

    public override init(frame: CGRect) {
        NSLog("PlayerView产生")
        super.init(frame: frame)
        self.playerLayer.isHidden = true
        self.playerFillMode = .resizeAspect
    }

    required public init?(coder aDecoder: NSCoder) {
        NSLog("PlayerView产生")
        super.init(coder: aDecoder)
        self.playerLayer.isHidden = true
        self.playerFillMode = .resizeAspect
    }

    public override var frame: CGRect {
        didSet {
            if !selfSetFrame, frame.size.height > 0.5 {
                didSetFrame = true
                NSLog("set playerView frame")
            }
            selfSetFrame = false
        }
    }
    
    func resizeTo(mediaHeight: CGFloat, mediaWidth: CGFloat, width: CGFloat, height: CGFloat) -> CGSize {
        let reSize: CGSize
        let sOrign = mediaHeight / max(mediaWidth, 1)
        let sDisplay = height / max(width, 1)
        
        if sOrign < sDisplay && mediaHeight - mediaWidth > 10 {
            reSize = CGSize(width: height / sOrign, height: height)
        } else {
            reSize = CGSize(width: width, height: width * sOrign)
        }
        return reSize
    }
    func reframePlayerView() {
        guard self.didSetFrame, self.playerFillMode == .resize else {return }
        //DispatchQueue.main.async {
            guard let _size = self.originalSize, bounds.size.height > 0.5 else {return }
            let _scale = _size.width / max(1, _size.height)
            let _curScale = bounds.size.width / max(1, bounds.size.height)
            if abs(_scale - _curScale) > 0.04 {
                let _size = self.resizeTo(mediaHeight: _size.height, mediaWidth: _size.width, width: bounds.size.width, height: bounds.size.height)
                let _rect = CGRect(x: frame.origin.x + (bounds.size.width - _size.width) / 2.0, y: frame.origin.y + (bounds.size.height - _size.height) / 2.0, width: _size.width, height: _size.height)
                self.selfSetFrame = true
                self.frame = _rect
                NSLog("纠正视频尺寸")
            }
            self.didSetFrame = false
        //}
    }
    
//    public override func layoutSubviews() {
//        super.layoutSubviews()
//        playerLayer.frame = self.frame
//    }
    deinit {
        NSLog("PlayerView释放")
        self.player?.pause()
        self.player = nil
    }

}

