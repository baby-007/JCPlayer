//
//  AutoVideoPlay.swift
//  JCMoments
//
//  Created by LJH on 2020/7/7.
//  Copyright © 2020 jingcheng. All rights reserved.
//

//MARK: 自动播放媒体管理
import UIKit

///自动播放协议
protocol AutoPlayable: NSObjectProtocol {
    func play(_ isPlay: Bool, type: PlayType)
}

///自动播放管理 针对 tableView 和 collectionView
class AutoMediaPlayer: NSObject {
    
    ///静音播放
    private(set) var mutePlay: Bool = false
    
    func resetMute(_ new: Bool) {
        mutePlay = new
    }

    
    //MARK: 播放媒体 统一管理
    class func playMedia(_ traget: AutoPlayable, type: PlayType = .video, isPlay: Bool = true) {
        //如果前一个自动播放的对象地址和当前播放地址一样就取消播放
        traget.play(isPlay, type: type)
    }
    
    //MARK: 播放table中的媒体 tableCell 必须实现 AutoPlayable协议
    ///- parameter type: 播放媒体类型
    ///- parameter isPlay: 是否播放 默认播放 否则停止播放
    @discardableResult class func playInTable(_ tableView: UITableView, type: PlayType = .video, isPlay: Bool = true) -> UITableViewCell?   {
        let cell = getRespondTableCell(tableView)
        playInCell(cell, type: type, isPlay: isPlay)
        return cell
    }
    
    @discardableResult class func playInCollection(_ collectionView: UICollectionView, type: PlayType = .video, isPlay: Bool = true) -> UICollectionViewCell? {
        let cell = getRespondCollectionCell(collectionView)
        playInCell(cell, type: type, isPlay: isPlay)
        return cell
    }
    
    //MARK: 播放 tableView 当前页的媒体
    class func playCurrentPageInTableView(_ tableView: UITableView, type: PlayType = .video, isPlay: Bool = true) {
        let cell = currentPageTableCell(tableView)
        playInCell(cell, type: type, isPlay: isPlay)
    }
    
    //MARK: 播放 collectionView 当前页的媒体
    class func playCurrentPageInCollectionView(_ collectionView: UICollectionView, type: PlayType = .video, isPlay: Bool = true, direction: UICollectionView.ScrollDirection = .horizontal, section: Int = 0) {
        let cell = currentPageCollectionCell(collectionView, direction: direction, section: section)
        playInCell(cell, type: type, isPlay: isPlay)
    }
    
    //MARK: 播放cell的媒体
    ///- parameter cell: 可能是tableViewCell 或 collectionViewCell
    class func playInCell(_ cell: AnyObject?, type: PlayType, isPlay: Bool) {
        if let playCell = cell as? AutoPlayable {
            playMedia(playCell, type: type, isPlay: isPlay)
        } else {
            //不支持自动播放 则停止断点续播模式
            GlobalArrayPlayer.shared.continuePlay = false
        }
    }
    
    //MARK: 获取 tableView 的响应Cell
    class func getRespondTableCell(_ tableView: UITableView) -> UITableViewCell? {
        let cells = tableView.visibleCells
        var selectCell: UITableViewCell?
        let centerY = tableView.contentOffset.y + tableView.bounds.size.height / 2.0
        var disY: Float = 100000
        for cell in cells {
            let curDisY = fabsf(Float(cell.center.y - centerY))
            if curDisY < disY {
                disY = curDisY
                selectCell = cell
            } else {
                break
            }
        }
        return selectCell
    }
    
    //MARK: 获取 collectionView 的响应Cell
    class func getRespondCollectionCell(_ collectionView: UICollectionView) -> UICollectionViewCell? {
        
        let cells = collectionView.visibleCells
        var selectCell: UICollectionViewCell?
        let centerY = collectionView.contentOffset.y + collectionView.bounds.size.height / 2.0
        var disY: Float = 100000
        for cell in cells {
            let curDisY = fabsf(Float(cell.center.y - centerY))
            if curDisY < disY {
                disY = curDisY
                selectCell = cell
            } else {
                break
            }
        }
        return selectCell
    }
    
    class func getRespondHorizontalCell(_ collectionView: UICollectionView) -> UICollectionViewCell? {
        
        let cells = collectionView.visibleCells
        var selectCell: UICollectionViewCell?
        let centerX = collectionView.contentOffset.x + collectionView.bounds.size.width / 2.0
        var disX: Float = 100000
        for cell in cells {
            let curDisX = fabsf(Float(cell.center.x - centerX))
            if curDisX < disX {
                disX = curDisX
                selectCell = cell
            }
        }
        return selectCell
    }
    
    //MARK: 获取tableView当前页的cell
    class func currentPageTableCell(_ tableView: UITableView, section: Int = 0) -> UITableViewCell? {
        let page = Int(tableView.contentOffset.y / tableView.bounds.size.height)
        return tableView.cellForRow(at: IndexPath(row: page, section: section))
    }
    
    //MARK: 获取collectionView当前页的cell
    class func currentPageCollectionCell(_ collectionView: UICollectionView, direction: UICollectionView.ScrollDirection = .horizontal, section: Int = 0) -> UICollectionViewCell? {
        if direction == .horizontal {
            let page = Int(collectionView.contentOffset.x / collectionView.bounds.size.width)
            return collectionView.cellForItem(at: IndexPath(item: page, section: section))
        } else {
            let page = Int(collectionView.contentOffset.y / collectionView.bounds.size.height)
            return collectionView.cellForItem(at: IndexPath(item: page, section: section))
        }
    }
}
