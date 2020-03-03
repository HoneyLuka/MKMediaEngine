//
//  MKMediaTextOverlay.h
//  MKAVExportDemo
//
//  Created by Luka Li on 23/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaOverlay.h"

@interface MKMediaTextOverlay : MKMediaOverlay

@property (nonatomic, copy) NSAttributedString *attributedString;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, assign) NSTextAlignment alignment;
@property (nonatomic, assign) BOOL lineWrapped;

@end
