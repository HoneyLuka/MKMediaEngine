//
//  MKMediaImageOverlay.m
//  MKAVExportDemo
//
//  Created by Luka Li on 23/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaImageOverlay.h"

@implementation MKMediaImageOverlay

- (CALayer *)overlayLayer
{
    CALayer *layer = [CALayer layer];
    [self setupLayerAttr:layer];
    layer.geometryFlipped = YES;
    layer.masksToBounds = YES;
    
    @autoreleasepool {
        UIImage *fixedImage = [self removeRotationForImage:self.image];
        if (fixedImage) {
            layer.contents = (__bridge id)fixedImage.CGImage;
        }
    }
    
    layer.contentsGravity = convertContentMode(self.contentMode);
    
    return layer;
}

- (UIImage *)removeRotationForImage:(UIImage *)image
{
    if (!image) {
        return nil;
    }
    
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

@end
