//
//  UIAutoresizing.h
//  MulleUIView
//
//  Copyright (c) 2023 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "import.h"

//#import "UIEdgeInsets.h"


typedef NS_OPTIONS( NSUInteger, UIViewAutoresizing)
{
   UIViewAutoresizingNone                  = 0x00,


   // This is a simplified form "margins" resizing
   // UIViewAutoresizingTop and friends are used by UIStackView mainly.
   // You use this for automated layouts
   // The autoresize will run each layout (contrary to the "Flexible"/Legacy
   // autoresize).
   //  CGContentModeScaleToFill is same as UIViewAutoresizingFillBoth but is 0
   //   UIViewAutoresizingRedraw,  // not supported

   UIViewAutoresizingCenter                = CGContentModeCenterPoint,

   UIViewAutoresizingTop                   = CGContentModeTop,
   UIViewAutoresizingBottom                = CGContentModeBottom,
   UIViewAutoresizingLeft                  = CGContentModeLeft,
   UIViewAutoresizingRight                 = CGContentModeRight,

   UIViewAutoresizingTopLeft               = CGContentModeTopLeft,
   UIViewAutoresizingTopRight              = CGContentModeTopRight,
   UIViewAutoresizingBottomLeft            = CGContentModeBottomLeft,
   UIViewAutoresizingBottomRight           = CGContentModeBottomRight,

   UIViewAutoresizingScaleToFillHorizontal = CGContentModeScaleToFillHorizontal,
   UIViewAutoresizingScaleToFillVertical   = CGContentModeScaleToFillVertical,
   UIViewAutoresizingScaleToFill           = CGContentModeScaleToFill,
   UIViewAutoresizingScaleAspectFit        = CGContentModeScaleAspectFit,
   UIViewAutoresizingScaleAspectFill       = CGContentModeScaleAspectFill,


   //
   // "Flexible" is "legacy" resizing, you use this for manual layouts
   // The "Flexible" autoresize will only be triggered, if the parent view has 
   // changed shape. So when you place a view in its parent and run layout 
   // nothing will happen.
   //
   // It ignores "margins" but takes "padding" of the superview into account.
   // "Legacy" resizing uses the frame of the view has it was setup originally.
   // For example, if you have setup the superview "padding", then the view
   // must have been placed properly into the superview, so that it does not
   // overlap the padding. Legacy resizing tries to keep the view in its
   // relative position and uses the "Flexible" info for that. That's in
   // contrast to contentMode, which does not care about the original position.
   // See NSView/UIView for a description how this works
   //
   UIViewAutoresizingFlexibleTopMargin     = 0x010000,
   UIViewAutoresizingFlexibleBottomMargin  = 0x020000,

   UIViewAutoresizingFlexibleLeftMargin    = 0x040000,
   UIViewAutoresizingFlexibleRightMargin   = 0x080000,

   UIViewAutoresizingFlexibleHeight        = 0x100000,
   UIViewAutoresizingFlexibleWidth         = 0x200000,

   // 8 bits for legacy
   // 16 bits for contentMode (future)
   UIViewAutoresizingClipToBounds          = 0x1000000,    // clip to fit into bounds if smaller
   UIViewAutoresizingCullAtBounds          = 0x2000000,    // set to size 0.0 if exceeds bounds
   UIViewAutoresizingIntegralFrame         = 0x4000000,    // make frame values integers
   UIViewAutoresizingMixedMode             = 0x8000000     // intentional mix of legacy and contentMode
};

#define UIViewAutoresizingFlexibleSize      (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)

#define UIViewAutoresizingLegacyBits        0x003F0000
#define UIViewAutoresizingContentModeBits   0x0000FFFF


static inline CGContentMode   UIViewAutoresizingGetContentMode( UIViewAutoresizing bits)
{
   return( bits & UIViewAutoresizingContentModeBits);
}


MULLE_UI_VIEW_GLOBAL
NS_OPTIONS_TABLE( UIViewAutoresizing, 25);

static inline char  *UIViewAutoresizingUTF8String( UIViewAutoresizing bits)
{
   return( NS_OPTIONS_PRINT( UIViewAutoresizing, bits));
}


// "backwards" compatibility

static inline char *
   UIViewAutoresizingMaskUTF8String( UIViewAutoresizing bits)
{
   return( UIViewAutoresizingUTF8String( bits));
}

MULLE_UI_VIEW_GLOBAL
char *
UIViewAutoresizingMaskShortUTF8String( UIViewAutoresizing bits);


// ..Scale.. is changing the initial frame,
// ..Flexible.. is changing a resized frame
static inline BOOL   UIViewAutoresizingIsScaling( UIViewAutoresizing bits)
{
   return( (bits & (UIViewAutoresizingScaleToFillHorizontal
                   | UIViewAutoresizingScaleToFillVertical
                   | UIViewAutoresizingScaleToFill
                   | UIViewAutoresizingScaleAspectFit
                   | UIViewAutoresizingScaleAspectFill)) ? YES : NO);
}


static inline BOOL   UIViewAutoresizingIsFlexible( UIViewAutoresizing bits)
{
   return( (bits & (UIViewAutoresizingFlexibleHeight
                   | UIViewAutoresizingFlexibleWidth
                   | UIViewAutoresizingFlexibleTopMargin
                   | UIViewAutoresizingFlexibleBottomMargin
                   | UIViewAutoresizingFlexibleLeftMargin
                   | UIViewAutoresizingFlexibleRightMargin)) ? YES : NO);
}




#define UIAutoresizingProperties                \
   @property( assign) CGRect   originalFrame;   \
   @property( assign) CGRect   lastBounds

//
// MEMO: there is the object that autoresizes another object with
//       -autoresizeObject:inRect:autoresizingMask:. Both must inherit from
//       UIAutoresizing. But the resized object does not get queried for 
//       bounds and padding.
//
@mixin UIAutoresizing

UIAutoresizingProperties;

@required
- (CGRect) frame;         

@optional
- (UIEdgeInsets) margins;  // default UIEdgeInsetsZero;

- (CGRect) autoresizeWithLayoutInfo:(struct UILayoutInfo *) context
                autoresizingMask:(UIViewAutoresizing) autoresizingMask;

@end;


// A typical adopting class will look like this:
// @interface Adopter : NSObject < UIAutoresizing>
// UIAutoresizingProperties;
// @end
//
// @implementation Adopter
// @end


MULLE_UI_VIEW_GLOBAL
CGRect   UIAutoresizingLegacyResize( CGRect originalFrame,
                                     CGRect lastBounds,
                                     CGRect bounds,
                                     UIViewAutoresizing autoresizingMask);
