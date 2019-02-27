//
//  BaseGraph.swift
//  formants
//
//  Created by asd on 12/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//

#if os(OSX)
import Cocoa
#elseif os(iOS)
import UIKit
#endif


class BaseGraph {
    // colors
    var lineColor=Color.blue, pointColor=Color.red,
    textColor=Color.white, dashColor=Color.yellow, bgColor=Color.black, clearColor=Color.clear
    
    var fontSize:CGFloat=10, fontAxisSize:CGFloat=7
    var layer = CALayer(), bounds=Rect()
    var w:CGFloat=0, h:CGFloat=0
    var font=Font(), fontAxis=Font()
    
    init(layer: CALayer, bounds: Rect) {
        self.layer=layer
        self.bounds=bounds
        w=bounds.width
        h=bounds.height
        font=Font(name:"Trebuchet MS", size:fontSize)!
        fontAxis=Font(name:"Trebuchet MS", size:fontAxisSize)!
    }
    
    func rectinLayer(rect: Rect, color: Color) -> CAShapeLayer {
        let path=CGMutablePath()
        path.addRect(rect)
        
        let sh = CAShapeLayer()
        sh.fillColor = color.cgColor
        sh.path = path
        return sh
    }
    func clearBG(color: Color) {
        layer.addSublayer(rectinLayer(rect: bounds, color: color))
    }
    func removeSubLayers() {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
    func addPath(path:CGMutablePath, strokeColor:Color, fillColor:Color) {
        let sh = CAShapeLayer()
        
        sh.strokeColor=strokeColor.cgColor
        sh.fillColor=fillColor.cgColor
        sh.lineWidth=0.5
        
        sh.path = path
        
        layer.addSublayer(sh)
    }
    func getTextSize(text: String, font: Font) -> CGSize {
        return (text as NSString).size(withAttributes: [NSAttributedString.Key.font: font] as [NSAttributedString.Key : Any])
    }
    func genTextLayer(text: String, point: CGPoint, font: Font) -> CATextLayer {
        
        let size = getTextSize(text: text, font: font)
        let rect = Rect(origin: point, size: size)
        
        let textLayer=CATextLayer()
        textLayer.string=text
        textLayer.font=font
        textLayer.fontSize=font.pointSize
        textLayer.frame=rect
        textLayer.position=CGPoint(x: rect.midX, y: rect.midY)
        textLayer.foregroundColor=textColor.cgColor
        #if os(OSX)
        textLayer.contentsScale = (NSScreen.main?.backingScaleFactor)! // avoid blurry text
        #elseif os(iOS)
        textLayer.contentsScale = UIScreen.main.scale // avoid blurry text
        #endif
        return textLayer
    }
    
}
