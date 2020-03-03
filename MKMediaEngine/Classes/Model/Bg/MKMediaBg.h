//
//  MKMediaBg.h
//  MKAVExportDemo
//
//  Created by Luka Li on 19/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaObject.h"

@class MKMediaTimeline;
@interface MKMediaBg : MKMediaObject

@property (nonatomic, strong) UIImage *image;

- (GPUImageOutput *)bgOutputWithTimeline:(MKMediaTimeline *)timeline;

@end
