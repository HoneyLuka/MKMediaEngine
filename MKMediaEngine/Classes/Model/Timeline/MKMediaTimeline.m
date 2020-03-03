//
//  MKMediaTimeline.m
//  TestProject
//
//  Created by Luka Li on 4/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaTimeline.h"

@interface MKMediaTimeline ()

@property (nonatomic, strong) NSMutableArray<MKMediaSection *> *sections;

@end

@implementation MKMediaTimeline

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - Section

- (MKMediaSection *)appendSection
{
    MKMediaSection *s = [MKMediaSection new];
    [self.sections addObject:s];
    
    return s;
}

#pragma mark - Effect

- (void)appendEffect:(MKMediaOverlay *)effect inTime:(CMTime)inTime duration:(CMTime)duration
{
    effect.inTime = inTime;
    effect.outTime = CMTimeAdd(inTime, duration);
    [self.effects addObject:effect];
}

- (void)reload
{
    for (int i = 0; i < self.sections.count; i++) {
        MKMediaSection *section = self.sections[i];
        section.sectionIndex = i;
        [section reload];
    }
    
    if (self.passthoughAudio) {
        MKMediaAudioClip *clip = self.passthoughAudio;
        CMTime totalDuration = self.sections.lastObject.outTime;
        [clip changeClipDuration:totalDuration];
    }
}

#pragma mark - Getter

- (NSMutableArray<MKMediaSection *> *)sections
{
    if (!_sections) {
        _sections = [NSMutableArray array];
    }
    
    return _sections;
}

- (NSMutableArray<MKMediaOverlay *> *)effects
{
    if (!_effects) {
        _effects = [NSMutableArray array];
    }
    
    return _effects;
}

@end
