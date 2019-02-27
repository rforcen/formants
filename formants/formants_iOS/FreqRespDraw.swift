//
//  FreqRespDraw.swift
//  formants_iOS
//
//  Created by asd on 13/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//

import UIKit

class FreqRespDraw: UIView {
    
    override func draw(_ rect: CGRect) {
        let gr=GraphLine(layer: layer, bounds : bounds)
        
        if( global.yf.count != 0 ) {
            gr.title(title: global.wavename)
            gr.draw(y: global.yf)
            gr.drawAxis(x: global.xf, xticks: 10, xlabel:"Hz", y: global.yf.sorted(), yticks: 10, ylabel:"db")
            
            for i in 0..<min(5,global.forms.n) {
                gr.mark(ix: global.xf.binarySearch{ $0 < global.hz[i] }, y: global.yf, label: String(format: "%.1f hz (%.0f db)", global.hz[i], global.pwr[i]))
            }
        }
    }
    
}
