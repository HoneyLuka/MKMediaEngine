//
//  UIImage+MKMedia.h
//  MKAVExportDemo
//
//  Created by Luka Li on 21/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (MKMedia)

- (nullable UIImage *)createImageToSize:(CGSize)size contentMode:(UIViewContentMode)contentMode;

@end
