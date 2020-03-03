//
//  MKMediaResource.h
//  TestProject
//
//  Created by Luka Li on 4/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaObject.h"

@interface MKMediaResource : MKMediaObject

@property (nonatomic, strong, readonly) NSURL *resourceURL;
@property (nonatomic, strong, readonly) AVAsset *asset;

@property (nonatomic, assign, readonly) CMTime duration;

- (instancetype)initWithURL:(NSURL *)resourceURL;
- (instancetype)initWithAsset:(AVAsset *)asset;

#pragma mark - Video

@property (nonatomic, assign, readonly) CGAffineTransform assetTransform;
@property (nonatomic, assign, readonly) CGSize assetSize;

- (AVAssetTrack *)videoTrack;

#pragma mark - Audio

- (AVAssetTrack *)audioTrack;

@end
