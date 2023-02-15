//
//  ViewController.swift
//  JCPlayer
//
//  Created by 714799510@qq.com on 02/14/2023.
//  Copyright (c) 2023 714799510@qq.com. All rights reserved.
//

import UIKit
import JCPlayer


class ViewController: UIViewController {
    
    var result: JCPlayer?
    override func viewDidLoad() {
        super.viewDidLoad()
         result = JCPlayer(url: "https://vd2.bdstatic.com/mda-ke9p5635eusp684d/sc/mda-ke9p5635eusp684d.mp4?v_from_s=hkapp-haokan-hnb&auth_key=1676354843-0-0-f2edd50239432a101693538850a20123&bcevod_channel=searchbox_feed&pd=1&cd=0&pt=3&logid=2243595708&vid=14517977793149209079&abtest=&klogid=2243595708")
//        result?.playUI = "ViewController"
        result?.setupPlayer()
        
        self.view.addSubview(result!.playerView)
        result!.playerView.frame = self.view.bounds
        result!.playFromLastTime()
//        result!.playFromBeginning()
        
        self.view.backgroundColor = UIColor.green;
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

