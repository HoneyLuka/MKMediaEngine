//
//  UIView+MKMedia.m
//  MKAVExportDemo
//
//  Created by Luka Li on 23/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "UIView+MKMedia.h"

@implementation UIView (MKMedia)

- (UIImage *)createSnapshotAsPx
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == NULL) {
        return nil;
    }
    
    [self.layer renderInContext:ctx];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
