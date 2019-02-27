//
//  AudioIn.cpp
//  Recorder
//
//  Created by asd on 12/10/2018.
//  https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/AudioQueueProgrammingGuide/AQRecord/RecordingAudio.html#//apple_ref/doc/uid/TP40005343-CH4-SW14
//
// once started is always recording, calling stopRecording disables calling selector callback

#import "AudioIn.h"

@interface AudioIn() 
@end


@implementation AudioIn


+(AudioIn*)initWithnChan:(int)nChan sampRate:(int)sampRate { // use 1, 22050
    OSStatus osStat;
    
    AudioIn* audioIn=[[super alloc]init];
    
    audioIn->recording=[RealArray init]; 
    
    const int sampleSize = sizeof(Float32); // define audio format
    AudioStreamBasicDescription AudioDescription = {
        .mSampleRate        = sampRate,
        .mFormatID          = kAudioFormatLinearPCM,
        .mFormatFlags       = kAudioFormatFlagIsFloat,
        .mBytesPerPacket    = sampleSize * nChan,
        .mFramesPerPacket   = 1,
        .mBytesPerFrame     = nChan * sampleSize,
        .mChannelsPerFrame  = nChan,
        .mBitsPerChannel    = 8 * sampleSize, //8 bits per byte
        .mReserved          = 0
    };
    audioIn->aqData.mDataFormat=AudioDescription;
    
    audioIn->aqData.bufferByteSize=[audioIn deriveBufferSize:audioIn->aqData.mQueue
                                    ASBDescription:audioIn->aqData.mDataFormat
                                           seconds:secondsSample];
    audioIn->aqData.userData=(__bridge void * _Nullable)(audioIn); // assign current AudioIn obj. to user data
    osStat=AudioQueueNewInput(&audioIn->aqData.mDataFormat, __callBackHandler,
                       &audioIn->aqData, NULL, kCFRunLoopCommonModes,  0, &audioIn->aqData.mQueue);

    // Prepare a Set of Audio Queue Buffers
    for (int i = 0; i < kNumberBuffers; ++i) {
        osStat=AudioQueueAllocateBuffer(audioIn->aqData.mQueue, audioIn->aqData.bufferByteSize, &audioIn->aqData.mBuffers[i]);
        osStat=AudioQueueEnqueueBuffer(audioIn->aqData.mQueue, audioIn->aqData.mBuffers[i], 0, NULL);
    }
    
    // start recording
    audioIn->aqData.mCurrentPacket = 0; // Record Audio
    audioIn->aqData.mIsRunning = true;
    osStat=AudioQueueStart(audioIn->aqData.mQueue, NULL);
    
    return audioIn;
}

// the 'C' AudioQueueInputCallback call back handler
static void  __callBackHandler(void *aqData, AudioQueueRef inAQ,
                              AudioQueueBufferRef inBuffer,
                              const AudioTimeStamp *inStartTime, UInt32 inNumPackets,
                              const AudioStreamPacketDescription *inPacketDesc) {
    
    AQRecorderState *pAqData = (AQRecorderState *)aqData;
    
    if (inNumPackets == 0 && pAqData->mDataFormat.mBytesPerPacket != 0)
        inNumPackets = inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    
    AudioIn*audioIn=(__bridge AudioIn *)pAqData->userData; // get AudioIn in userData
    
    // call selector if recording, always running
    if (audioIn!=nil && audioIn->__callbackBlock!=nil && pAqData->isRecording) {
        [audioIn->recording copyReals:inBuffer->mAudioData size:inNumPackets]; // copy input recording
        audioIn->__callbackBlock(audioIn); // call handler block
    }
    
    pAqData->mCurrentPacket += inNumPackets;
    if (pAqData->mIsRunning)
        AudioQueueEnqueueBuffer(pAqData->mQueue, inBuffer, 0, NULL);
}

- (void)recordHandler:(void (^)(AudioIn*))callbackBlock {
    __callbackBlock=callbackBlock;
}

-(RealArray*)getRecording {
    return recording;
}

// always recording, control action in selector body
-(void) startRecording { self->aqData.isRecording=true;}
-(void) stopRecording  { self->aqData.isRecording=false;}
-(BOOL) isRecording    { return (BOOL)self->aqData.isRecording; }
-(void) switchRecording {
    if ([self isRecording]) [self stopRecording];
    else [self startRecording];
}

-(void)end {
    AudioQueueStop(aqData.mQueue, true); // Wait, on user interface thread, until user stops the recording
    aqData.mIsRunning = false;
    AudioQueueDispose(aqData.mQueue, true); // Clean Up After Recording.   When finished with recording, dispose of the audio queue
}

-(UInt32)deriveBufferSize: (AudioQueueRef) audioQueue  ASBDescription:(AudioStreamBasicDescription)ASBDescription seconds:(Float64)seconds        {
    static const int maxBufferSize = 0x50000; // 320kb
    
    int maxPacketSize = ASBDescription.mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty(audioQueue,
                              kAudioQueueProperty_MaximumOutputPacketSize,
                              &maxPacketSize, &maxVBRPacketSize);
    }
    
    Float64 numBytesForTime = ASBDescription.mSampleRate * maxPacketSize * seconds;
    
    return  (UInt32)(numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize);
}
@end
