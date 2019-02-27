//
//  GraphLine.swift
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

class GraphLine : BaseGraph {
    let x0:CGFloat=30, y0:CGFloat=30, pntW:CGFloat=5
    
    override init(layer: CALayer, bounds: Rect) {
        super.init(layer: layer, bounds: bounds)
        
        lineColor=Color.blue; pointColor=Color.red;
        textColor=Color.magenta; dashColor=Color.brown;
        bgColor=Color.white
        
        removeSubLayers()
        clearBG(color: bgColor)
    }
    
    func Point(x: CGFloat, y:CGFloat) -> CGPoint {
        #if os(OSX)
        return CGPoint(x:x, y:y)
        #elseif os(iOS)
        return CGPoint(x:x, y:y)
        #endif
    }
   
    func draw(y:[Double]) {
        if (y.count==0) { return }
        
        let mx=CGFloat(y.max()!), mi=CGFloat(y.min()!), diff=abs(mx-mi), n=CGFloat(y.count)
        
        if mx==0 || diff==0 || n==0 { return }
        
        let scx=(w-2*x0)/n, scy=(h-2*y0)/diff
        
        let path=CGMutablePath()
        path.move(to: Point(x:x0, y:y0))
        
        for i in 0..<y.count {
            path.addLine(to: Point(x:x0 + CGFloat(i) * scx, y: y0 + scy * (CGFloat(y[i])-mi)))
        }
        
        path.addLine(to: Point(x:w-x0, y:y0))
        path.addLine(to: Point(x:x0, y:y0))
        
        addPath(path: path, strokeColor: lineColor, fillColor: Color.clear)
    }
    
    func drawAxis(x:[Double], xticks: CGFloat, xlabel:String, y:[Double], yticks: CGFloat, ylabel:String) {
        if (y.count==0) { return }
        
        let path=CGMutablePath()
        let xg=Array(stride(from:x.min()!, to:x.max()!, by:Double((x.max()!-x.min()!)/Double(xticks)))),
            yg=Array(stride(from:y.min()!, to:y.max()!, by:Double((y.max()!-y.min()!)/Double(xticks))))
        
        for i in 0...Int(xticks) {
            let xc=CGFloat(i)*(w-x0*2)/xticks+x0
            path.move(to: Point(x: xc, y:y0-3))
            path.addLine(to: Point(x: xc, y:y0+3))
            
            let text=String(format: "%.1f ", xg[i<xg.count ? i:xg.count-1]) + (i<xg.count ? "":xlabel)
            
            layer.addSublayer(genTextLayer(text: text,
                                           point: Point(x:xc-getTextSize(text: text, font: fontAxis).width/2,
                                                          y: y0-fontAxisSize*2 ),
                                           font: fontAxis))
        }
        for i in 0...Int(yticks) {
            let yc=CGFloat(i)*(h-y0*2)/yticks+y0
            path.move(to: Point(x: x0-3, y:yc))
            path.addLine(to: Point(x: x0+3, y:yc))
            
            let text=String(format: "%.1f ", yg[i<yg.count ? i:yg.count-1]) + (i<yg.count ? "":ylabel)
            
            layer.addSublayer(genTextLayer(text: text,
                                           point: Point(x:x0-getTextSize(text: text, font: fontAxis).width-3,
                                                          y: yc-fontAxisSize),
                                           font: fontAxis))
        }
        addPath(path: path, strokeColor: lineColor, fillColor: Color.clear)
    }
    
    func mark(ix:Int, y:[Double], label:String) {
        let pw2=pntW/2
        let mx=CGFloat(y.max()!), mi=CGFloat(y.min()!), diff=abs(mx-mi), n=CGFloat(y.count)
        let scx=(w-2*x0)/n
        let scy=(h-2*y0)/diff
        
        let pnt=Point(x:x0 + CGFloat(ix) * scx - pw2, y: y0 + scy * (CGFloat(y[ix])-mi) - pw2)
        
        func drawPoint() {
            let path=CGMutablePath() // point
            path.addEllipse(in: CGRect(origin: pnt, size: CGSize(width: 5, height: 5)))
            addPath(path: path, strokeColor: lineColor, fillColor: pointColor)
        }
        func drawDashedAxis() {
            let pathDash=CGMutablePath() // dashed vert/horz lines
            let p0=Point(x:x0 + CGFloat(ix) * scx, y: y0 + scy * (CGFloat(y[ix])-mi))
            pathDash.move(to: p0)
            pathDash.addLine(to: Point(x:p0.x, y:y0))
            pathDash.move(to: p0)
            pathDash.addLine(to: Point(x:x0, y:p0.y))
            addPath(path: pathDash.copy(dashingWithPhase: 0, lengths: [2,3]) as! CGMutablePath, strokeColor: dashColor, fillColor: Color.clear)
        }
        func drawLabel() {
            layer.addSublayer(genTextLayer(text: label, point:Point(x:pnt.x+pntW, y:pnt.y+pw2), font: font))
        }
        
        drawPoint()
        drawLabel()
        drawDashedAxis()
    }
    
    func title(title: String)  {
        layer.addSublayer(genTextLayer(text: title, point:Point(x:bounds.maxX/2, y:bounds.maxY - y0/2), font: font))
    }
}


