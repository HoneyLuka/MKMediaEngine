//
//  MKMediaCustomCompositor.m
//  MKAVExportDemo
//
//  Created by Luka Li on 13/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaCustomCompositor.h"
#import <GPUImage/GPUImage.h>
#import <YUGPUImageCVPixelBufferInput/YUGPUImageCVPixelBufferInput.h>

@interface MKMediaCustomCompositor ()
{
    BOOL                                _shouldCancelAllRequests;
    dispatch_queue_t                    _renderingQueue;
    dispatch_queue_t                    _renderContextQueue;
    AVVideoCompositionRenderContext*    _renderContext;
    GPUImageRawDataOutput*              _rawDataOutput;
    CGSize                              _renderSize;
    
    MKMediaTimeline*                    _timeline;
}

@property (nonatomic, strong) NSMutableDictionary *bufferInputDict;

@end

@implementation MKMediaCustomCompositor

- (NSMutableDictionary *)bufferInputDict
{
    if (!_bufferInputDict) {
        _bufferInputDict = [NSMutableDictionary dictionary];
    }
    
    return _bufferInputDict;
}

- (YUGPUImageCVPixelBufferInput *)bufferInputForTrackID:(CMPersistentTrackID)trackID
{
    YUGPUImageCVPixelBufferInput *input = self.bufferInputDict[@(trackID)];
    if (!input) {
        input = [YUGPUImageCVPixelBufferInput new];
        [self.bufferInputDict setObject:input forKey:@(trackID)];
    }
    
    return input;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _renderingQueue = dispatch_queue_create("com.apple.aplcustomvideocompositor.renderingqueue", DISPATCH_QUEUE_SERIAL);
        _renderContextQueue = dispatch_queue_create("com.apple.aplcustomvideocompositor.rendercontextqueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)createRawDataOutputForSize:(CGSize)size timeline:(MKMediaTimeline *)timeline
{
    _renderSize = size;
    _rawDataOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:_renderSize resultsInBGRAFormat:YES];
    _timeline = timeline;
}

#pragma mark - AVVideoCompositing

- (NSDictionary *)sourcePixelBufferAttributes
{
    NSArray<NSNumber *> *formatsSupported = @[[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]];

    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : formatsSupported,
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext
{
    NSArray<NSNumber *> *formatsSupported = @[[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]];
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : formatsSupported,
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext
{
    dispatch_sync(_renderContextQueue, ^{
        self->_renderContext = newRenderContext;
    });
}

 - (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request
{
    @autoreleasepool {
        dispatch_async(_renderingQueue,^() {
            
            // Check if all pending requests have been cancelled
            if (self->_shouldCancelAllRequests) {
                [request finishCancelledRequest];
            } else {
                NSError *err = nil;
                // Get the next rendererd pixel buffer
                CVPixelBufferRef resultPixels = [self newRenderedPixelBufferForRequest:request error:&err];
                
                if (resultPixels) {
                    // The resulting pixelbuffer from OpenGL renderer is passed along to the request
                    [request finishWithComposedVideoFrame:resultPixels];
                    CFRelease(resultPixels);
                } else {
                    [request finishWithError:err];
                }
            }
        });
    }
}

- (void)cancelAllPendingVideoCompositionRequests
{
    // pending requests will call finishCancelledRequest, those already rendering will call finishWithComposedVideoFrame
    _shouldCancelAllRequests = YES;
    
    dispatch_barrier_async(_renderingQueue, ^() {
        // start accepting requests again
        self->_shouldCancelAllRequests = NO;
    });
}

#pragma mark - Utilities

- (MKMediaVideoClip *)videoClipByTrackID:(CMPersistentTrackID)trackID
{
    for (int i = 0; i < _timeline.sections.count; i++) {
        MKMediaSection *section = _timeline.sections[i];
        for (int j = 0; j < section.videoClips.count; j++) {
            MKMediaVideoClip *clip = section.videoClips[j];
            if (clip.videoTrackID == trackID) {
                return clip;
            }
        }
    }
    
    return nil;
}

- (NSArray *)videoClipsByTrackIDs:(NSArray *)trackIDs
{
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < trackIDs.count; i++) {
        NSNumber *trackIDObj = trackIDs[i];
        int32_t trackID = trackIDObj.intValue;
        
        MKMediaVideoClip *clip = [self videoClipByTrackID:trackID];
        [array addObject:clip];
    }
    
    [array sortUsingComparator:^NSComparisonResult(MKMediaVideoClip *obj1, MKMediaVideoClip *obj2) {
        if (obj1.videoTrackID > obj2.videoTrackID) {
            return NSOrderedDescending;
        }
        
        if (obj1.videoTrackID < obj2.videoTrackID) {
            return NSOrderedAscending;
        }
        
        return NSOrderedSame;
    }];
    
    return array;
}

- (MKMediaSection *)sectionByTime:(CMTime)time
{
    for (MKMediaSection *section in _timeline.sections) {
        if ([section containsTime:time]) {
            return section;
        }
    }
    
    return nil;
}

- (GPUImageOutput *)createVideosLayerOutput:(NSArray *)clips requestTime:(CMTime)requestTime
{
    GPUImageOutput<GPUImageInput> *previousBlender = nil;
    
    for (int i = 0; i < clips.count; i++) {
        MKMediaVideoClip *clip = clips[i];
        YUGPUImageCVPixelBufferInput *input = [self bufferInputForTrackID:clip.videoTrackID];
        [input removeAllTargets];
        
        GPUImageOutput<GPUImageInput> *filter = [clip filterByTime:requestTime timeline:_timeline];
        if (!filter) {
            NSAssert(NO, @"");
            return nil;
        }
        
        [input addTarget:filter];
        
        if (clips.count == 1) {
            previousBlender = filter;
            break;
        }
        
        if (i < 2) {
            if (!previousBlender) {
                previousBlender = [GPUImageNormalBlendFilter new];
            }
            [filter addTarget:previousBlender];
        } else {
            GPUImageNormalBlendFilter *blender = [GPUImageNormalBlendFilter new];
            [previousBlender addTarget:blender];
            [filter addTarget:blender];
            previousBlender = blender;
        }
    }
    
    return previousBlender;
}

- (CVPixelBufferRef)newRenderedPixelBufferForRequest:(AVAsynchronousVideoCompositionRequest *)request error:(NSError **)errOut
{
    const CGSize renderSize = _renderContext.size;
    const CMTime requestTime = request.compositionTime;
    
    NSLog(@"rendering = %f", CMTimeGetSeconds(requestTime));
    
    if (CGSizeEqualToSize(_renderSize, renderSize) == NO) {
        [_rawDataOutput setImageSize:renderSize];
    }
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [_rawDataOutput setNewFrameAvailableBlock:^{
        dispatch_semaphore_signal(sema);
    }];
    
    if (!request.sourceTrackIDs.count) {
        return [_renderContext newPixelBuffer];
    }
    
    NSArray *clips = [self videoClipsByTrackIDs:request.sourceTrackIDs];
    
    // video
    GPUImageOutput *videoLayersOutput = [self createVideosLayerOutput:clips requestTime:requestTime];
    if (!videoLayersOutput) {
        NSAssert(NO, @"");
        return [_renderContext newPixelBuffer];
    }
    
    GPUImageOutput *blend = videoLayersOutput;
    
    MKMediaSection *currentSection = [self sectionByTime:requestTime];
    
    // bg
    MKMediaBg *bg = currentSection.bg;
    if (bg) {
        GPUImageOutput *bgOutput = [bg bgOutputWithTimeline:_timeline];
        GPUImageNormalBlendFilter *bgBlend = [GPUImageNormalBlendFilter new];

        [bgOutput addTarget:bgBlend];
        [videoLayersOutput addTarget:bgBlend];

        blend = bgBlend;
    }
    
    [blend addTarget:_rawDataOutput];
    
    for (int i = 0; i < clips.count; i++) {
        MKMediaVideoClip *clip = clips[i];
        YUGPUImageCVPixelBufferInput *input = [self bufferInputForTrackID:clip.videoTrackID];
        CVBufferRef sourceBuffer = [request sourceFrameByTrackID:clip.videoTrackID];
        [input processCVPixelBuffer:sourceBuffer frameTime:requestTime];
    }
    
    dispatch_time_t bufferProcessTimeout = dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC);
    long result = dispatch_semaphore_wait(sema, bufferProcessTimeout);
    if (result != 0) {
        NSAssert(NO, @"");
        return NULL;
    }
    
    [_rawDataOutput lockFramebufferForReading];
    GLubyte *outputBytes = [_rawDataOutput rawBytesForImage];
    NSAssert(outputBytes != NULL, @"outputBytes should not be NULL");
    NSInteger bytesPerRow = [_rawDataOutput bytesPerRowInOutput];
    [_rawDataOutput unlockFramebufferAfterReading];
    
    CVPixelBufferRef nextFramePixels = [_renderContext newPixelBuffer];
    CVPixelBufferLockBaseAddress(nextFramePixels, 1);
    uint8_t *nextFramePixelsBaseAddress = CVPixelBufferGetBaseAddress(nextFramePixels);
    memcpy(nextFramePixelsBaseAddress, outputBytes, renderSize.height * bytesPerRow);
    CVPixelBufferUnlockBaseAddress(nextFramePixels, 1);
    
    return nextFramePixels;
}

@end
