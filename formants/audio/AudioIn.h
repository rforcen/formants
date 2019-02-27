//
//  AudioIn.h
//  Recorder
//
//  Created by asd on 12/10/2018.
//  Copyright © 2018 voicesync. All rights reserved.
//

#ifndef AudioIn_h
#define AudioIn_h

#import <CoreAudio/CoreAudioTypes.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreFoundation/CFByteOrder.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioToolbox.h>

#import "RealArray.h"

static const float secondsSample=0.2; // lap time for each callback
static const int kNumberBuffers = 3;
typedef struct  {
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[kNumberBuffers];
    UInt32 bufferByteSize;
    SInt64 mCurrentPacket;
    bool mIsRunning;
    bool isRecording;
    void*userData; // will hold AudioIn object
} AQRecorderState;


@interface AudioIn : NSObject {
    AQRecorderState aqData;
@public
    void (^__callbackBlock)(AudioIn*);
    RealArray *recording;
}

+(AudioIn*)initWithnChan:(int)nChan sampRate:(int)sampRate;
-(void)recordHandler:(void (^)(AudioIn*))callbackBlock; // block each recording data ready
-(RealArray*)getRecording;
-(void)startRecording;
-(void)stopRecording;
-(BOOL)isRecording;
-(void)switchRecording;
-(void)end;
@end

#endif
