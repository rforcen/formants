//
//  GraphView.swift
//  TestWaves
//
//  Created by asd on 30/12/2018.
//  Copyright © 2018 voicesync. All rights reserved.
//

import Cocoa


class GraphView: NSView {
    @IBInspectable var graphValue: String? = ""
    
    var graphCol: Int = 1
    
    override func draw(_ dirtyRect: NSRect) {

        func RectinLayer(rect: NSRect, color: NSColor) -> CAShapeLayer {
            let path=CGMutablePath()
            path.addRect(rect)
            
            let sh = CAShapeLayer()
            sh.fillColor = color.cgColor
            sh.path = path
            return sh
        }
        func clearBG(color: NSColor) {
            layer!.addSublayer(RectinLayer(rect: bounds, color: color))
        }
        func removeSubLayers() {
            self.layer!.sublayers?.forEach { $0.removeFromSuperlayer() }
        }
        func drawBars() {
            func genTextLayer(value: String, rect: NSRect) -> CATextLayer {
                let textLayer=CATextLayer()
                textLayer.string=value
                textLayer.font=NSFont(name:"Trebuchet MS", size:10)
                textLayer.fontSize=12
                textLayer.frame=NSRect(x: rect.minX, y: 200, width: rect.width, height: rect.height)
                textLayer.position=NSPoint(x: rect.midX+2, y: rect.midY)
                textLayer.foregroundColor=colors[graphCol+1].cgColor
                
                return textLayer
            }
            
            let w=bounds.width, h=bounds.height, n=waves.count
            
            for i in 0..<n {
                let wave=waves[i]
                var value:Float=0, fmtValue:String=""
                
                switch graphValue {
                case "amp"  : graphCol=0; fmtValue=String(format: "%.0f",wave.amp*100);  value = wave.amp
                case "freq" : graphCol=1; fmtValue=String(format: "%.1f",wave.hz);  value = (wave.hz - minFreq) / (maxFreq-minFreq)
                case "phase": graphCol=2; fmtValue=String(format: "%.0f",wave.phase*360/(Float.pi*2)); value = wave.phase/(Float.pi*2)
                    
                default: break
                }
              
                let barv=NSRect(
                    x: CGFloat(n-1-i)*w/CGFloat(n), y: 0,
                    width: w/CGFloat(n), height: h * CGFloat(value)),
                barh=NSRect(
                    x: 0, y: CGFloat(n-1-i)*h/CGFloat(n),
                    width: w * CGFloat(value), height: h / CGFloat(n))
                
                layer!.addSublayer(RectinLayer(rect: barh, color: colors[graphCol]))
                layer!.addSublayer(genTextLayer(value: fmtValue, rect: barh))
            }
        }
        
        super.draw(dirtyRect)

        removeSubLayers()
        clearBG(color: NSColor.white)
        drawBars()
        
    }
    
}
