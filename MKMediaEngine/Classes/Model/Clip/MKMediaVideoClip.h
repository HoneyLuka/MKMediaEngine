//
//  MKMediaVideoClip.h
//  MKAVExportDemo
//
//  Created by Luka Li on 20/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaClip.h"

@class MKMediaTimeline;
@interface MKMediaVideoClip : MKMediaClip

@property (nonatomic, assign) BOOL audioEnabled;
@property (nonatomic, assign) CGRect frame;

/// 弧度
@property (nonatomic, assign) CGFloat rotate;

@property (nonatomic, assign) CMPersistentTrackID videoTrackID;
@property (nonatomic, assign, readonly) CMPersistentTrackID subAudioTrackID;

- (GPUImageOutput<GPUImageInput> *)filterByTime:(CMTime)time timeline:(MKMediaTimeline *)timeline;

@end
