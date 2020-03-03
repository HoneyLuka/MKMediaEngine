//
//  MKMediaOverlay.m
//  MKAVExportDemo
//
//  Created by Luka Li on 21/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaOverlay.h"
#import "MKMediaTimeline.h"

@implementation MKMediaOverlay

- (void)setupLayerAttr:(CALayer *)layer
{
    layer.frame = self.frame;
    [layer setAffineTransform:CGAffineTransformMakeRotation(self.rotate)];
    
    if (self.backgroundColor) {
        layer.backgroundColor = self.backgroundColor.CGColor;
    }
    
    // 动画功能之后做
    
//    CABasicAnimation *inAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//    inAnimation.removedOnCompletion = NO;
//    inAnimation.fromValue = @0;
//    inAnimation.toValue = @1;
//    inAnimation.fillMode = kCAFillModeBoth;
//    inAnimation.duration = 0;
//    inAnimation.beginTime = AVCoreAnimationBeginTimeAtZero + CMTimeGetSeconds(self.inTime);
//
//    CABasicAnimation *outAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//    outAnimation.removedOnCompletion = NO;
//    outAnimation.fromValue = @1;
//    outAnimation.toValue = @0;
//    outAnimation.fillMode = kCAFillModeForwards;
//    outAnimation.duration = 0;
//    outAnimation.beginTime = AVCoreAnimationBeginTimeAtZero + CMTimeGetSeconds(self.outTime);
//
//    [layer addAnimation:inAnimation forKey:@"in"];
//    [layer addAnimation:outAnimation forKey:@"out"];
}

- (CALayer *)overlayLayer
{
    NSAssert(NO, @"should not use base class");
    return nil;
}

@end
