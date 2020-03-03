//
//  MKMediaEditorContext.m
//  TestProject
//
//  Created by Luka Li on 4/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaEditorContext.h"
#import "MKMediaCustomCompositor.h"

NSString * const MKMediaExportProgressNotification = @"MKMediaExportProgressNotification";
NSString * const MKMediaExportProgressKey = @"MKMediaExportProgressKey";

@interface MKMediaEditorContext ()

@property (nonatomic, assign) MKMediaEditorContextStatus status;

@property (nonatomic, strong) MKMediaTimeline *timeline;

@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) AVAssetExportSession *exportSession;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation MKMediaEditorContext

+ (instancetype)sharedContext
{
    static MKMediaEditorContext *sContext = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sContext = [MKMediaEditorContext new];
    });
    
    return sContext;
}

- (BOOL)createTimeline
{
    if (self.status != MKMediaEditorContextStatusIdle) {
        return NO;
    }
    
    self.timeline = [[MKMediaTimeline alloc] init];
    
    self.status = MKMediaEditorContextStatusEditing;
    
    return YES;
}

- (BOOL)generate
{
    [self.timeline reload];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    composition.naturalSize = self.timeline.renderSize;
    
    // 目前只处理第一个章节
    MKMediaSection *section = self.timeline.sections.firstObject;
    for (int i = 0; i < section.videoClips.count; i++) {
        MKMediaVideoClip *clip = section.videoClips[i];
        
        AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                         preferredTrackID:clip.videoTrackID];
        AVAssetTrack *videoAssetTrack = [clip.resource videoTrack];
        
        NSError *error;
        [videoTrack insertTimeRange:clip.clipRange ofTrack:videoAssetTrack atTime:clip.inTime error:&error];
        if (error) {
            NSLog(@"error = %@", error);
            NSAssert(NO, @"");
            self.timeline = nil;
            return NO;
        }
        
        if (clip.audioEnabled) {
            AVAssetTrack *audioAssetTrack = [clip.resource audioTrack];
            if (!audioAssetTrack) {
                continue;
            }
            
            AVMutableCompositionTrack *audioTrack =
            [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                     preferredTrackID:clip.subAudioTrackID];
            [audioTrack insertTimeRange:clip.clipRange
                                ofTrack:audioAssetTrack
                                 atTime:clip.inTime
                                  error:&error];
            if (error) {
                NSLog(@"error = %@", error);
                NSAssert(NO, @"");
                self.timeline = nil;
                return NO;
            }
        }
    }
    
    if (self.timeline.passthoughAudio) {
        MKMediaAudioClip *audioClip = self.timeline.passthoughAudio;
        AVAssetTrack *audioAssetTrack = [audioClip.resource audioTrack];
        if (audioAssetTrack) {
            AVMutableCompositionTrack *audioTrack =
            [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                     preferredTrackID:MKME_PASSTHOUGH_AUDIO_TRACK_ID];
            
            CMTime duration = composition.duration;
            CMTime offset = kCMTimeZero;
            
            while (CMTIME_COMPARE_INLINE(offset, <, duration)) {
                NSError *error;
                [audioTrack insertTimeRange:audioClip.clipRange
                                    ofTrack:audioAssetTrack
                                     atTime:offset
                                      error:&error];
                
                if (error) {
                    NSLog(@"audio error = %@", error);
                    NSAssert(NO, @"");
                    self.timeline = nil;
                    return NO;
                }
                
                offset = CMTimeAdd(offset, audioClip.clipDuration);
            }
            
            audioClip.audioTrackID = MKME_PASSTHOUGH_AUDIO_TRACK_ID;
        }
    }
    
    self.composition = composition;
    return YES;
}

- (void)generatePlayerItem:(MKMediaEditorContextPlayerItemCallback)completion
{
    if (![self generate]) {
        MKME_SAFE_BLOCK(completion, nil, nil);
        return;
    }
    
    self.status = MKMediaEditorContextStatusIdle;
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.composition];
    item.videoComposition = [self createVideoComposition:NO];
    item.audioMix = [self createAudioMix];
    
    if ([item.customVideoCompositor isKindOfClass:MKMediaCustomCompositor.class]) {
        MKMediaCustomCompositor *compositor = (MKMediaCustomCompositor *)item.customVideoCompositor;
        [compositor createRawDataOutputForSize:self.timeline.renderSize timeline:self.timeline];
    }
    
    NSArray *layerArray = [self createAnimationLayersArray];
    MKME_SAFE_BLOCK(completion, item, layerArray);
}

- (void)exportToURL:(NSURL *)exportURL completion:(MKMediaEditorContextExportCallback)completion
{
    if (self.status != MKMediaEditorContextStatusEditing) {
        MKME_SAFE_BLOCK(completion, NO, [self errorWithCode:MKMediaEditorErrorCodeWrongStatus]);
        NSAssert(NO, @"wrong status");
        return;
    }
    
    self.status = MKMediaEditorContextStatusExporting;
    
    if (![self generate]) {
        self.status = MKMediaEditorContextStatusIdle;
        MKME_SAFE_BLOCK(completion, NO, [self errorWithCode:MKMediaEditorErrorCodeInternalError]);
        NSAssert(NO, @"generate failed");
        return;
    }
    
    self.exportSession = [[AVAssetExportSession alloc]
                          initWithAsset:self.composition
                          presetName:AVAssetExportPresetHighestQuality];
    
    self.exportSession.shouldOptimizeForNetworkUse = YES;
    self.exportSession.outputURL = exportURL;
    self.exportSession.outputFileType = AVFileTypeMPEG4;
    self.exportSession.videoComposition = [self createVideoComposition:YES];
    self.exportSession.audioMix = [self createAudioMix];
    
    if ([self.exportSession.customVideoCompositor isKindOfClass:MKMediaCustomCompositor.class]) {
        MKMediaCustomCompositor *compositor = (MKMediaCustomCompositor *)self.exportSession.customVideoCompositor;
        [compositor createRawDataOutputForSize:self.timeline.renderSize timeline:self.timeline];
    }
    
    [self startProgressTimer];
    
    __weak typeof(self) weakSelf = self;
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf stopProgressTimer];
            
            weakSelf.status = MKMediaEditorContextStatusIdle;
            
            if (weakSelf.exportSession.error) {
                MKME_SAFE_BLOCK(completion, NO, weakSelf.exportSession.error);
                return;
            }
            
            MKME_SAFE_BLOCK(completion, YES, nil);
        });
    }];
}

- (void)startProgressTimer
{
    [self stopProgressTimer];
    self.timer = [NSTimer timerWithTimeInterval:1
                                         target:self
                                       selector:@selector(onTimer)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopProgressTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)onTimer
{
    if (!self.exportSession) {
        [self stopProgressTimer];
        return;
    }
    
    if (self.exportSession.status != AVAssetExportSessionStatusWaiting &&
        self.exportSession.status != AVAssetExportSessionStatusExporting) {
        [self stopProgressTimer];
        return;
    }
    
    NSDictionary *userInfo = @{MKMediaExportProgressKey : @(self.exportSession.progress)};
    [[NSNotificationCenter defaultCenter] postNotificationName:MKMediaExportProgressNotification
                                                        object:nil
                                                      userInfo:userInfo];
}

- (AVMutableVideoComposition *)createVideoComposition:(BOOL)containsAnimationTool
{
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:self.composition];
    videoComposition.customVideoCompositorClass = MKMediaCustomCompositor.class;
    videoComposition.frameDuration = CMTimeMake(1, self.timeline.framePerSecond);
    videoComposition.renderSize = self.timeline.renderSize;
    if (containsAnimationTool) {
        videoComposition.animationTool = [self createAnimationTool];
    }
    
    return videoComposition;
}

- (AVAudioMix *)createAudioMix
{
    AVMutableAudioMix *mix = [AVMutableAudioMix audioMix];
    NSMutableArray *array = [NSMutableArray array];
    
    if (self.timeline.passthoughAudio) {
        MKMediaAudioClip *music = self.timeline.passthoughAudio;
        AVMutableCompositionTrack *track = [self.composition trackWithTrackID:music.audioTrackID];
        if (track) {
            AVMutableAudioMixInputParameters *input =
            [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
            [input setVolume:music.volume atTime:kCMTimeZero];
            
            [array addObject:input];
        }
    }
    
    MKMediaSection *section = self.timeline.sections.firstObject;
    for (int i = 0; i < section.videoClips.count; i++) {
        MKMediaVideoClip *clip = section.videoClips[i];
        
        if (clip.audioEnabled) {
            AVMutableCompositionTrack *track = [self.composition trackWithTrackID:clip.subAudioTrackID];
            if (track) {
                AVMutableAudioMixInputParameters *input =
                [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
                [input setVolume:clip.volume atTime:kCMTimeZero];
                
                [array addObject:input];
            }
        }
    }
    
    mix.inputParameters = array;
    return mix;
}

- (AVVideoCompositionCoreAnimationTool *)createAnimationTool
{
    CALayer *parentLayer = [CALayer layer];
    parentLayer.geometryFlipped = YES;
    parentLayer.frame = CGRectMake(0, 0, self.timeline.renderSize.width, self.timeline.renderSize.height);
    
    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = parentLayer.frame;
    [parentLayer addSublayer:videoLayer];
    
    CALayer *overlayContainerLayer = [CALayer layer];
    overlayContainerLayer.frame = parentLayer.frame;
    [parentLayer addSublayer:overlayContainerLayer];
    
    for (int i = 0; i < self.timeline.sections.count; i++) {
        MKMediaSection *section = self.timeline.sections[i];
        
        // section layer
        CALayer *sectionOverlayLayer = [CALayer layer];
        sectionOverlayLayer.frame = overlayContainerLayer.frame;
//        sectionOverlayLayer.opacity = 0;
//
//        CABasicAnimation *inAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//        inAnimation.removedOnCompletion = NO;
//        inAnimation.toValue = @1;
//        inAnimation.fillMode = kCAFillModeForwards;
//        inAnimation.duration = 0;
//        inAnimation.beginTime = AVCoreAnimationBeginTimeAtZero + CMTimeGetSeconds(section.inTime);
//
//        CABasicAnimation *outAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//        outAnimation.removedOnCompletion = NO;
//        outAnimation.toValue = @0;
//        outAnimation.fillMode = kCAFillModeForwards;
//        outAnimation.duration = 0;
//        outAnimation.beginTime = AVCoreAnimationBeginTimeAtZero + CMTimeGetSeconds(section.outTime);
        
//        [sectionOverlayLayer addAnimation:inAnimation forKey:@"in"];
//        [sectionOverlayLayer addAnimation:outAnimation forKey:@"out"];
        
        // overlay
        for (int j = 0; j < section.overlays.count; j++) {
            MKMediaOverlay *overLay = section.overlays[j];
            CALayer *overlayElementLayer = [overLay overlayLayer];
            [sectionOverlayLayer addSublayer:overlayElementLayer];
        }
        
        [overlayContainerLayer addSublayer:sectionOverlayLayer];
    }
    
    CALayer *effectContainerLayer = [CALayer layer];
    effectContainerLayer.frame = parentLayer.frame;
    [parentLayer addSublayer:effectContainerLayer];
    
    for (MKMediaOverlay *effect in self.timeline.effects) {
        CALayer *layer = [effect overlayLayer];
        layer.frame = effectContainerLayer.bounds;
        [effectContainerLayer addSublayer:layer];
    }
    
    AVVideoCompositionCoreAnimationTool *tool =
    [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                                                                                 inLayer:parentLayer];
    
    return tool;
}

- (NSArray *)createAnimationLayersArray
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (int i = 0; i < self.timeline.sections.count; i++) {
        MKMediaSection *section = self.timeline.sections[i];
        
        // overlay
        for (int j = 0; j < section.overlays.count; j++) {
            MKMediaOverlay *overLay = section.overlays[j];
            CALayer *overlayElementLayer = [overLay overlayLayer];
            [array addObject:overlayElementLayer];
        }
    }
    
    for (MKMediaOverlay *effect in self.timeline.effects) {
        CALayer *layer = [effect overlayLayer];
        layer.frame = CGRectMake(0, 0, self.timeline.renderSize.width, self.timeline.renderSize.height);
        [array addObject:layer];
    }
    
    return array;
}

- (NSError *)errorWithCode:(MKMediaEditorErrorCode)errorCode
{
    NSErrorDomain domain = @"im.maka.media_editor_error_domain";
    return [NSError errorWithDomain:domain code:errorCode userInfo:nil];
}

#pragma mark - Helper

- (void)fastExportAVAsset:(AVAsset *)asset
                   toPath:(NSString *)filePath
                startTime:(CMTime)startTime
                  endTime:(CMTime)endTime
               completion:(MKMediaEditorContextExportCallback)completion
{
    if (!asset) {
        MKME_SAFE_BLOCK(completion, NO, nil);
        return;
    }
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    
    CMTimeRange range = CMTimeRangeMake(startTime, CMTimeSubtract(endTime, startTime));
    
    AVMutableComposition *comp = [AVMutableComposition composition];
    
    AVAssetTrack *videoAssetTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    if (videoAssetTrack) {
        AVMutableCompositionTrack *videoTrack =
        [comp addMutableTrackWithMediaType:AVMediaTypeVideo
                          preferredTrackID:kCMPersistentTrackID_Invalid];
        videoTrack.preferredTransform = videoAssetTrack.preferredTransform;
        
        NSError *err;
        [videoTrack insertTimeRange:range
                            ofTrack:videoAssetTrack
                             atTime:kCMTimeZero
                              error:&err];
        
        if (err) {
            MKME_SAFE_BLOCK(completion, NO, err);
            return;
        }
    }
    
    AVAssetTrack *audioAssetTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    if (audioAssetTrack) {
        AVMutableCompositionTrack *audioTrack =
        [comp addMutableTrackWithMediaType:AVMediaTypeAudio
                          preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSError *err;
        [audioTrack insertTimeRange:range
                            ofTrack:audioAssetTrack
                             atTime:kCMTimeZero
                              error:&err];
        
        if (err) {
            MKME_SAFE_BLOCK(completion, NO, err);
            return;
        }
    }
    
    AVAssetExportSession *session =
    [[AVAssetExportSession alloc] initWithAsset:comp
                                     presetName:AVAssetExportPresetHighestQuality];
    
    session.shouldOptimizeForNetworkUse = YES;
    session.outputURL = fileURL;
    session.outputFileType = AVFileTypeMPEG4;
    
    __weak typeof(session) ws = session;
    [session exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ws.error) {
                MKME_SAFE_BLOCK(completion, NO, ws.error);
                return;
            }
            
            MKME_SAFE_BLOCK(completion, YES, nil);
        });
    }];
}

@end
