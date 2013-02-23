//
//  MWController.h
//  Call-In
//
//  Created by yllan on 2/21/13.
//  Copyright (c) 2013 Marshmallow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWRecorder.h"

@interface MWController : NSObject
{
    MWRecorder *_recorder;
}

@property (retain, nonatomic) MWRecorder *recorder;
@property (assign) IBOutlet NSButton *recordButton;

- (IBAction)toggleRecord:(id)sender;
@end
