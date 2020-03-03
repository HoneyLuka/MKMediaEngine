//
//  MKMediaVideoClip.m
//  MKAVExportDemo
//
//  Created by Luka Li on 20/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaVideoClip.h"
#import "MKMediaTimeline.h"

@implementation MKMediaVideoClip

- (instancetype)initWithResource:(MKMediaResource *)resource
{
    self = [super initWithResource:resource];
    self.audioEnabled = YES;
    self.volume = 1.f;
    return self;
}

- (CMPersistentTrackID)subAudioTrackID
{
    return self.videoTrackID * -1;
}

- (GPUImageOutput<GPUImageInput> *)filterByTime:(CMTime)time timeline:(MKMediaTimeline *)timeline
{
    if (CMTIME_COMPARE_INLINE(time, <, self.inTime)) {
        // 比当前片段早
        return nil;
    }
    
    if (CMTIME_COMPARE_INLINE(time, >, self.outTime)) {
        // 比当前片段晚
        return nil;
    }
    
    GPUImageTransformFilter *filter = [GPUImageTransformFilter new];
    CGAffineTransform transform = self.resource.assetTransform;
    
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeRotation(self.rotate));
    
    BOOL needXFlip = transform.a == -1 || transform.b == -1;
    BOOL needYFlip = transform.c == -1 || transform.d == -1;
    
    transform.tx = 0;
    transform.ty = 0;
    transform.a = ABS(transform.a);
    transform.b = ABS(transform.b);
    transform.c = ABS(transform.c);
    transform.d = ABS(transform.d);
    
    CGSize preferSize = CGSizeApplyAffineTransform(self.resource.assetSize, transform);
    preferSize = CGSizeMake(ABS(preferSize.width), ABS(preferSize.height));
    
    CGSize renderSize = timeline.renderSize;
    
    CGFloat xOffset = 0;
    CGFloat yOffset = 0;
    
    BOOL needAutoOffset = NO;
    CGSize containerSize = renderSize;
    if (!CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        containerSize = self.frame.size;
        needAutoOffset = YES;
    }
    
    if (preferSize.width / preferSize.height > containerSize.width / containerSize.height) {
        CGFloat widthScale = containerSize.width / renderSize.width;
        CGFloat newHeight = preferSize.height / preferSize.width * containerSize.width;
        CGFloat heightScale = newHeight / renderSize.height;
        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(widthScale, heightScale));
        
        if (needAutoOffset) {
            yOffset = (containerSize.height - newHeight) / 2;
        }
    } else if (preferSize.height / preferSize.width >= containerSize.height / containerSize.width) {
        CGFloat heightScale = containerSize.height / renderSize.height;
        CGFloat newWidth = preferSize.width / preferSize.height * containerSize.height;
        CGFloat widthScale = newWidth / renderSize.width;
        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(widthScale, heightScale));
        
        if (needAutoOffset) {
            xOffset = (containerSize.width - newWidth) / 2;
        }
    }
    
    transform.tx = (self.frame.origin.x + xOffset) * (1 / renderSize.width);
    transform.ty = (self.frame.origin.y + yOffset) * (1 / renderSize.height);
    
    filter.affineTransform = transform;
    filter.ignoreAspectRatio = YES;
    
    if (!CGRectEqualToRect(self.frame, CGRectZero)) {
        filter.anchorTopLeft = YES;
    }
    
    if (!needXFlip && !needYFlip) {
        return filter;
    }
    
    // need flip
    GPUImageTransformFilter *flip = [GPUImageTransformFilter new];
    flip.ignoreAspectRatio = YES;
    flip.affineTransform = CGAffineTransformMake(needXFlip ? -1 : 1,
                                                 0,
                                                 0,
                                                 needYFlip ? -1 : 1,
                                                 0,
                                                 0);
    
    [flip addTarget:filter];
    GPUImageFilterGroup *group = [GPUImageFilterGroup new];
    group.initialFilters = @[flip];
    group.terminalFilter = filter;
    [group addFilter:flip];
    [group addFilter:filter];
    
    return group;
}


@end
