//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
// prefer a local UIView over one in import.h
#import "UIView.h"


#import "UILayoutContext.h"


static inline struct UILayoutContext
   UILayoutContextMakeWithView( UIView *view)
{
   return( UILayoutContextMake( [view contentRect], [view padding]));
}



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
// will layout the all layers so that its frame equals the bounds, will leave
// all other layers untouched
//
- (void) layoutLayer:(id <UILayer>) layer
              inRect:(CGRect) bounds;


- (void) layoutWithContext:(struct UILayoutContext *) context
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


@interface UIView( LayoutFuture)

- (id <UILayoutContext>) layoutContext;

- (void) beginLayout:(void *) info;
- (void) endLayout;

// this flag is handled by UIWindow
- (void) setNeedsLayout    MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) needsLayout       MULLE_OBJC_THREADSAFE_METHOD;

- (void) layoutShadowLayer:(id <UILayer>) layer
                    inRect:(CGRect) rect;
@end


MULLE_UI_CORE_EXTERN_GLOBAL
void   UIViewAutoresize( UIView *self,
                         struct UILayoutContext *context,
                         UIViewAutoresizing autoresizingMask);

MULLE_UI_CORE_EXTERN_GLOBAL
void  UIViewLayoutWithContext( UIView *self, struct UILayoutContext *context);

MULLE_UI_CORE_EXTERN_GLOBAL
void   UIViewLayoutSubviewInRect( UIView *self, UIView *view, CGRect contentRect);
