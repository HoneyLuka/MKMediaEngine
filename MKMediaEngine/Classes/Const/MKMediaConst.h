//
//  MKMediaConst.h
//  TestProject
//
//  Created by Luka Li on 4/12/2019.
//  Copyright © 2019 Luka Li. All rights reserved.
//

#ifndef MKMediaConst_h
#define MKMediaConst_h

#define MKME_SAFE_BLOCK(BlockName, ...) ({ !BlockName ? nil : BlockName(__VA_ARGS__); })

#define MKME_PASSTHOUGH_AUDIO_TRACK_ID (-999999)

typedef NS_ENUM(NSUInteger, MKMediaEditorContextStatus) {
    MKMediaEditorContextStatusIdle,
    MKMediaEditorContextStatusEditing,
    MKMediaEditorContextStatusExporting,
};

typedef NS_ENUM(NSInteger, MKMediaEditorErrorCode) {
    MKMediaEditorErrorCodeNone,
    MKMediaEditorErrorCodeWrongStatus,
    MKMediaEditorErrorCodeInternalError,
};

typedef NS_ENUM(NSUInteger, MKMediaVideoTransitionType) {
    MKMediaVideoTransitionTypeNone,
    MKMediaVideoTransitionTypeDissolve,
};

static inline CALayerContentsGravity convertContentMode(UIViewContentMode mode) {
    switch (mode) {
        case UIViewContentModeScaleToFill:
            return kCAGravityResize;
        case UIViewContentModeScaleAspectFit:
            return kCAGravityResizeAspect;
        case UIViewContentModeScaleAspectFill:
            return kCAGravityResizeAspectFill;
        case UIViewContentModeCenter:
            return kCAGravityCenter;
        case UIViewContentModeTop:
            return kCAGravityTop;
        case UIViewContentModeBottom:
            return kCAGravityBottom;
        case UIViewContentModeLeft:
            return kCAGravityLeft;
        case UIViewContentModeRight:
            return kCAGravityRight;
        case UIViewContentModeTopLeft:
            return kCAGravityTopLeft;
        case UIViewContentModeTopRight:
            return kCAGravityTopRight;
        case UIViewContentModeBottomLeft:
            return kCAGravityBottomLeft;
        case UIViewContentModeBottomRight:
            return kCAGravityBottomRight;
        default:
            return kCAGravityResize;
    }
}

#endif /* MKMediaConst_h */
