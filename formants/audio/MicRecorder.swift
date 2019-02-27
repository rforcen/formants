//
//  MicRecorder.swift
//  formants
//
//  Created by asd on 17/01/2019.
//  Copyright © 2019 voicesync. All rights reserved.
//
/* Usage:
 
 enable Mic in project/target/capabilities
 
 let micRecorder = MicRecorder(nChannels: 1, sampleRate: 22050)
 func swift_MicRecorder() {
 
 micRecorder.setHandle { recording in
 
 global.genFormants(signal: recording, rate: Double(sampleRate), frameCount: recording.count)
 
 DispatchQueue.main.async { // update graphs
 self.radialGraph.setNeedsDisplay()
 self.freqRespGraph.setNeedsDisplay()
 }
 }
 micRecorder.start()
 }
 */

import AudioToolbox
import AVFoundation

class MicRecorder {
    static let recordSampleTime:Double=0.2
    var duration:Double=0
    
    var recording=[Float]() // recording samples buffer
    
    var osStat : OSStatus = 0
    internal struct RecordState {
        var format: AudioStreamBasicDescription
        var queue: UnsafeMutablePointer<AudioQueueRef?>
        var buffers: [AudioQueueBufferRef?]
        var file: AudioFileID?
        var currentPacket: Int64
        var isRecording: Bool
        var mySelf : MicRecorder
    }
    private var recordState: RecordState?
    private let kNumberBuffers = 2
    
    static let __callBack: AudioQueueInputCallback = { // call back handler
        (userData: UnsafeMutableRawPointer?,
        audioQueue: AudioQueueRef,
        bufferQueue: AudioQueueBufferRef,
        startTime: UnsafePointer<AudioTimeStamp>,
        packets: UInt32,
        packetDescription: UnsafePointer<AudioStreamPacketDescription>?) in
        
        
        // convert UnsafeMutableRawPointer -> [Float], np
        func ptr2floats(_ mem:UnsafeMutableRawPointer, _ np : Int) -> [Float] {
            let bTypedPtr : UnsafeMutablePointer<Float> = mem.bindMemory(to: Float.self, capacity: np)
            let floatBuffer = UnsafeBufferPointer(start: bTypedPtr, count: np)
            return Array(floatBuffer)
        }
        
        var recStat = unsafeBitCast(userData, to: UnsafeMutablePointer<RecordState>.self).pointee
        let localSelf = recStat.mySelf
        
        
        if recStat.isRecording && localSelf.handle != nil { // when recording call handler w/ recording samples
            localSelf.recording = ptr2floats(bufferQueue.pointee.mAudioData, Int(packets))
            localSelf.handle!(localSelf.recording)
        }
        
        recStat.currentPacket += Int64(packets)
        //        print("packet=", recStat.currentPacket)
        AudioQueueEnqueueBuffer(audioQueue, bufferQueue, 0, nil)
    }
    
    var handle : ((_ recording : [Float]) -> Void)? = nil
    
    func setHandle( _ handle : @escaping ([Float]) -> Void ) {
        self.handle = handle
    }
    
    var format: AudioFormatID {
        get { return recordState!.format.mFormatID }
    }
    
    var sampleRate: Float64 {
        get { return recordState!.format.mSampleRate }
    }
    
    var channelsPerFrame: UInt32 {
        get {   return recordState!.format.mChannelsPerFrame }
    }
    
    var bitsPerChannel: UInt32 {
        get {   return recordState!.format.mBitsPerChannel }
    }
    
    var bytesPerPacket: UInt32 {
        get { return recordState!.format.mBytesPerPacket  }
    }
    
    init() {}
    
    init(nChannels : Int, sampleRate: Int) {
        
        let sampleSize = MemoryLayout<Float32>.size // define audio format
        let audioDescription=AudioStreamBasicDescription(
            mSampleRate        : Float64(sampleRate),
            mFormatID          : kAudioFormatLinearPCM,
            mFormatFlags       : kAudioFormatFlagIsFloat,
            mBytesPerPacket    : UInt32(sampleSize * nChannels),
            mFramesPerPacket   : 1,
            mBytesPerFrame     : UInt32(nChannels * sampleSize),
            mChannelsPerFrame  : UInt32(nChannels),
            mBitsPerChannel    : UInt32(8 * sampleSize), //8 bits per byte
            mReserved          : 0
        )
        
        duration = (1 / audioDescription.mSampleRate) * Double(audioDescription.mFramesPerPacket)
        
        recordState = RecordState(format: audioDescription,
                                  queue: UnsafeMutablePointer<AudioQueueRef?>.allocate(capacity: kNumberBuffers),
                                  buffers: [AudioQueueBufferRef?](repeating: nil, count: kNumberBuffers),
                                  file: nil,
                                  currentPacket: 0,
                                  isRecording: false,
                                  mySelf: self
        )
        
        
        let auth=AVCaptureDevice.authorizationStatus(for: .audio)
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                self.prepare()
            }
        }
        //        prepare()
    }
    
    
    private func prepare() {
        if AudioQueueNewInput(&recordState!.format, MicRecorder.__callBack, &recordState, nil, nil, 0, recordState!.queue)
            == 0  {
            let bufferByteSize: Int = calculate(format: recordState!.format, seconds: MicRecorder.recordSampleTime)
            
            for index in (0..<recordState!.buffers.count)  {
                osStat = AudioQueueAllocateBuffer(recordState!.queue.pointee!, UInt32(bufferByteSize), &recordState!.buffers[index])
                osStat = AudioQueueEnqueueBuffer(recordState!.queue.pointee!, recordState!.buffers[index]!, 0, nil)
            }
            
            osStat = AudioQueueStart(recordState!.queue.pointee!, nil)
            if osStat != 0 {
                if osStat == kAudioQueueErr_InvalidDevice {
                    print("Invalid device, enable Mic in target/capabilities")
                }
            } else {
                recordState?.isRecording = true
            }
        }
    }
    
    func startRecording()  {
        recordState!.currentPacket = 0
        recordState?.isRecording = true
    }
    func stopRecording()  {
        recordState?.isRecording = false
    }
    
    func endRecording() {
        recordState?.isRecording = false
        AudioQueueStop(recordState!.queue.pointee!, true)
        AudioQueueDispose(recordState!.queue.pointee!, true)
    }
    
    func switchRecording() {
        let ir = !recordState!.isRecording
        recordState?.isRecording = ir
    }
    
    func calculate(format: AudioStreamBasicDescription, seconds: Double) -> Int
    {
        let framesRequiredForBufferTime = Int(ceil(seconds * format.mSampleRate))
        if framesRequiredForBufferTime > 0 {
            return (framesRequiredForBufferTime * Int(format.mBytesPerFrame))
        }
        else
        {
            var maximumPacketSize = UInt32(0)
            if format.mBytesPerPacket > 0
            {
                maximumPacketSize = format.mBytesPerPacket
            }
            else
            {
                audioQueueProperty(propertyId: kAudioQueueProperty_MaximumOutputPacketSize, value: &maximumPacketSize)
            }
            
            var packets = 0
            if format.mFramesPerPacket > 0
            {
                packets = (framesRequiredForBufferTime / Int(format.mFramesPerPacket))
            } else
            {
                packets = framesRequiredForBufferTime
            }
            
            if packets == 0
            {
                packets = 1
            }
            
            return (packets * Int(maximumPacketSize))
        }
    }
    
    func audioQueueProperty<T>(propertyId: AudioQueuePropertyID, value: inout T)
    {
        let propertySize = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        propertySize.pointee = UInt32(MemoryLayout<T>.size)
        
        osStat = AudioQueueGetProperty(recordState!.queue.pointee!, propertyId, &value, propertySize)
        propertySize.deallocate()
        
        if osStat != 0 {
            print("Unable to get audio queue property.")
        }
    }
}
