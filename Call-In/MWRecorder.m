//
//  MWRecorder.m
//  Call-In
//
//  Created by yllan on 2/21/13.
//  Copyright (c) 2013 Marshmallow. All rights reserved.
//

#import "MWRecorder.h"
#import "AFNetworking.h"

static void HandleInputBuffer (void                                *aqData,
                               AudioQueueRef                       inAQ,
                               AudioQueueBufferRef                 inBuffer,
                               const AudioTimeStamp                *inStartTime,
                               UInt32                              inNumPackets,
                               const AudioStreamPacketDescription  *inPacketDesc
                               )
{
    AQRecorderState *pAqData = (AQRecorderState *) aqData;
    
    if (inNumPackets == 0 && pAqData->mDataFormat.mBytesPerPacket != 0)
        inNumPackets = inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    
    // bytes: inBuffer->mAudioData with length: inBuffer->mAudioDataByteSize
    printf("%u packet\n", inNumPackets);
    printf("write %u bytes\n", inBuffer->mAudioDataByteSize);
    if (inBuffer->mAudioDataByteSize > 0) {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        short int leftpcm[inNumPackets];
        short int rightpcm[inNumPackets];
        
        for(int i = 0; i < inNumPackets; i++) {
            leftpcm[i] = ((short int *)inBuffer->mAudioData)[2 * i];
            rightpcm[i] = ((short int *)inBuffer->mAudioData)[2 * i + 1];
        }
        int bufSize = inBuffer->mAudioDataByteSize * 4;
        unsigned char buf[bufSize];
        
        int encodedLength = lame_encode_buffer(pAqData->gfp, leftpcm, rightpcm, inNumPackets, buf, bufSize);
        printf("encoded length: %d\n", encodedLength);

//        FILE *fp = fopen("/tmp/test.mp3", "a");
//        fwrite(buf, 1, encodedLength, fp);
//        fclose(fp);
        
        NSURL *url = [NSURL URLWithString: @"http://localhost:9000/feed"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod: @"POST"];
        [request   setValue: @"application/x-www-form-urlencoded; charset=UTF-8"
         forHTTPHeaderField:@"Content-Type"];
        NSData *formData = [NSData dataWithBytes: buf length: encodedLength];
        [request setHTTPBody:formData];
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest: request delegate: nil];
        [conn start];
        [pool drain];
    }

    
//    if (AudioFileWritePackets (pAqData->mAudioFile,
//                               false,
//                               inBuffer->mAudioDataByteSize,
//                               inPacketDesc,
//                               pAqData->mCurrentPacket,
//                               &inNumPackets,
//                               inBuffer->mAudioData
//                               ) == noErr) {
    
        pAqData->mCurrentPacket += inNumPackets;
        if (pAqData->mIsRunning == 0) return;
        
        AudioQueueEnqueueBuffer(pAqData->mQueue, inBuffer, 0, NULL);
        
//    }

}

void DeriveBufferSize (AudioQueueRef                audioQueue,
                       AudioStreamBasicDescription  *ASBDescription,
                       Float64                      seconds,
                       UInt32                       *outBufferSize)
{
    static const int maxBufferSize = 0x50000;
    
    int maxPacketSize = ASBDescription->mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty (
                               audioQueue,
                               kAudioConverterPropertyMaximumOutputPacketSize,
                               &maxPacketSize,
                               &maxVBRPacketSize
                               );
    }
    
    Float64 numBytesForTime = ASBDescription->mSampleRate * maxPacketSize * seconds;
    *outBufferSize = (UInt32) (numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize);
}

OSStatus SetMagicCookieForFile (AudioQueueRef inQueue,
                                AudioFileID   inFile)
{
    OSStatus result = noErr;
    UInt32 cookieSize;
    
    if (AudioQueueGetPropertySize(inQueue, kAudioQueueProperty_MagicCookie, &cookieSize) == noErr)
    {
        char* magicCookie = (char *) malloc(cookieSize);
        if (AudioQueueGetProperty(inQueue, kAudioQueueProperty_MagicCookie, magicCookie, &cookieSize) == noErr)
            result = AudioFileSetProperty(inFile,
                                          kAudioFilePropertyMagicCookieData,
                                          cookieSize,
                                          magicCookie
                                          );
        free(magicCookie);
    }
    return result;
}

@implementation MWRecorder

- (BOOL) recording
{
    return _aqData.mIsRunning;
}

- (void) startRecording
{
    // Set Up an Audio Format for Recording
    
    _aqData.mDataFormat.mFormatID = kAudioFormatLinearPCM;
    _aqData.mDataFormat.mSampleRate = 44100.0;
    _aqData.mDataFormat.mChannelsPerFrame = 2;
    _aqData.mDataFormat.mBitsPerChannel = 16;
    _aqData.mDataFormat.mBytesPerPacket =
    _aqData.mDataFormat.mBytesPerFrame =
    _aqData.mDataFormat.mChannelsPerFrame * sizeof (SInt16);
    _aqData.mDataFormat.mFramesPerPacket = 1;
    
    _aqData.mDataFormat.mFormatFlags =
//        kLinearPCMFormatFlagIsBigEndian
        kLinearPCMFormatFlagIsSignedInteger
        | kLinearPCMFormatFlagIsPacked;
        
    // Create a Recording Audio Queue
    AudioQueueNewInput(&_aqData.mDataFormat,
                       HandleInputBuffer,
                       &_aqData,
                       NULL,
                       kCFRunLoopCommonModes,
                       0,
                       &_aqData.mQueue);
    
    // Set an Audio Queue Buffer Size
    DeriveBufferSize(_aqData.mQueue, &(_aqData.mDataFormat), 0.5, &_aqData.bufferByteSize);
    
    
    // Prepare a Set of Audio Queue Buffers
    for (int i = 0; i < kNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(_aqData.mQueue, _aqData.bufferByteSize, &_aqData.mBuffers[i]);
        AudioQueueEnqueueBuffer(_aqData.mQueue, _aqData.mBuffers[i], 0, NULL);
    }
    
    // Set Lame
    _gfp = lame_init();
    _aqData.gfp = _gfp;
    
    lame_set_num_channels(_gfp, 2);
    lame_set_in_samplerate(_gfp,44100);
    lame_set_brate(_gfp,96);
    lame_set_mode(_gfp, 1);
    lame_set_quality(_gfp, 5);   /* 2=high  5 = medium  7=low */
    
    if (lame_init_params(_gfp) < 0) {
        NSLog(@"Error! lame_init_params!");
        return;
    }
    
    // Record Audio
    _aqData.mCurrentPacket = 0;
    _aqData.mIsRunning = true;
    
    AudioQueueStart(_aqData.mQueue, NULL);
}

- (void) stopRecording
{
    AudioQueueStop (_aqData.mQueue, true);
    _aqData.mIsRunning = false;
    
    // Clean up
    AudioQueueDispose(_aqData.mQueue, true);
}

@end
