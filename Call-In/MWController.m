//
//  MWController.m
//  Call-In
//
//  Created by yllan on 2/21/13.
//  Copyright (c) 2013 Marshmallow. All rights reserved.
//

#import "MWController.h"

@implementation MWController
@synthesize recorder = _recoder;

- (void) awakeFromNib
{
    self.recorder = [[MWRecorder new] autorelease];
}

- (void) dealloc
{
    [_recorder release], _recorder = nil;
    [super dealloc];
}

- (IBAction) toggleRecord: (id)sender {
    if (self.recorder.recording) {
        [self.recorder stopRecording];
        [self.recordButton setTitle: @"Record"];
    } else {
        [self.recorder startRecording];
        [self.recordButton setTitle: @"Stop"];
    }
}

@end
