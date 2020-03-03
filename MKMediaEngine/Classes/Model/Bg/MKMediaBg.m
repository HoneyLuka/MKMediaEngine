//
//  MKMediaBg.m
//  MKAVExportDemo
//
//  Created by Luka Li on 19/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaBg.h"
#import "MKMediaTimeline.h"
#import "UIImage+MKMedia.h"

@interface MKMediaBg ()

@property (nonatomic, strong) GPUImagePicture *pic;

@end

@implementation MKMediaBg

- (GPUImageOutput *)bgOutputWithTimeline:(MKMediaTimeline *)timeline
{
    if (self.image) {
        return [self imageOutputWithTimeLine:timeline];
    }
    
    return nil;
}

- (GPUImageOutput *)imageOutputWithTimeLine:(MKMediaTimeline *)timeline
{
    if (!self.pic) {
        __block UIImage *image = nil;
        
        runOnMainQueueWithoutDeadlocking(^{
            @autoreleasepool {
                image = [self.image createImageToSize:timeline.renderSize
                                          contentMode:UIViewContentModeScaleAspectFill];
            }
        });
        
        self.pic = [[GPUImagePicture alloc] initWithImage:image];
        [self.pic processImage];
    }
    
    return self.pic;
}

@end
