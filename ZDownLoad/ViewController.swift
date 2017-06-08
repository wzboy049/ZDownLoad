//
//  ViewController.swift
//  ZDownLoad
//
//  Created by 王志滨 on 17/6/8.
//  Copyright © 2017年 wzboy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    
    var progressView : DCircleProgress = DCircleProgress(fontSize: 12, lineWidth: 3, color: UIColor.orange)
    
    let url1 = "http://m2.pc6.com/mac/Plants.dmg"
    
    @IBAction func startBtnClick(_ sender: UIButton) {
        
        ZDownLoaderManager.shared.download(urlStr: url1, downLoadInfoBlk: { (totalSize) in
            print("总大小 totalSize = \(totalSize)")
            }, progress: { (progress) in
                print("progress = \(progress)")
                self.progressView.progressValue = CGFloat(progress)
            }, stateChangeBlk: { (state) in
                print("下载状态改变 state = \(state)")
                self.statusLabel.text = "下载状态:" + "\(state)"
            }, successBlk: { (filePath) in
                print("下载成功 filePath = \(filePath)")
        }) { (error) in
            print("下载失败 DownloadFailed, error = \(error.localizedDescription)")
        }
    }
    
    
    @IBAction func pauseBtnClick(_ sender: UIButton) {
        ZDownLoaderManager.shared.pause(urlStr: url1)
    }
    
    
    @IBAction func cancleAndDelete(_ sender: UIButton) {
        ZDownLoaderManager.shared.cacelAndClean(urlStr: url1)
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
         progressView.frame = CGRect(x: 180, y: 100, width: 50, height: 50)
         view.addSubview(progressView)

        
    }
    

    @IBAction func crashButtonClick(_ sender: UIButton) {
        
        let exp = NSException(name: NSExceptionName(rawValue: "崩溃吧"), reason: "haha", userInfo: nil)
        exp.raise()
    }


}

