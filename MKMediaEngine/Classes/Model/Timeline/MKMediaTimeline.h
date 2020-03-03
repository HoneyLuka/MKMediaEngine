//
//  MKMediaTimeline.h
//  TestProject
//
//  Created by Luka Li on 4/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaObject.h"
#import "MKMediaAudioClip.h"
#import "MKMediaSection.h"
#import "MKMediaAnimatedImageOverlay.h"

@interface MKMediaTimeline : MKMediaObject

@property (nonatomic, strong, readonly) NSMutableArray<MKMediaSection *> *sections;
@property (nonatomic, strong) NSMutableArray<MKMediaOverlay *> *effects;

@property (nonatomic, strong) MKMediaAudioClip *passthoughAudio;

@property (nonatomic, assign) CGSize renderSize;
@property (nonatomic, assign) CGFloat framePerSecond;

- (MKMediaSection *)appendSection;

- (void)appendEffect:(MKMediaOverlay *)effect inTime:(CMTime)inTime duration:(CMTime)duration;

- (void)reload;

@end
