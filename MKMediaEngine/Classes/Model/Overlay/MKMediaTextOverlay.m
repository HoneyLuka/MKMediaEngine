//
//  MKMediaTextOverlay.m
//  MKAVExportDemo
//
//  Created by Luka Li on 23/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaTextOverlay.h"

@interface MKMediaOverlayTextLayer : CATextLayer

@end

@implementation MKMediaOverlayTextLayer

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.geometryFlipped = YES;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.geometryFlipped = YES;
    }
    return self;
}

- (void)drawInContext:(CGContextRef)ctx
{
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat yDiff = 0;
    CGFloat textHeight = 0;

    if ([self.string isKindOfClass:NSAttributedString.class]) {
        NSAttributedString *str = (NSAttributedString *)self.string;
        if (!self.isWrapped) {
            textHeight = str.size.height;
        } else {
            CGRect rect =
            [str boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.bounds), CGFLOAT_MAX)
                              options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                                             context:nil];
            textHeight = ceilf(CGRectGetHeight(rect));
        }
        
        yDiff = (height - textHeight) / 2;
    } else {
        textHeight = self.fontSize;
        yDiff = (height - textHeight) / 2 - textHeight / 10;
    }
    
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 0, yDiff);
    [super drawInContext:ctx];
    CGContextRestoreGState(ctx);
}

@end

@implementation MKMediaTextOverlay

- (CALayer *)overlayLayer
{
    MKMediaOverlayTextLayer *textLayer = [MKMediaOverlayTextLayer layer];
    [self setupLayerAttr:textLayer];
    
    NSAttributedString *attrString = self.attributedString;
    if (!attrString) {
        NSString *s = self.text ?: @"";
        NSDictionary *attr = @{NSFontAttributeName: self.font,
                               NSForegroundColorAttributeName: self.textColor};
        attrString = [[NSAttributedString alloc] initWithString:s attributes:attr];
    }

    textLayer.string = attrString;
    textLayer.wrapped = self.lineWrapped;
    textLayer.alignmentMode = [self convertNSTextAlignment];
    
    return textLayer;
}

- (CATextLayerAlignmentMode)convertNSTextAlignment
{
    switch (self.alignment) {
        case NSTextAlignmentLeft:
            return kCAAlignmentLeft;
        case NSTextAlignmentRight:
            return kCAAlignmentRight;
        case NSTextAlignmentCenter:
            return kCAAlignmentCenter;
        default:
            return kCAAlignmentCenter;
    }
}

- (UIFont *)font
{
    if (!_font) {
        _font = [UIFont systemFontOfSize:20];
    }
    
    return _font;
}

- (UIColor *)textColor
{
    if (!_textColor) {
        _textColor = UIColor.whiteColor;
    }
    
    return _textColor;
}

@end
