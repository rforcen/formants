//
//  FreqRespGraph.swift
//  formants
//
//  Created by asd on 10/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//

import Cocoa

class FreqRespGraph: NSView {
    
    override func draw(_ dirtyRect: Rect) {
        super.draw(dirtyRect)
        
        if( global.yf.count == 0 ) { return }
        
        let gr=GraphLine(layer: layer!, bounds : bounds)
        gr.title(title: global.wavename)
        gr.draw(y: global.yf)
        gr.drawAxis(x: global.xf, xticks: 10, xlabel:"Hz", y: global.yf.sorted(), yticks: 10, ylabel:"db")
        
        for i in 0..<global.forms.n {
            gr.mark(ix: global.xf.binarySearch{ $0 < global.hz[i] }, y: global.yf, label: String(format: "%.1f hz (%.0f db)", global.hz[i], global.pwr[i]))
        }
    }
    
}
