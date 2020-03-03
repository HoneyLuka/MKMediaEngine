//
//  MKMediaSection.m
//  MKAVExportDemo
//
//  Created by Luka Li on 21/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaSection.h"

@interface MKMediaSection ()

@property (nonatomic, strong) NSMutableArray<MKMediaVideoClip *> *videoClips;
@property (nonatomic, strong) NSMutableArray<MKMediaOverlay *> *overlays;

@property (nonatomic, assign) CMTime inTime;
@property (nonatomic, assign) CMTime outTime;

@end

@implementation MKMediaSection

#pragma mark -

- (CMTime)sectionDuration
{
    MKMediaVideoClip *lastClip = [self getLastVideoClip];
    MKMediaVideoClip *firstClip = [self getFirstVideoClip];
    
    return CMTimeSubtract(lastClip.outTime, firstClip.inTime);
}

- (void)reload
{
    for (int i = 0; i < self.videoClips.count; i++) {
        MKMediaVideoClip *clip = self.videoClips[i];
        clip.videoTrackID = self.sectionIndex * 10000 + i + 1;
        clip.sectionRef = self;
    }
    
    self.inTime = [self getFirstVideoClip].inTime;
    self.outTime = [self getLastVideoClip].outTime;
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

#pragma mark - Clip

- (void)appendVideoClip:(MKMediaVideoClip *)clip inTime:(CMTime)inTime duration:(CMTime)duration
{
    CMTime outTime = CMTimeAdd(inTime, duration);
    [self appendVideoClip:clip inTime:inTime outTime:outTime];
}

- (void)appendVideoClip:(MKMediaVideoClip *)clip inTime:(CMTime)inTime outTime:(CMTime)outTime
{
    if ([self.videoClips containsObject:clip]) {
        [self.videoClips removeObject:clip];
    }
    
    [self.videoClips addObject:clip];
    clip.inTime = inTime;
    clip.outTime = outTime;
}

#pragma mark - Overlay

//- (void)appendOverlay:(MKMediaOverlay *)overlay
//{
//    CMTime inTime = kCMTimeZero;
//    CMTime outTime = CMTimeMake(NSIntegerMax, 600);
//    [self appendOverlay:overlay inTime:inTime outTime:outTime];
//}

- (void)appendOverlay:(MKMediaOverlay *)overlay inTime:(CMTime)inTime outTime:(CMTime)outTime
{
    overlay.inTime = inTime;
    overlay.outTime = outTime;
    [self.overlays addObject:overlay];
}

#pragma mark - Helper

- (MKMediaVideoClip *)getLastVideoClip
{
    MKMediaVideoClip *clip = nil;
    for (MKMediaVideoClip *c in self.videoClips) {
        if (!clip) {
            clip = c;
            continue;
        }
        
        if (CMTIME_COMPARE_INLINE(c.outTime, >, clip.outTime)) {
            clip = c;
        }
    }
    
    return clip;
}

- (MKMediaVideoClip *)getFirstVideoClip
{
    MKMediaVideoClip *clip = nil;
    for (MKMediaVideoClip *c in self.videoClips) {
        if (!clip) {
            clip = c;
            continue;
        }
        
        if (CMTIME_COMPARE_INLINE(c.inTime, <, clip.inTime)) {
            clip = c;
        }
    }
    
    return clip;
}

#pragma mark - Getter

- (NSMutableArray<MKMediaVideoClip *> *)videoClips
{
    if (!_videoClips) {
        _videoClips = [NSMutableArray array];
    }
    
    return _videoClips;
}

- (NSMutableArray<MKMediaOverlay *> *)overlays
{
    if (!_overlays) {
        _overlays = [NSMutableArray array];
    }
    
    return _overlays;
}

@end
