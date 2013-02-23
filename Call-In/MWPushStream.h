//
//  MWPushStream.h
//  Call-In
//
//  Created by yllan on 2/21/13.
//  Copyright (c) 2013 Marshmallow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MWPushStream : NSInputStream
{
    NSMutableData *_data;
}
@property (retain) NSMutableData *data;
@end
