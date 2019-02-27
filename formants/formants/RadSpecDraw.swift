//
//  RadSpecDraw.swift
//  formants
//
//  Created by asd on 12/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//

import Cocoa

class RadSpecDraw: NSView {

    override func draw(_ dirtyRect: Rect) {
        super.draw(dirtyRect)

        let re=RadialSpec(layer: layer!, bounds: bounds)
        
        re.drawValues(yv: global.fft)
        re.drawAxis(x: global.xf, xticks: 24)
       
    }
    
}
