//
//  MKClip.h
//  MKAVExportDemo
//
//  Created by Luka Li on 20/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#import "MKMediaObject.h"

@interface MKClip : MKMediaObject

@property (nonatomic, assign, readonly) CMTime clipDuration;

@property (nonatomic, assign) CMTime inTime;
@property (nonatomic, assign) CMTime outTime;

- (BOOL)containsTime:(CMTime)time;

@end
