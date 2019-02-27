//
//  RadialSpec.swift
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


class Scaler {
    var _max:Double!=0, _min:Double!=0, diff:Double!=0
    
    init(x:[Double]) {
        _max=x.max()
        _min=x.min()
        diff=_max-_min
        if (diff==0) { diff=1 }
    }
    
    func scaled(xv:Double) -> Double{
        return (xv-_min)/diff
    }
}


class RadialSpec : BaseGraph {
    
    var r:CGFloat=0, d:CGFloat=0, rect=Rect()
    // scaled circle
    var sf=CGFloat(0.8), // axis scale factor
    rs=CGFloat(0), xc=CGFloat(0), yc=CGFloat(0),
    tickSize=CGFloat(1.05)
    
    override init(layer: CALayer, bounds: Rect) {
        super.init(layer: layer, bounds: bounds)
        
        d = min(w,h)
        r = d*2
        xc = w/2; yc=h/2
        rs = min(w*sf, h*sf)/2
        
     
        
        removeSubLayers()
        clearBG(color: bgColor)
    }
    
    func pointInSector(i:Int, ns:Int, ts:CGFloat) -> CGPoint { // in (xc,yc) abd rs radio
        let x=xc + rs * sin( (CGFloat(i)/CGFloat(ns)) * CGFloat.pi * 2 ) * ts,
            y=yc + rs * cos( (CGFloat(i)/CGFloat(ns)) * CGFloat.pi * 2 ) * ts
        return CGPoint(x: x, y: y)
    }
    
    func drawAxis(x:[Double], xticks:Int)  {
        func frameCircle() { // scale circle to 'sf' -> xs,ys
            func scaledRect(scale : CGFloat) -> CGRect {
                let ws = w*scale, hs = h*scale,
                ds = min(ws,hs),
                xs = (w-ds)/2, ys = (h-ds)/2
                
                return Rect(origin: CGPoint(x:xs, y:ys), size: CGSize(width: ds, height: ds))
            }
            
            let path=CGMutablePath()
            path.addEllipse(in: scaledRect(scale: sf))
            path.addEllipse(in: scaledRect(scale: sf*tickSize))
            addPath(path: path, strokeColor: lineColor, fillColor: clearColor)
        }
        
        func drawTicks() {
            let path=CGMutablePath(), pathst=CGMutablePath()
            
            for i in 0..<xticks {
                let pnt=pointInSector(i: i, ns: xticks, ts: 1),
                pntto=pointInSector(i: i, ns: xticks, ts: tickSize)
                path.move(to: pnt)
                path.addLine(to: pntto)
            }
            
            let xt10 = xticks*10, ts2=(1+tickSize)/2, ts3=(2+tickSize)/3
            
            for i in 0..<xt10 {
                let ts=(i & 1 == 0) ? ts2 : ts3
                
                let pnt=pointInSector(i: i, ns: xt10, ts: 1),
                pntto=pointInSector(i: i, ns: xt10, ts: ts)
                pathst.move(to: pnt)
                pathst.addLine(to: pntto)
            }
            addPath(path: pathst, strokeColor: Color.cyan, fillColor: clearColor)
            addPath(path: path,   strokeColor: dashColor,    fillColor: clearColor)
        }
        
        func drawLabels() {
            if(x.count==0) { return }
            
            let xg=Array(stride(from:x.min()!, to:x.max()!, by:Double((x.max()!-x.min()!)/Double(xticks))))
            
            for i in 0..<xticks {
                let x=xc + rs*sin( (CGFloat(i)/CGFloat(xticks)) * CGFloat.pi * 2 )*tickSize,
                y=yc + rs*cos( (CGFloat(i)/CGFloat(xticks)) * CGFloat.pi * 2 )*tickSize
                
                let text=String(format: "%.0f", xg[i])
                let ts=getTextSize(text: text, font: fontAxis),
                tw=ts.width, th=ts.height
                var xi=CGFloat(0), yi=CGFloat(0)
                
                switch i {
                case 0..<xticks/16:              xi = -tw/2;     yi = 0
                case xticks/16..<7*xticks/16:    xi = 0;         yi = -th/2
                case 7*xticks/16..<9*xticks/16:  xi = -tw/2;     yi = -th
                case 9*xticks/16..<15*xticks/16: xi = -tw;       yi = -th/2
                case 15*xticks/16..<xticks:      xi = -tw/2;     yi = 0
                default: break
                }
                
                layer.addSublayer(genTextLayer(text: text,  point: CGPoint(x:x+xi, y: y+yi), font: fontAxis))
            }
        }
        
        frameCircle()
        drawTicks()
        drawLabels()
    }
    
    func drawValues(yv:[Double]) {
        func pointr(rad : CGFloat, sector : Double) -> CGPoint {
            let x=xc + rad*sin( CGFloat(sector) * CGFloat.pi * 2 ),
                y=yc + rad*cos( CGFloat(sector) * CGFloat.pi * 2 )
            return CGPoint(x: x, y: y)
        }
        
        if yv.count==0 { return }
        
        let mx=yv.max()!, mi=yv.min()!, diff=mx-mi
        
        if mx==0 || diff==0 { return }
        
        let paths=[CGMutablePath(),CGMutablePath(),CGMutablePath(),CGMutablePath()]
        let colors=[Color.cyan, Color.orange, Color.red, Color.yellow]
        let np=paths.count
        var profile=[CGPoint]()
        
        for i in 0..<yv.count {
            let val = (yv[i]-mi)/diff
            var ip = Int(val * Double(np))
            if (ip>=np) { ip -= 1 }
            
            let pf=pointr(rad: rs,                    sector: Double(i)/Double(yv.count)),
                pt=pointr(rad: rs * CGFloat(1 - val), sector: Double(i+1)/Double(yv.count))
            
            paths[ip].move(to: pf)
            paths[ip].addLine(to: pt)
            
            profile.append(pt)
        }
        
        let path=CGMutablePath() // draw profile
        path.move(to: profile[0])
        for p in profile {
            path.addLine(to: p)
        }
        addPath(path: path, strokeColor: Color.cyan, fillColor: clearColor)
        
        for i in 0..<np { // draw colored lines
            addPath(path: paths[i], strokeColor: colors[i], fillColor: clearColor)
        }
    }
}

