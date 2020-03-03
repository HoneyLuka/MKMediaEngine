//
//  MKMediaOverlay.h
//  MKAVExportDemo
//
//  Created by Luka Li on 21/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKClip.h"

@class MKMediaTimeline;
@interface MKMediaOverlay : MKClip

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, strong) UIColor *backgroundColor;

/// 弧度
@property (nonatomic, assign) CGFloat rotate;

- (void)setupLayerAttr:(CALayer *)layer;

- (CALayer *)overlayLayer;

@end
