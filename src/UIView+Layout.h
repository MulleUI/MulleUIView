//
//  UIView+Layout.h
//  MulleUIView
//
//  Copyright (c) 2020 Nat! - Mulle kybernetiK.
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
#import "UIView.h"


typedef NS_ENUM( NSUInteger, UILayoutStrategy)
{
   UILayoutStrategyDefault,
   UILayoutStrategyContinue,
   UILayoutStrategyStop
};


/*
 * The layout first calls layoutLayers and then calls layoutSubviews.
 *
 * A UIView has some properties that define its wishes how to be placed
 * into a superview. First of all is the frame. If the autoresizingMask of
 * the view is UIViewAutoresizingNone, then the frame is absolute and should
 * not be changed ever by the superview.
 *
 * Otherwise the UIView can indicate, if it wants to be stretched
 * in a horizontal or vertical fashion or both.
 *
 * A stretched view will cover the entire given bounds. The given bounds are
 * reduced by the margins though. That effectively creates some distance from
 * the bounds.
 *
 * The non stretchable dimension can indicate a preferred sticking point,
 * which could be top/left for example.
 */
enum
{
   UILayoutConstraintAxisVerticalIndex   = CGVerticalAxisIndex,
   UILayoutConstraintAxisHorizontalIndex = CGHorizontalAxisIndex
};

typedef NSInteger   UILayoutConstraintAxisIndex;


static inline BOOL
   UIViewAutoresizingIsFlexibleInAxis( UIViewAutoresizing bits,
                                       UILayoutConstraintAxisIndex index)
{
   NSUInteger   mask;

   mask = (index == UILayoutConstraintAxisHorizontalIndex)
         ? UIViewAutoresizingFlexibleLeftMargin
           | UIViewAutoresizingFlexibleWidth
           | UIViewAutoresizingFlexibleRightMargin
           | CGContentModeScaleToFillHorizontal
         : UIViewAutoresizingFlexibleTopMargin
           | UIViewAutoresizingFlexibleHeight
           | UIViewAutoresizingFlexibleBottomMargin
           | CGContentModeScaleToFillVertical;
   return( (bits & mask) ? YES : NO);
}



@interface UIView( Layout)

// actual method: context is usually CGContext
- (CGSize) sizeThatFits:(CGSize) size
                context:(id <UILayoutContext>) context;

- (CGSize) sizeThatFits:(CGSize) size;

- (void) sizeToFit;

//
// You do not need not to call super in UIView subclasses, if you manually
// layout everything.
//

// layoutSubviews will call -layoutSubview:inRect:autoresizingMask: on all
// subviews. The bounds passed will be the -layoutRect. If you return NO
// -layout will not be called recursively on all subviews.
// You should not call layoutSubviews on its own, since it doesn't affect
// the layers of the subview.
//                
- (BOOL) layoutSubviews;

//
// layoutLayers will call -layoutSubview:inRect: on each layer. Bounds will
// be the -bounds. .
//
- (void) layoutLayers;

// loops over subviews and calls -layout on them
- (void) performLayoutOnSubviews;

// basically: 
//  if( [self layoutStrategy] != UILayoutStrategyStop)
//  {
//     [self layoutLayers];
//     if( [self layoutSubviews])
//        [self performLayoutOnSubviews];
//  }
- (void) layout;

//
// will layout the main layers so that its frame equals the bounds, will leave
// all other layers untouched
//
- (void) layoutLayer:(id <UILayer>) layer
          layoutInfo:(struct UILayoutInfo *) info;

- (void) layoutMainLayer:(id <UILayer>) layer
              layoutInfo:(struct UILayoutInfo *) info;

- (void) layoutAuxillaryLayer:(id <UILayer>) layer
                   layoutInfo:(struct UILayoutInfo *) info;


- (void) layoutWithLayoutInfo:(struct UILayoutInfo *) context
             autoresizingMask:(UIViewAutoresizing) autoresizingMask;


// used by UIViewController to set the layouted frame
- (void) setLayoutedFrame:(CGRect) frame
         autoresizingMask:(UIViewAutoresizing) autoresizingMask;

// this method was used before -layoutWithContext:autoresizingMask: was written
// its in here to support older code
- (void) layoutSubview:(UIView *) subview
                inRect:(CGRect) contentRect
      autoresizingMask:(UIViewAutoresizing) autoresizingMask;

// yoga uses this to its layout
- (UILayoutStrategy) layoutStrategy;

// if layout can't fit it in, or subview is out of bounds
// its frame.size is set to zero. The original size is kept in -mulleLayoutSize
// it's better to check this method though as I might change by mind...
- (BOOL) isCulledByLayout;

// will not assert
- (void) _setFrame:(CGRect) frame;

@end


@interface UIView( LayoutFuture) < MulleObjCFuture>

- (id <UILayoutContext>) layoutContext;

- (void) beginLayout:(void *) info;  // CGFrameInfo
- (void) endLayout;

// this flag is handled by UIWindow
- (void) setNeedsLayout    MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) needsLayout       MULLE_OBJC_THREADSAFE_METHOD;

- (void) layoutShadowLayer:(id <UILayer>) layer
                layoutInfo:(struct UILayoutInfo *) info;
@end



static inline struct UILayoutInfo  UILayoutInfoMakeWithView( UIView *view)
{
   assert( [view isKindOfClass:[UIView class]]);

   return( UILayoutInfoMake( [view contentRect],
                             [view padding],
                             [view layoutContext]));
}



MULLE_UI_VIEW_GLOBAL
void   UIViewAutoresize( UIView *self,
                         struct UILayoutInfo *info,
                         UIViewAutoresizing autoresizingMask);

MULLE_UI_VIEW_GLOBAL
void  UIViewLayoutWithViewLayoutInfo( UIView *self, struct UILayoutInfo *context);

MULLE_UI_VIEW_GLOBAL
void   UIViewLayoutSubviewInRect( UIView *self, UIView *view, CGRect contentRect);
