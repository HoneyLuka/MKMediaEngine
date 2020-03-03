//
//  MKMediaClip.h
//  TestProject
//
//  Created by Luka Li on 4/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKClip.h"
#import "MKMediaResource.h"
#import <GPUImage/GPUImage.h>

@class MKMediaSection;
@interface MKMediaClip : MKClip

@property (nonatomic, strong, readonly) MKMediaResource *resource;

@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, assign) CGFloat speed;
@property (nonatomic, assign) CMTimeRange clipRange;

@property (nonatomic, weak) MKMediaSection *sectionRef;

- (instancetype)initWithResource:(MKMediaResource *)resource;

/// 改变clip在时间线上的持续时间, 同时会修改outTime
/// 会考虑speed因素
/// 如果指定的长度超过素材本身可以支持的长度(考虑clipRange.start), 会修改clipRange为当前支持的最大range
///
- (void)changeClipDuration:(CMTime)duration;

@end
