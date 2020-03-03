//
//  MKMediaAnimatedImageOverlay.m
//  MKMediaEngine
//
//  Created by Luka Li on 25/12/2019.
//

#import "MKMediaAnimatedImageOverlay.h"
#import "MKMediaEditorContext.h"

@implementation MKMediaAnimatedImageOverlay

- (CALayer *)overlayLayer
{
    CALayer *layer = [CALayer layer];
    [self setupLayerAttr:layer];
    layer.geometryFlipped = YES;
    layer.masksToBounds = YES;
    layer.contentsGravity = convertContentMode(self.contentMode);
    
    NSMutableArray *cgImageArray = [NSMutableArray array];
    for (int i = 0; i < self.image.animatedImageFrameCount; i++) {
        UIImage *frameImg = [self.image animatedImageFrameAtIndex:i];
        if (frameImg) {
            [cgImageArray addObject:(__bridge id)frameImg.CGImage];
        }
    }
    
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    anim.values = cgImageArray;
    anim.duration = self.image.animatedImageFrameCount / [MKMediaEditorContext sharedContext].timeline.framePerSecond;
    anim.repeatCount = self.repeat ? CGFLOAT_MAX : 0;
    anim.beginTime = AVCoreAnimationBeginTimeAtZero + CMTimeGetSeconds(self.inTime);
    anim.removedOnCompletion = NO;
    
    [layer addAnimation:anim forKey:@"animatedAnimation"];
    
    return layer;
}

@end
