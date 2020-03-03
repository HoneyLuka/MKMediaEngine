//
//  MKMediaCustomCompositor.h
//  MKAVExportDemo
//
//  Created by Luka Li on 13/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MKMediaEditorContext.h"

@interface MKMediaCustomCompositor : NSObject <AVVideoCompositing>

- (void)createRawDataOutputForSize:(CGSize)size timeline:(MKMediaTimeline *)timeline;

@end
