//
//  MKMediaEditorContext.h
//  TestProject
//
//  Created by Luka Li on 4/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MKMediaConst.h"
#import "MKMediaTimeline.h"

extern NSString * const MKMediaExportProgressNotification;
extern NSString * const MKMediaExportProgressKey;

typedef void(^MKMediaEditorContextExportCallback)(BOOL result, NSError *error);
typedef void(^MKMediaEditorContextPlayerItemCallback)(AVPlayerItem *playerItem, NSArray<CALayer *> *layerArray);

@interface MKMediaEditorContext : NSObject

@property (nonatomic, assign, readonly) MKMediaEditorContextStatus status;

@property (nonatomic, strong, readonly) MKMediaTimeline *timeline;

- (BOOL)createTimeline;

- (void)exportToURL:(NSURL *)exportURL completion:(MKMediaEditorContextExportCallback)completion;
- (void)generatePlayerItem:(MKMediaEditorContextPlayerItemCallback)completion;

#pragma mark - Helper

- (void)fastExportAVAsset:(AVAsset *)asset
                   toPath:(NSString *)filePath
                startTime:(CMTime)startTime
                  endTime:(CMTime)endTime
               completion:(MKMediaEditorContextExportCallback)completion;

+ (instancetype)sharedContext;

@end
