//
//  ZDownLoader.swift
//  SwiftDownLoader
//
//  Created by wzboy on 17/3/16.
//  Copyright © 2017年 zbx. All rights reserved.
//

import UIKit

public enum ZDownloaderState {
    case pause
    case downLoading
    case pauseSuccess
    case pauseFailed
}

typealias ZDownloadInfoBlock = (Int)->()
typealias ZDownloadProgressBlock = (Float)->()
typealias ZDownloadSuccessBlock = (String)->()
typealias ZDownloadFailedBlock = (Error)->()
typealias ZDownloadStateChangeBlock = (ZDownloaderState)->()


class ZDownLoader: NSObject ,URLSessionDataDelegate{
    
    let downloadedFolder =  cachePath() + "/ZDownloader/Downloaded/"
    let downloadingFolder =  cachePath() + "/ZDownloader/Downloading/"
    
    var md5Key = ""
    
    var state : ZDownloaderState = .pause {
        didSet{
            
            // 代理, block, 通知
            if stateChange != nil{
                stateChange!(state)
            }
            
            if state == .pauseSuccess && successBlock != nil{
                successBlock!(downLoadedPath)
            }
            

            
        }
    }
    
    var progress : Float = 0{
        didSet{
            if progressChange != nil{
                progressChange!(progress)
            }
        }
    }
    
    var downLoadInfo : ZDownloadInfoBlock?
    var stateChange : ZDownloadStateChangeBlock?
    var progressChange : ZDownloadProgressBlock?
    var successBlock : ZDownloadSuccessBlock?
    var failureBlock : ZDownloadFailedBlock?
    
    /// 记录文件临时下载大小
    fileprivate var tempSize : Int = 0
    
    /// 记录文件总大小
    fileprivate var totalSize : Int = 0
    
    /// 下载会话
    fileprivate var session : URLSession?
    fileprivate var downLoadedPath : String = ""
    fileprivate var downLoadingPath : String = ""
//    fileprivate var outputStream : OutputStream?
    fileprivate var writeHandle : FileHandle?
    
    public var dataTask : URLSessionDataTask?
    
    deinit {
        writeHandle?.closeFile()
        writeHandle = nil
    }
    
    func download(urlStr:String,downLoadInfoBlk:@escaping ZDownloadInfoBlock,progressBlk:@escaping ZDownloadProgressBlock,downloadStateBlk : @escaping ZDownloadStateChangeBlock, success:@escaping ZDownloadSuccessBlock,failure:@escaping ZDownloadFailedBlock){
    
        // 1. 给所有的block赋值
        downLoadInfo = downLoadInfoBlk
        progressChange = progressBlk
        stateChange = downloadStateBlk
        successBlock = success
        failureBlock = failure
        
        // 2. 开始下载
        download(urlStr: urlStr)
    }
    
    /// 根据URL地址下载资源, 如果任务已经存在, 则执行继续动作
    func download(urlStr:String){
        
        if !FileManager.default.fileExists(atPath:downloadedFolder) {
           try! FileManager.default.createDirectory(atPath: downloadedFolder, withIntermediateDirectories: true, attributes: nil)
        }
        
        if !FileManager.default.fileExists(atPath:downloadingFolder) {
            try! FileManager.default.createDirectory(atPath: downloadingFolder, withIntermediateDirectories: true, attributes: nil)
        }
        
        let url = URL(string: urlStr)!
        
        //0.当前任务, 如果存在
        if self.dataTask != nil {
            if url == self.dataTask!.originalRequest?.url {
                 // 判断当前的状态, 如果是暂停状态
                if state == .pause{
                    
                    if session == nil {
                        tempSize = fileSize(filePath: downLoadingPath)
                        download(url: url, offset: tempSize)
                        return
                    }else {
                        
                        // 继续
                        resumeCurrentTask()
                        state = .downLoading
                        return
                    }
                }else if state == .downLoading {
                    return
                }
            }else{
                 cacelCurrentTask()
            }
        }
        
        // 两种: 1. 任务不存在, 2. 任务存在, 但是, 任务的Url地址 不同
        
       
        
        let fileName = url.lastPathComponent
        
        downLoadedPath = downloadedFolder + fileName
        print("downLoadedPath = \(downLoadedPath)")
        
        downLoadingPath = downloadingFolder + fileName
        
        //print("downLoadedPath = \(downLoadingPath)")
        
        // 1. 判断, url地址, 对应的资源, 是下载完毕,(下载完成的目录里面,存在这个文件)
        // 1.1 告诉外界, 下载完毕, 并且传递相关信息(本地的路径, 文件的大小)
        
        if dataTask != nil {
            if fileExists( filePath: downLoadedPath) && (fileSize(filePath: downLoadedPath) == Int(dataTask!.countOfBytesExpectedToReceive)) {
                print("该文件已经下载完毕")
                state = .pauseSuccess
                return
            }
        }
        
        // 2. 检测, 临时文件是否存在
        // 2.2 不存在: 从0字节开始请求资源
        if !fileExists(filePath: downLoadingPath){
            // 从0字节开始请求资源
            download(url: url, offset: 0)
            return
        }
        
        tempSize = fileSize(filePath: downLoadingPath)
        download(url: url, offset: tempSize)
    }
    
    /// 根据开始字节, 请求资源
    fileprivate func download(url:URL, offset:Int){
        
        var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 0)
        request.setValue("bytes=\(offset)-", forHTTPHeaderField: "Range")
       // print(request.allHTTPHeaderFields?["Range"])
        
        // session 分配的task, 默认情况, 挂起状态
        
        if session == nil {
            session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        }
        
        dataTask = session?.dataTask(with: request)
        resumeCurrentTask()
        state = .downLoading
    }
    
    /// 继续任务
    func resumeCurrentTask(){
        if dataTask != nil && state == .pause {
            dataTask?.resume()
            //state = .downLoading
            
            print("继续任务")
        }
    }
   
    /// 暂停任务
    func pauseCurrentTask(){
        
        if state == .downLoading {
        
//            UserDefaults.standard.set(tempSize, forKey: md5Key)
//            UserDefaults.standard.synchronize()
          
            
            state = .pause
            dataTask?.suspend()
            print("暂停任务")
        }
    }
    
    
    /// 取消当前任务
    private func cacelCurrentTask(){
        state = .pause
        
        session?.invalidateAndCancel()
        session = nil
        
        print("取消当前任务")
    }
    
    // 取消任务, 并清理资源
    func cacelAndClean(){
        
        cacelCurrentTask()
        
        writeHandle?.closeFile()
        writeHandle = nil
        
        removFile(filePath: downLoadingPath)
        
        print("取消任务, 并清理资源")
    }
    
}

// MARK: - delegate 

extension ZDownLoader {
    
    /**
     第一次接受到相应的时候调用(响应头, 并没有具体的资源内容)
     通过这个方法, 里面, 系统提供的回调代码块, 可以控制, 是继续请求, 还是取消本次请求
     
     @param session 会话
     @param dataTask 任务
     @param response 响应头信息
     @param completionHandler 系统回调代码块, 通过它可以控制是否继续接收数据
     */
    @objc(URLSession:dataTask:didReceiveResponse:completionHandler:) func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        // 取资源总大小
        // 1. 从  Content-Length 取出来
        // 2. 如果 Content-Range 有, 应该从Content-Range里面获取
        

        totalSize = fileSize(filePath: downLoadingPath) + Int(dataTask.countOfBytesExpectedToReceive)
        
        if downLoadInfo != nil {
            downLoadInfo!(totalSize)
        }
        
         // 比对本地大小, 和 总大小
        if tempSize == totalSize{
            
            // 1. 移动到下载完成文件夹
            moveFile(fromPath: downLoadingPath, toPath: downLoadedPath)
            // 2. 取消本次请求
            completionHandler(URLSession.ResponseDisposition.cancel)
            // 3. 修改状态
            state = .pauseSuccess
            
            return
        }
        
        if tempSize > totalSize {
            // 1. 删除临时缓存
            removFile(filePath: downLoadingPath)
            // 2. 取消请求
            completionHandler(URLSession.ResponseDisposition.cancel)
            // 3. 从0 开始下载
            download(urlStr: response.url!.absoluteString)
            
            // MARK: - response.url!.absoluteString
            
            return
        }
        
        state = .downLoading
        
        // 继续接受数据
        // 确定开始下载数据
//        outputStream = OutputStream(toFileAtPath: downLoadingPath, append: true)
//        outputStream?.open()
        
        if !FileManager.default.fileExists(atPath: downLoadingPath) {
            FileManager.default.createFile(atPath: downLoadingPath, contents: nil, attributes: nil)
        }
        
        writeHandle = FileHandle(forWritingAtPath: downLoadingPath)
    
        writeHandle?.seekToEndOfFile()
        
        completionHandler(URLSession.ResponseDisposition.allow)
        
    }
    
    /**
     当用户确定, 继续接受数据的时候调用
     
     @param session 会话
     @param dataTask 任务
     @param data 接受到的一段数据
     */
    @objc(URLSession:dataTask:didReceiveData:) func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        // 这就是当前已经下载的大小
        tempSize += data.count
        
        progress = Float(tempSize) / Float(totalSize)
//        progress = Float(dataTask.countOfBytesReceived) / Float(dataTask.countOfBytesExpectedToReceive)
        
        // 往输出流中写入数据
        
//        outputStream?.write((data as! UnsafePointer<UInt8>), maxLength: data.count)
        writeHandle?.write(data)
        
        print("在接收后续数据")
    
    }
    
    /**
     请求完成时候调用
     请求完成的时候调用( != 请求成功/失败)
     @param session 会话
     @param task 任务
     @param error 错误
     */
    @objc(URLSession:task:didCompleteWithError:) func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil {
            moveFile(fromPath: downLoadingPath, toPath: downLoadedPath)
            state = .pauseSuccess
        }else {
            
            print(error?.localizedDescription)
            
            
            /*
             // 取消,  断网
             // 999 != 999
             if (-999 == error.code) {
             self.state = DownLoadStatePause;
             }else {
             self.state = DownLoadStatePauseFailed;
             }
             
             po error!
             Error Domain=NSURLErrorDomain Code=-999 "cancelled" UserInfo={NSErrorFailingURLKey=http://free2.macx.cn:8281/tools/photo/SnapNDragPro418.dmg, NSLocalizedDescription=cancelled, NSErrorFailingURLStringKey=http://free2.macx.cn:8281/tools/photo/SnapNDragPro418.dmg
             */
            if error!.localizedDescription == "cancelled"{
                state = .pause
            }else {
                state = .pauseFailed
                if failureBlock != nil{
                    failureBlock!(error!)
                }
            }
            
            /*
             error!
             Error Domain=NSURLErrorDomain Code=-1005 "The network connection was lost." UserInfo={NSUnderlyingError=0x60000005fa70 {Error Domain=kCFErrorDomainCFNetwork Code=-1005 "(null)" UserInfo={NSErrorPeerAddressKey=<CFData 0x600000285f50 [0x106307c70]>{length = 16, capacity = 16, bytes = 0x100220597912e75d0000000000000000}, _kCFStreamErrorCodeKey=57, _kCFStreamErrorDomainKey=1}}, NSErrorFailingURLStringKey=http://free2.macx.cn:8281/tools/photo/Sip44.dmg, NSErrorFailingURLKey=http://free2.macx.cn:8281/tools/photo/Sip44.dmg, _kCFStreamErrorDomainKey=1, _kCFStreamErrorCodeKey=57, NSLocalizedDescription=The network connection was lost.}
             */
        }
        
//        outputStream?.close()
        writeHandle?.closeFile()
        writeHandle = nil
    }
    
}





func cachePath()->String{
    let arr = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
    
    return arr.first!
}



