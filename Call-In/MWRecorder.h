//
//  MWRecorder.h
//  Call-In
//
//  Created by yllan on 2/21/13.
//  Copyright (c) 2013 Marshmallow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudio.h>
#import "lame.h"
#import "AFNetworking.h"

static const int kNumberBuffers = 4;

typedef struct {
    AudioStreamBasicDescription  mDataFormat;
    AudioQueueRef                mQueue;
    AudioQueueBufferRef          mBuffers[kNumberBuffers];
    //    AudioFileID                  mAudioFile;
    lame_global_flags            *gfp;
    UInt32                       bufferByteSize;
    SInt64                       mCurrentPacket;
    bool                         mIsRunning;
} AQRecorderState;

@interface MWRecorder : NSObject
{
    AQRecorderState _aqData;
    lame_global_flags *_gfp;
}
- (BOOL) recording;
- (void) startRecording;
- (void) stopRecording;
@end
