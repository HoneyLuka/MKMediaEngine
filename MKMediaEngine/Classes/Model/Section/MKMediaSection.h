//
//  MKMediaSection.h
//  MKAVExportDemo
//
//  Created by Luka Li on 21/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaObject.h"
#import "MKMediaBg.h"
#import "MKMediaVideoClip.h"
#import "MKMediaOverlay.h"

@interface MKMediaSection : MKMediaObject

@property (nonatomic, assign) int32_t sectionIndex;
@property (nonatomic, assign, readonly) CMTime inTime;
@property (nonatomic, assign, readonly) CMTime outTime;
@property (nonatomic, assign, readonly) CMTime sectionDuration;

@property (nonatomic, strong) MKMediaBg *bg;
@property (nonatomic, strong, readonly) NSMutableArray<MKMediaVideoClip *> *videoClips;
@property (nonatomic, strong, readonly) NSMutableArray<MKMediaOverlay *> *overlays;

- (void)reload;

- (BOOL)containsTime:(CMTime)time;

#pragma mark - Add

- (void)appendVideoClip:(MKMediaVideoClip *)clip inTime:(CMTime)inTime duration:(CMTime)duration;

/// 追加到数组最后, 使用参数指定的time
- (void)appendVideoClip:(MKMediaVideoClip *)clip inTime:(CMTime)inTime outTime:(CMTime)outTime;

/// 追加到数组最后, 持续时间为整个section长度, 会主动更改overlay的inTime和outTime
//- (void)appendOverlay:(MKMediaOverlay *)overlay;
- (void)appendOverlay:(MKMediaOverlay *)overlay inTime:(CMTime)inTime outTime:(CMTime)outTime;

@end
