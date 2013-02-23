//
//  MWPushStream.m
//  Call-In
//
//  Created by yllan on 2/21/13.
//  Copyright (c) 2013 Marshmallow. All rights reserved.
//

#import "MWPushStream.h"

@implementation MWPushStream
@synthesize data = _data;

- (id) init
{
    self = [super init];
    if (self) {
        _data = [[NSMutableData dataWithCapacity: 2048] retain];
    }
    return self;
}

- (void) dealloc
{
    [_data release], _data = nil;
    [super dealloc];
}

- (void) pushBytes: (char *)bytes length: (int)length
{
    [_data appendBytes: bytes length: length];
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len;
{
    NSInteger bytesToRead = MIN([_data length], len);
    if (bytesToRead > 0) {
        memmove(buffer, [_data bytes], bytesToRead);
        self.data = [NSMutableData dataWithData: [_data subdataWithRange: NSMakeRange(bytesToRead, [_data length] - bytesToRead)]];
    }
    return bytesToRead;
}
// reads up to length bytes into the supplied buffer, which must be at least of size len. Returns the actual number of bytes read.

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len
{
    return NO;
}
// returns in O(1) a pointer to the buffer in 'buffer' and by reference in 'len' how many bytes are available. This buffer is only valid until the next stream operation. Subclassers may return NO for this if it is not appropriate for the stream type. This may return NO if the buffer is not available.

- (BOOL) hasBytesAvailable
{
    return ([_data length] > 0);
}
@end
