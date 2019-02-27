//
//  Global.swift
//  formants
//
//  Created by asd on 10/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//


import AVFoundation

// os dep. conditional compilation
#if os(OSX)
#elseif os(iOS)
#endif


#if os(OSX)
import Cocoa

typealias Real = CGFloat
typealias Color = NSColor
typealias Rect = NSRect
typealias Font = NSFont
#elseif os(iOS)

import UIKit

typealias Real = Float
typealias Color = UIColor
typealias Rect = CGRect
typealias Font = UIFont
#endif


class Global {
    // global signal parameters
    var forms = Formants()
    var hz=[Double](), pwr=[Double](), bw=[Double](), xf=[Double](), yf=[Double](), fft=[Double](), sumFFT=[Double]()
    var wavename:String=""
    
    // Audio recording
    var audioIn = AudioIn()
    var recording=[Float]()
    
    static let sampleRate=22050
    static let nChannels=1
    
    var micRecorder = MicRecorder() // nChannels: Global.nChannels, sampleRate: Global.sampleRate)
    
    func loadAudioFile(audioURL: URL) -> (signal: [Float], rate: Double, frameCount: Int) {
        let file = try! AVAudioFile(forReading: audioURL)
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
        let buf = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: UInt32(file.length))
        try! file.read(into: buf!) // You probably want better error handling
        let floatArray = Array(UnsafeBufferPointer(start: buf!.floatChannelData![0], count:Int(buf!.frameLength)))
        return (signal: floatArray, rate: file.fileFormat.sampleRate, frameCount: Int(file.length))
    }
    
    func genFormants(signal: [Float], rate: Double, frameCount: Int) {
        forms = generateFormants(Int(rate), frameCount, UnsafeMutablePointer<Float>(mutating: signal))
        
        hz=pointer2array(forms.hz, forms.n)
        pwr=pointer2array(forms.pwr, forms.n)
        bw=pointer2array(forms.bw, forms.n)
        
        xf=pointer2array(forms.xfr, forms.nfr)
        yf=pointer2array(forms.yfr, forms.nfr)
        
        fft=pointer2array(forms.fft, forms.nfft)
        
        if (sumFFT.count == 0) { sumFFT=fft }
        else {
            for i in 0..<min(fft.count, sumFFT.count) {
                sumFFT[i] += fft[i]
            }
        }
        releaseResources(); // once forms arrays are copied
    }
    
    func pointer2array(_ p : UnsafeMutablePointer<Double>, _ n : Int) -> [Double] {
        return Array<Double>(UnsafeBufferPointer(start: p, count: n))
    }
    
    func pointer2array(_ p : UnsafeMutablePointer<Float>, _ n : Int) -> [Float] {
        return Array<Float>(UnsafeBufferPointer(start: p, count: n))
    }
    
    
    static func checkSum(_ vd:[Float]) -> Float {
        var s:Float=0
        for d in vd {
            s+=d
        }
        return s
    }
    
    func wavFormants(name:String) {
        wavename=name;
        let audio = loadAudioFile(audioURL: Bundle.main.url(forResource: name, withExtension: "wav")!)
        genFormants(signal: audio.signal, rate: audio.rate, frameCount: audio.frameCount)
    }
}

let global=Global()


extension Collection {
    /// Finds such index N that predicate is true for all elements up to
    /// but not including the index N, and is false for all elements
    /// starting with index N.
    /// Behavior is undefined if there is no such N.
    // (0 ..< 778).binarySearch { $0 < 145 } // 145
    func binarySearch(predicate: (Iterator.Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high)/2)
            if predicate(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}
