//
//  DCircleProgress.swift
//  ZBXMobile
//
//  Created by wzboy on 17/4/18.
//  Copyright © 2017年 zbx. All rights reserved.
//

import UIKit

open class DCircleProgress: UIView {
    

    open var lineWidth : CGFloat = 10.0
    open var circleFontSize : CGFloat = 13
    open var circleColor : UIColor = UIColor.orange
    
    open var progressValue : CGFloat = 0{
        didSet{
            cLabel.text = "\(Int(progressValue * 100))%"
            
            setNeedsDisplay()
        }
    }
    

    
    open var progressText : String? {
        didSet{
            if progressText != nil {
                cLabel.text = progressText
                setNeedsDisplay()
            }
        }
    }
    
    open var progress : Progress?{
        didSet{
            if progress != nil {
                progressValue = CGFloat(progress!.completedUnitCount)/CGFloat(progress!.totalUnitCount)
            }
        }
    }
    
    fileprivate var cLabel = UILabel()

    override public init(frame:CGRect){
        super.init(frame: frame)
    
        backgroundColor = UIColor.clear
    }
    
    open func setupcLabel(){
        addSubview(cLabel)
        cLabel.font = UIFont.boldSystemFont(ofSize: circleFontSize)
        cLabel.textColor = circleColor
        cLabel.textAlignment = .center
        cLabel.fill_dd(referView: self)
    }
    
    convenience public init(fontSize:CGFloat, lineWidth:CGFloat = 10,color:UIColor = UIColor.orange){
        
        self.init()
        
        circleFontSize = fontSize == 0 ? self.circleFontSize : fontSize
        self.lineWidth = lineWidth
        self.circleColor = color
        setupcLabel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override open func draw(_ rect: CGRect) {
        
        //路径
        let path = UIBezierPath()
        //线宽
        path.lineWidth = lineWidth
        //颜色
        circleColor.set()
        //拐角
        path.lineCapStyle = CGLineCap.round
        path.lineJoinStyle = CGLineJoin.round
        //半径
        let radius = ( CGFloat.minimum(rect.size.width, rect.size.height) - lineWidth) * 0.5
        
        //画弧（参数：中心、半径、起始角度(3点钟方向为0)、结束角度、是否顺时针）
        path.addArc(withCenter: CGPoint(x:rect.size.width * 0.5, y: rect.size.height * 0.5), radius: radius, startAngle: CGFloat.pi * 1.5, endAngle: CGFloat.pi * 1.5 + CGFloat.pi * 2 * progressValue, clockwise: true)
        
        //描边
        path.stroke()
    }
    

}
