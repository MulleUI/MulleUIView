//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "UIView+Layout.h"

#import "import-private.h"

#import "UIView+DebugPrivate.h"
#import "UIView+CGGeometry.h"
#import "UIViewController.h"
//#import "UIEdgeInsets+UTF8String.h"

//#define LEGACY_DEBUG
//#define TRACKING_AREA_DEBUG

@interface NSObject ( Layout)

- (void) addLayoutedView:(UIView *) view;
- (BOOL) isLayoutedView:(UIView *) view;

@end


@interface UIView( Forward)

- (void) willChange;

@end


@implementation UIView ( Layout)

- (CGSize) sizeThatFits:(CGSize) size
                context:(id <UILayoutContext>) context;
{
   // TODO: should use inverse transform on size
   return( [_mainLayer sizeThatFits:size
                            context:context]);
}


// IDEAS, no gospel!
//
// If you have a variably sized view (likely something text based, like a
// UILabel: you have various scenarios:
//
// size is INFINITY, INFINITY. You use the default font, calculate the size
//                             needed, give it back.
// size is w/h                 Use truncation algorithm or whatever to fit
//                             into this size. Don't change the fontSize

// https://developer.apple.com/documentation/uikit/uiview/1622625-sizethatfits?language=objc
- (CGSize) sizeThatFits:(CGSize) size
{
   id <UILayoutContext>   context;

   context = [self layoutContext];
   return( [self sizeThatFits:size
                      context:context]);
}


//
// Enclose subviews by default. If there are none, enlarge to superview.
// Hope that's useful as default behaviour.
//
- (void) sizeToFit
{
   CGRect   frame;
   CGRect   rect;
   UIView   *view;
   UIView   *superview;

   rect = CGRectZero;
   UIViewSubviewsFor( self, view)
   {
      frame = [view frame];
      rect  = CGRectUnion( rect, frame);
   }

   superview = [self superview];
   if( CGRectGetArea( rect) == 0.0f)
      rect = [superview bounds];

   frame = [self convertRect:rect
                      toView:superview];

   [self setFrame:frame];
}


#pragma mark - layout


//
// by default, the mainLayer fills the contentRect of
// its owning UIView.
//
- (void) layoutLayer:(id <UILayer>) layer
              inRect:(CGRect) rect
{
   if( layer == _shadowLayer)
   {
      [self layoutShadowLayer:layer
                       inRect:rect];
   }

   if( layer == _mainLayer)
   {
      [layer setFrame:rect];
    //  [layer setBounds:[self bounds]]; ??
   }
}


//
// Layout:
//
// Easiest case: UIViewAutoresizingScaleToFill
//               and all margins are flexible.
//
// We take the margins and use them to inset the bounds. The resulting CGRect
// is our frame.
// If a margin isn't flexible, then we substitute the current margin for it.
//
// Harder case: A dimension isn't flexible.
//

- (UILayoutStrategy) layoutStrategy
{
   return( UILayoutStrategyDefault);
}


- (void) layoutLayers
{
   id <UILayer>   layer;
   CGRect         contentRect;

   contentRect = [self contentRect]; // not layoutRect

#ifdef HAVE_RENDER_CACHE
   if( _cacheLayer)
   {
      if( CGRectEqualToRect( contentRect, [_cacheLayer frame]))
         return;
      [_cacheLayer release];
      _cacheLayer = nil;
   }
#endif

   if( (*_willLayoutLayersCallback)( self))
   {
      if( _shadowLayer)
      {
         [self layoutLayer:_shadowLayer
                    inRect:contentRect];
      }

      [self layoutLayer:_mainLayer
                 inRect:contentRect];

      mulle_pointerarray_for( &_layers, layer)
      {
         [self layoutLayer:layer
                    inRect:contentRect];
      }
   }
   (*_didLayoutLayersCallback)( self);
}


- (void) setLayoutedFrame:(CGRect) frame
         autoresizingMask:(UIViewAutoresizing) autoresizingMask
{
#ifndef UIVIEW_FRAME_USES_CGRECTINTEGRAL
   if( autoresizingMask & UIViewAutoresizingIntegralFrame)
      frame = UIViewIntegralFrame( frame);
#endif
   if( ! CGRectEqualToRect( [self frame], frame))
      [self setFrame:frame];
}


void   UIViewAutoresize( UIView *self,
                         struct UILayoutContext *context,
                         UIViewAutoresizing autoresizingMask)
{
   CGRect   frame;

   frame = [self autoresizeWithContext:context
                      autoresizingMask:autoresizingMask];

   [self setLayoutedFrame:frame
         autoresizingMask:autoresizingMask];
}


- (void) layoutWithContext:(struct UILayoutContext *) context
          autoresizingMask:(UIViewAutoresizing) autoresizingMask
{
   if( [_controller layoutView:self
                 layoutContext:context
              autoresizingMask:autoresizingMask])
   {
      return;
   }

   UIViewAutoresize( self, context, autoresizingMask);
}



// "legacy" support
- (void) layoutSubview:(UIView *) subview
                inRect:(CGRect) contentRect
       autoresizingMask:(UIViewAutoresizing) autoresizingMask
{
   struct UILayoutContext   context;

   context = UILayoutContextMake( contentRect, [self padding]);
   [subview layoutWithContext:&context
             autoresizingMask:autoresizingMask];
}


void  UIViewLayoutWithContext( UIView *self, struct UILayoutContext *context)
{
   NSUInteger   autoresizingMask;

   autoresizingMask = [self autoresizingMask];
   UIViewLayoutLog( "layout Subview %@ %s (%s)",
                        self,
                        CGRectUTF8String( [self frame]),
                        UIViewAutoresizingMaskShortUTF8String( autoresizingMask));
   [self layoutWithContext:context
          autoresizingMask:autoresizingMask];
}


void   UIViewLayoutSubviewInRect( UIView *self, UIView *view, CGRect contentRect)
{
   NSUInteger   autoresizingMask;

   autoresizingMask = [view autoresizingMask];
   UIViewLayoutLog( "layout Subview %@ %s (%s)",
                        view,
                        CGRectUTF8String( [view frame]),
                        UIViewAutoresizingMaskShortUTF8String( autoresizingMask));
   [self layoutSubview:view
                inRect:contentRect
      autoresizingMask:autoresizingMask];
}



- (BOOL) layoutSubviews
{
   BOOL                     flag;
   UIView                   *view;
   struct UILayoutContext   context;

   if( (*_willLayoutSubviewsCallback)( self))
   {
      // TODO: could "cull" subviews here, that, after layout, are not
      //       visible.. is this beneficial ?
      //
      context = UILayoutContextMakeWithView( self);
      UIViewSubviewsFor( self, view)
      {
         UIViewLayoutWithContext( view, &context);
      }
   }
   flag = (*_didLayoutSubviewsCallback)( self);
   return( flag);
}


- (void) _setFrame:(CGRect) frame
{
   BOOL   flag;
   // keep
   // if( _lastBounds.size.width == 0.0)
   //   _lastBounds = [self bounds];
   frame = UIViewMakeFrameWithRect( frame);
   flag  = ! CGRectEqualToRect( _frame, frame);
   if( flag)
   {
      UIViewLayoutLog( "-> frame %s", CGRectUTF8String( _frame));
      UIViewMouseTrackingEventLog( nil, "Tracking areas need updates");
      _needsTrackingAreaUpdate = flag;
      // [[self window] setViewsNeedTrackingAreaUpdate:YES];
   }

   _frame = frame;
}


- (void) setFrame:(CGRect) frame
{
   assert( ! [(id) [self window] isLayoutedView:self]);

   [self willChange];
   [self _setFrame:frame];
}


- (void) performLayoutOnSubviews
{
   UIView   *view;

   UIViewSubviewsFor( self, view)
   {
      [view layout];
   }
}

//
// Layouting is strictly top/down. Space is distributed from the top to
// the button via bounds/frame and the code in "layoutSubviews" that
// distributes it.
//
// https://developer.apple.com/documentation/uikit/uiview/1622585-hidden?language=objc:
// A hidden view ... remains in its superview’s list of subviews ... and 
// participates in autoresizing.
//
- (void) layout
{
#ifndef NDEBUG
   [(id) [self window] addLayoutedView:self];
#endif
   /*
    * TOP/DOWN
    */
   // [self setNeedsLayout:NO];

   // start Yoga
   switch( [self layoutStrategy])
   {
   case UILayoutStrategyDefault:
   case UILayoutStrategyContinue :
      break;

   case UILayoutStrategyStop:  // yoga says this because its doing it all
      return;
   }

   UIViewLayoutLog( "frame %s ->", CGRectUTF8String( _frame));

   // this is the flat possibly hardcoded code, that layouts each layer
   [self layoutLayers];

   //
   // this is the flat possibly hardcoded code, that layouts each subview
   // skip if there are none

   if( UIViewSubviewsCount( self)) // this is too likely not to check
   {
      if( [self layoutSubviews])
      {
         //
         // this is recursive code, triggering possibly more autoresizes
         // or yogas..
         //
         [self performLayoutOnSubviews];
      }
   }


   // now subviews are layouted, so _lastBounds can be reset to zero
   // is this necessary though ?
   // _lastBounds.size.width = 0.0;
}


- (BOOL) isCulledByLayout
{
   return( _frame.size.width == 0.0);
}

@end
