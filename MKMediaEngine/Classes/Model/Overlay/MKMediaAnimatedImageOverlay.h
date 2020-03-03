//
//  MKMediaAnimatedImageOverlay.h
//  MKMediaEngine
//
//  Created by Luka Li on 25/12/2019.
//

#import "MKMediaOverlay.h"
#import <YYKit/YYKit.h>

@interface MKMediaAnimatedImageOverlay : MKMediaOverlay

@property (nonatomic, strong) YYImage *image;
@property (nonatomic, assign) UIViewContentMode contentMode;
@property (nonatomic, assign) BOOL repeat;

@end
