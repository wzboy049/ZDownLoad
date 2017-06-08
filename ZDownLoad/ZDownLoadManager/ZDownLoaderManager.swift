//
//  ZDownLoaderManager.swift
//  SwiftDownLoader
//
//  Created by wzboy on 17/3/16.
//  Copyright © 2017年 zbx. All rights reserved.
//

import UIKit

class ZDownLoaderManager: NSObject {
    
    var downLoadInfo = [String:ZDownLoader]()
    
    /// 单例
    static let shared: ZDownLoaderManager = ZDownLoaderManager()

    func download(urlStr:String,downLoadInfoBlk:@escaping ZDownloadInfoBlock,progress:@escaping ZDownloadProgressBlock, stateChangeBlk:@escaping ZDownloadStateChangeBlock,successBlk: @escaping ZDownloadSuccessBlock,failureBlk:@escaping ZDownloadFailedBlock) {
        
        let url = URL(string: urlStr)!
        
        let urlMD5 = url.absoluteString.md5String()
        
        var downloader  = downLoadInfo[urlMD5]
        
        if downloader == nil{
            downloader = ZDownLoader()
            downLoadInfo[urlMD5] = downloader!
        }
        
        downloader!.md5Key = urlMD5
        
        weak var weakSelf = self
        
        downloader!.download(urlStr: urlStr, downLoadInfoBlk: downLoadInfoBlk, progressBlk: progress, downloadStateBlk: stateChangeBlk, success: { (filePath) in
            
            _ = weakSelf?.downLoadInfo.removeValue(forKey: urlMD5)
            successBlk(filePath)
            
            }) {(error) in
                failureBlk(error)
        }
        
    
    }
    
    func pause(urlStr:String){
        
        let url = URL(string: urlStr)!
        let urlMD5 = url.absoluteString.md5String()
        let downloader  = downLoadInfo[urlMD5]
    
        downloader?.pauseCurrentTask()
    }
    
    func resume(urlStr:String) -> ZDownLoader?{
        let url = URL(string: urlStr)!
        let urlMD5 = url.absoluteString.md5String()
        let downloader  = downLoadInfo[urlMD5]
        
        downloader?.resumeCurrentTask()
        
        return downloader
    }
    

    
    func  cacelAndClean(urlStr:String){
        
        let url = URL(string: urlStr)!
        let urlMD5 = url.absoluteString.md5String()
        let downloader  = downLoadInfo[urlMD5]
        
        downloader?.cacelAndClean()
    }
    
    
    func pauseAll(){
        
        let keys = downLoadInfo.keys
        
        for key in keys {
            let value = downLoadInfo[key]
            value?.pauseCurrentTask()
        }
    }
    
    func resumeAll(){
        let keys = downLoadInfo.keys
        
        for key in keys {
            let value = downLoadInfo[key]
            value?.resumeCurrentTask()
        }
    }
}


extension String {
    
    func md5String() -> String{
        let cStr = self.cString(using: String.Encoding.utf8);
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(cStr!,(CC_LONG)(strlen(cStr!)), buffer)
        let md5String = NSMutableString();
        for i in 0 ..< 16{
            md5String.appendFormat("%02x", buffer[i])
        }
        free(buffer)
        return md5String as String
    }
    
}

