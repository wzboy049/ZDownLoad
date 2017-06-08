//
//  ZFileTool.swift
//  SwiftDownLoader
//
//  Created by wzboy on 17/3/16.
//  Copyright © 2017年 zbx. All rights reserved.
//

import UIKit

class ZFileTool: NSObject {

}

func fileExists(filePath:String)->Bool{
    if filePath.characters.count == 0 {
        return false
    }
    return FileManager.default.fileExists(atPath: filePath)
}


func fileSize(filePath:String)->Int{
    if !fileExists(filePath: filePath) {
        return 0
    }
    
    do {
        let fileInfo = try FileManager.default.attributesOfItem(atPath: filePath)
        return fileInfo[FileAttributeKey.size] as! Int
    } catch {
        dump(error)
        return 0
    }
}

func moveFile(fromPath:String, toPath:String){
    
    if fileSize(filePath: fromPath) <= 0 {
        return
    }
    
    do {
        try FileManager.default.moveItem(atPath: fromPath, toPath: toPath)
    } catch {
        dump(error)
    }
}

func removFile(filePath:String){
    do {
        try FileManager.default.removeItem(atPath: filePath)
    } catch {
        dump(error)
    }
}



