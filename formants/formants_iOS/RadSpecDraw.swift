//
//  RadSpecDraw.swift
//  formants_iOS
//
//  Created by asd on 13/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//

import UIKit

class RadSpecDraw: UIView {
    override func draw(_ dirtyRect: Rect) {
        super.draw(dirtyRect)
        
        let re=RadialSpec(layer: layer, bounds: bounds)
        
        if(global.sumFFT.count != 0 && global.xf.count != 0) {
            re.drawValues(yv: global.sumFFT)
            re.drawAxis(x: global.xf, xticks: 24)
        }
    }
}
