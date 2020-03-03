//
//  MKClip.m
//  MKAVExportDemo
//
//  Created by Luka Li on 20/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKClip.h"

@implementation MKClip

- (CMTime)clipDuration
{
    return CMTimeSubtract(self.outTime, self.inTime);
}

- (BOOL)containsTime:(CMTime)time
{
    if (CMTIME_COMPARE_INLINE(time, <, self.inTime)) {
        // 比当前片段早
        return NO;
    }
    
    if (CMTIME_COMPARE_INLINE(time, >, self.outTime)) {
        // 比当前片段晚
        return NO;
    }
    
    return YES;
}

@end
