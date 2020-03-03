//
//  MKMediaClip.m
//  TestProject
//
//  Created by Luka Li on 4/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaClip.h"
#import "MKMediaTimeline.h"

@interface MKMediaClip ()

@property (nonatomic, strong) MKMediaResource *resource;

@end

@implementation MKMediaClip

- (instancetype)initWithResource:(MKMediaResource *)resource
{
    self = [super init];
    self.speed = 1.f;
    self.resource = resource;
    self.clipRange = CMTimeRangeMake(kCMTimeZero, resource.duration);
    return self;
}

- (CMTime)clipDuration
{
    return CMTimeMultiplyByFloat64(self.clipRange.duration, 1.f / self.speed);
}

- (void)changeClipDuration:(CMTime)duration
{
    CMTime normalSpeedDuration = CMTimeMultiplyByFloat64(duration, self.speed);
    CMTimeRange currentMaxRange = CMTimeRangeMake(self.clipRange.start,
                                                  CMTimeSubtract(self.resource.duration, self.clipRange.start));
    
    if (CMTIME_COMPARE_INLINE(normalSpeedDuration, >, currentMaxRange.duration)) {
        // 当前设置的长度如果大于目前clip能够提供的最大长度，则使用最大长度
        self.clipRange = currentMaxRange;
    } else {
        self.clipRange = CMTimeRangeMake(self.clipRange.start, normalSpeedDuration);
    }
    
    self.outTime = CMTimeAdd(self.inTime, self.clipDuration);
}

@end
