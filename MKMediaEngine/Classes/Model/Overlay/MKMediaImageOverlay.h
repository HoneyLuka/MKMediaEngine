//
//  MKMediaImageOverlay.h
//  MKAVExportDemo
//
//  Created by Luka Li on 23/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaOverlay.h"

@interface MKMediaImageOverlay : MKMediaOverlay

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) UIViewContentMode contentMode;

@end
