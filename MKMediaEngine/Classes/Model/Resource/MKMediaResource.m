//
//  MKMediaResource.m
//  TestProject
//
//  Created by Luka Li on 4/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaResource.h"

@interface MKMediaResource ()

@property (nonatomic, strong) NSURL *resourceURL;
@property (nonatomic, strong) AVAsset *asset;

@property (nonatomic, assign) CGAffineTransform assetTransform;
@property (nonatomic, assign) CGSize assetSize;

@end

@implementation MKMediaResource

- (instancetype)initWithURL:(NSURL *)resourceURL
{
    self = [super init];
    self.resourceURL = resourceURL;
    self.asset = [AVAsset assetWithURL:resourceURL];
    [self prepareForResource];
    return self;
}

- (instancetype)initWithAsset:(AVAsset *)asset
{
    self = [super init];
    self.asset = asset;
    [self prepareForResource];
    return self;
}

- (void)prepareForResource
{
    AVAssetTrack *track = [self videoTrack];
    self.assetTransform = track.preferredTransform;
    self.assetSize = track.naturalSize;
}

- (CMTime)duration
{
    return self.asset.duration;
}

- (AVAssetTrack *)videoTrack
{
    return [self.asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
}

- (AVAssetTrack *)audioTrack
{
    return [self.asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
}

@end
