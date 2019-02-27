//
//  AudioCaptureSession.swift
//  formants
//
//  Created by asd on 18/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//

import AVFoundation

class AudioCaptureSession: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    let settings = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVNumberOfChannelsKey : 1,
        AVSampleRateKey : 22050]
    
    let captureSession=AVCaptureSession()
    var handle : ((_ recording : [Float]) -> Void)? = nil
    
    override init() {
        super.init()
       
        _=AVCaptureDevice.authorizationStatus(for: .audio)
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                let queue = DispatchQueue(label: "AudioSessionQueue", attributes: [])
                let captureDevice = AVCaptureDevice.default( for: .audio)
                var audioInput : AVCaptureDeviceInput? = nil
                var audioOutput : AVCaptureAudioDataOutput? = nil
                
                do {
                    try captureDevice?.lockForConfiguration()
                    audioInput = try AVCaptureDeviceInput(device: captureDevice!)
                    captureDevice?.unlockForConfiguration()
                    audioOutput = AVCaptureAudioDataOutput()
                    audioOutput?.setSampleBufferDelegate(self, queue: queue)
                    audioOutput?.audioSettings = self.settings
                } catch {
                    print("Capture devices could not be set")
                    print(error.localizedDescription)
                }
                
                if audioInput != nil && audioOutput != nil {
                    self.captureSession.beginConfiguration()
                    if (self.self.captureSession.canAddInput(audioInput!)) {
                        self.captureSession.addInput(audioInput!)
                    } else {
                        print("cannot add input")
                    }
                    if (self.self.captureSession.canAddOutput(audioOutput!)) {
                        self.captureSession.addOutput(audioOutput!)
                    } else {
                        print("cannot add output")
                    }
                    self.captureSession.commitConfiguration()
                    
                    print("Starting capture session")
                    self.captureSession.startRunning()
                }
            }
        }
        
        
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        
        var audioBufferList = AudioBufferList()
        var blockBuffer : CMBlockBuffer?
        
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, bufferListSizeNeededOut: nil, bufferListOut: &audioBufferList, bufferListSize: MemoryLayout<AudioBufferList>.size, blockBufferAllocator: nil, blockBufferMemoryAllocator: nil, flags: 0, blockBufferOut: &blockBuffer)
        
        let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer)!)!.pointee
        
        let buffers = UnsafeBufferPointer<AudioBuffer>(start: &audioBufferList.mBuffers, count: Int(audioBufferList.mNumberBuffers))
        
        let data  =  audioBufferList.mBuffers.mData
        
        let pointer = data?.assumingMemoryBound(to: Float.self)
        let numSamplesInBuffer = CMSampleBufferGetNumSamples(sampleBuffer)
        
        let floatPointer = data?.bindMemory(to: Float.self, capacity: numSamplesInBuffer)
        let floatBuffer = UnsafeBufferPointer(start: floatPointer, count: numSamplesInBuffer)
        let outputArray = Array(floatBuffer)
        if handle != nil {
            handle!(outputArray)
        }
    }
    
    
    func setHandle( _ handle : @escaping ([Float]) -> Void ) {
        self.handle = handle
    }
    
}
