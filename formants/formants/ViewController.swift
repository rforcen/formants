//
//  ViewController.swift
//  formants
//
//  Created by asd on 05/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController {
    
    @IBOutlet weak var freqRespGraph: FreqRespGraph!
    @IBOutlet weak var radialGraph: RadSpecDraw!
    
    func objC_AudioIn() {
        global.wavename = String(format: "Microphone @%d samps/sec", Global.sampleRate)
        global.audioIn=AudioIn.initWithnChan(Int32(Global.nChannels), sampRate: Int32(Global.sampleRate))
        
        global.audioIn.recordHandler { // recording handler
            _audioIn in
            
            let pnt=_audioIn?.getRecording()! // get recording in recBuffer[Float]
            let recBuffer:[Float] = global.pointer2array(pnt!.data, Int(pnt!.n))
            
            if recBuffer.count > 0 {
                global.genFormants(signal: recBuffer, rate: Double(Global.sampleRate), frameCount: recBuffer.count)
                
                DispatchQueue.main.async { // update graphs
                    self.radialGraph.needsDisplay=true
                    self.freqRespGraph.needsDisplay=true
                }
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
                    self.radialGraph.needsDisplay=true
                    self.freqRespGraph.needsDisplay=true
                }
            }
        }
        global.micRecorder.startRecording()
    }
    
    var capSess:AudioCaptureSession?=nil
    func captureSess() {
        capSess = AudioCaptureSession()
        capSess!.setHandle { recording in
            
            if recording.count > 0 {
                global.genFormants(signal: recording, rate: Double(Global.sampleRate), frameCount: recording.count)
                
                DispatchQueue.main.async { // update graphs
                    self.radialGraph.needsDisplay=true
                    self.freqRespGraph.needsDisplay=true
                }
            }
        }
    }
    
    override func viewDidLoad()  {
        
        func wavFormants(name:String) {
            global.wavename=name;
            let audio = global.loadAudioFile(audioURL: Bundle.main.url(forResource: name, withExtension: "wav")!)
            global.genFormants(signal: audio.signal, rate: audio.rate, frameCount: audio.frameCount)
        }
        
        super.viewDidLoad()
        
                swift_MicRecorder()
//        objC_AudioIn()
//                captureSess()
    }
}

