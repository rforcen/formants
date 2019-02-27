//
//  ViewController.swift
//  formants_iOS
//
//  Created by asd on 13/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var radialGraph: RadSpecDraw!
    @IBOutlet weak var freqRespGraph: FreqRespDraw!
    
    @IBOutlet var viewTap: UITapGestureRecognizer!
    
    @IBAction func onViewTap(_ sender: Any) {
        resetFFT()
        global.audioIn.switchRecording()
    }
    @IBAction func onStart(_ sender: Any) {
        resetFFT()
        global.audioIn.startRecording();
    }
    @IBAction func onStop(_ sender: Any) {
        global.audioIn.stopRecording();
    }
    
    
    func resetFFT() {
        for i in 0..<global.sumFFT.count { global.sumFFT[i]=0 }
    }
    
    func objC_AudioIn() {
        global.wavename = String(format: "Microphone @%d samps/sec", Global.sampleRate)
        global.audioIn=AudioIn.initWithnChan(Int32(Global.nChannels), sampRate: Int32(Global.sampleRate))
        
        global.audioIn.recordHandler { // recording handler
            _audioIn in
            
            let pnt=_audioIn?.getRecording()! // get recording in recBuffer[Float]
            let recBuffer:[Float] = global.pointer2array(pnt!.data, Int(pnt!.n))
            
            global.genFormants(signal: recBuffer, rate: Double(Global.sampleRate), frameCount: recBuffer.count)
            
            DispatchQueue.main.async { // update graphs
                self.radialGraph.setNeedsDisplay()
                self.freqRespGraph.setNeedsDisplay()
            }
        }
        
        global.audioIn.startRecording()
    }
    
  
    
    func swift_MicRecorder() {
        global.wavename = String(format: "Microphone @%d samps/sec", Global.sampleRate)
        global.micRecorder = MicRecorder(nChannels: Global.nChannels, sampleRate: Global.sampleRate)
        
        global.micRecorder.setHandle { recording in
            
            if recording.count > 0 {
                global.genFormants(signal: recording, rate: Double(Global.sampleRate), frameCount: recording.count)
                
                DispatchQueue.main.async { // update graphs
                    self.radialGraph.setNeedsDisplay()
                    self.freqRespGraph.setNeedsDisplay()
                }
            }
        }
        global.micRecorder.startRecording()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        swift_MicRecorder()
        objC_AudioIn()
    }
}

