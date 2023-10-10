#import "UIView+CGGeometry.h"


#define DUMP_LAYERS


@interface NSObject ( UIWindow)

- (BOOL) __isUIWindow;

@end


@implementation UIView( CGGeometry)

- (CGPoint) contentLocationForLocation:(CGPoint) location
{
   CGPoint             contentLocation;
   CGAffineTransform   transform;

//   CGAffineTransform   identity;
//   identity   = CGAffineTransformMakeIdentity();
//   nvgTransformIdentity( transform);
   transform       = CGAffineTransformMakeInverseProjection( [self frame], [self bounds]);
//   transform = CGAffineTransformConcatFrameAndBoundsTransform( identity, [self frame], [self bounds]);
   contentLocation = CGPointApplyAffineTransformInline( location, transform);
//   nvgTransformPoint( &translated.x, &translated.y, transform, point.x, point.y);
   return( contentLocation);
}


- (CGPoint) locationForContentLocation:(CGPoint) location
{
   CGPoint             contentLocation;
   CGAffineTransform   transform;
//   CGAffineTransform   identity;

//   identity   = CGAffineTransformMakeIdentity();
//   nvgTransformIdentity( transform);
//   transform = CGAffineTransformConcatFrameAndBoundsInverseTransform( identity, [self frame], [self bounds]);
   transform       = CGAffineTransformMakeProjection( [self frame], [self bounds]);
   contentLocation = CGPointApplyAffineTransformInline( location, transform);
//   nvgTransformPoint( &translated.x, &translated.y, transform, point.x, point.y);
   return( contentLocation);
}



// Memo:
// prefer conversion from window to view, so floating point errors are
// the same as they are when we handle an event
//


#if 0
- (CGRect) convertRect:(CGRect) rect
              fromView:(UIView *) fromView
{
   CGRect                                        converted;
   UIView                                        *view;
   CGRect                                        frame;
   UIView                                        *views[ 32];
   struct mulle_pointerarray                     array;
   struct mulle__pointerarrayreverseenumerator   rover;

   _mulle__pointerarray_init_with_static_pointers( array, views, sizeof( views) / sizeof( UIView *));

   converted = rect;
   for( view = fromView; view; view = [view superview])
   {
      if( self == fromView)
         return( converted);

      frame               = [view frame];
      converted.origin.x -= frame.origin.x;
      converted.origin.y -= frame.origin.y;
      converted           = [self convertBoundsRectToFrameRect:converted];
   }

   /*
    *
    */
   for( view = self; view; view = [view superview])
      _mulle__pointerarray_add( views, view, NULL);

   rover = _mulle__pointerarray_reverseenumerator( views);
   while( _mulle__pointerarrayreverseenumerator_next( &rover, (void **) &view))
   {
      converted           = [self convertFrameRectToBoundsRect:converted];
      frame               = [view frame];
      converted.origin.x += frame.origin.x;
      converted.origin.y += frame.origin.y;
   }
   _mulle__pointerarrayreverseenumerator_done( &rover);

   _mulle__pointerarray_done( &views, NULL);

   return( converted);
}
#endif

/**
                     v--- point (src)
   window <- self{ bounds: }
   window -> view1 { bounds: } -> view2 { bounds: }
                                           ^----- point( dst)
*/



/*
 * These routines have been checked vs UIView (sic!) and they are compatible.
 * Replace: NSView -> UIView
 *          NSRect -> CGRect
 *          NSPoint -> CGPoint
 *          NSEqualSizes -> CGSizeEqualToSize
 */

// +--------------------[a frame]---------------------+
// | [a bounds]                                       |
// |          +----+.....[b frame].........+....+     |
// |          |    :     +----------+      |    :     |
// |          |    :     |   rect   |      |    :     |
// |          |    :     +----------+      |    :     |
// |          +--[b bounds}::::::::::::::::+....+     |
// |                                                  |
// +--------------------------------------------------+


//
// frame  = 0.0,0.0,1.0,1.0
// bounds = 0.0,0.0,0.5,0.5
// rect   = 0.5,0.5,0.5,0.5
//
// so rect is in the lower right quarter of bounds
// bounds has half the resolution of frame
//    +-------------frame--------------+
//    |  bounds                        |
//    |                                |
//    |               0.5              |
//    |           0.5 +................+
//    |               :                |
//    |               :      rect      |
//    |               :                |
//    +---------------+----------------+
//
static CGRect   convertFrameRectToBoundsRect( CGRect rect, CGRect frame, CGRect bounds)
{
   CGPoint  scale;

   if( ! CGSizeEqualToSize( frame.size, bounds.size))
   {
      if( frame.size.width == 0.0)
         scale.x = INFINITY;
      else
         scale.x = bounds.size.width / frame.size.width;

      if( frame.size.height == 0.0)
         scale.y = INFINITY;
      else
         scale.y = bounds.size.height / frame.size.height;

      rect.origin.x    *= scale.x;
      rect.origin.y    *= scale.y;
      rect.size.width  *= scale.x;
      rect.size.height *= scale.y;
   }

   rect.origin.x += bounds.origin.x;
   rect.origin.y += bounds.origin.y;

   return( rect);
}


//
// frame  = 0.0,0.0,1.0,1.0
// bounds = 0.0,0.0,0.5,0.5
// rect   = 0.25,0.25,0.25,0.25
//
// so rect is in the lower right quarter of bounds
// bounds has half the resolution of frame
//    +-------------frame--------------+
//    |  bounds                        |
//    |                                |
//    |               0.25             |
//    |          0.25 +................+
//    |               :                |
//    |               :      rect      |
//    |               :                |
//    +---------------+----------------+
//
static CGRect   convertBoundsRectToFrameRect( CGRect rect, CGRect bounds, CGRect frame)
{
   CGPoint  scale;

   rect.origin.x -= bounds.origin.x;
   rect.origin.y -= bounds.origin.y;

   if( ! CGSizeEqualToSize( frame.size, bounds.size))
   {
      if( bounds.size.width == 0.0)
         scale.x = 0;
      else
         scale.x = frame.size.width / bounds.size.width;

      if( bounds.size.height == 0.0)
         scale.y = 0;
      else
         scale.y = frame.size.height / bounds.size.height;

      rect.origin.x    *= scale.x;
      rect.origin.y    *= scale.y;
      rect.size.width  *= scale.x;
      rect.size.height *= scale.y;
   }

   return( rect);
}


//
// A-----B-----C
//  \
//   ----D
//
//  self  | toView  | down | up
// -------|---------|------|--------------
//   A    |    A    |   -  |  -
//   A    |    B    |   -  |  B
//   A    |    C    |   -  |  BC
//   A    |    D    |   -  |  D
//   B    |    A    |   A  |  -
//   B    |    C    |   A  |  BC
//   B    |    D    |   A  |  D
//   C    |    A    |  BA  |  -
//   C    |    B    |   B  |  -
//   C    |    D    |  BA  |  D
//   D    |    A    |   A  |  -
//   D    |    B    |   A  |  B
//   D    |    C    |   A  |  BC

// if self == B and toView == C, we will hit B, when going down from C
// and stop there. Then convert upwards only.
// if self == C and toView == B, we wont hit C, when going down from B
// so we stop at A. Then move upwards again to B and then C
// if self == B and toView == C, we will hit B, when going down from C

- (CGRect) convertRect:(CGRect) rect
                toView:(UIView *) toView
{
   CGRect                                        converted;
   CGRect                                        frame;
   CGRect                                        bounds;
   struct mulle__pointerarrayreverseenumerator   rover;
   struct mulle__pointerarray                    array;
   UIView                                        *view;
   UIView                                        *views[ 32];

   converted = rect;

   _mulle__pointerarray_init_with_static_pointers( &array,
                                                   (void **) views,
                                                   sizeof( views) / sizeof( UIView *));

// if toView is nil, first loop is bypassed, second loop runs to root as
// desired...

//   if( ! toView)
//   {
//      toView = (UIWindow *) [self window];
//      assert( toView);
//   }

   for( view = toView; view; view = [view superview])
   {
      if( view == self)
         goto up;

      if( ! [view __isUIWindow])
         _mulle__pointerarray_add( &array, view, NULL);
   }

   for( view = self; view; view = [view superview])
   {
      if( view == toView)
         goto done;

      if( ! [view __isUIWindow])
      {
         frame               = [view frame];
         bounds              = [view bounds];
         converted           = convertBoundsRectToFrameRect( converted, bounds, frame);
         converted.origin.x += frame.origin.x;
         converted.origin.y += frame.origin.y;
      }
      // convert direction to screen coordinates
   }

up:
   // either start at screen coordinates or at self
   rover = _mulle__pointerarray_reverseenumerate( &array);
   while( _mulle__pointerarrayreverseenumerator_next( &rover, (void **) &view))
   {
      frame               = [view frame];
      bounds              = [view bounds];
      converted.origin.x -= frame.origin.x;
      converted.origin.y -= frame.origin.y;
      converted           = convertFrameRectToBoundsRect( converted, frame, bounds);
   }
   _mulle__pointerarrayreverseenumerator_done( &rover);

done:
   _mulle__pointerarray_done( &array, NULL);

   return( converted);
}


- (CGRect) convertRect:(CGRect) rect
              fromView:(UIView *) fromView
{
   CGRect                                        converted;
   CGRect                                        frame;
   CGRect                                        bounds;
   struct mulle__pointerarrayreverseenumerator   rover;
   struct mulle__pointerarray                    array;
   UIView                                        *view;
   UIView                                        *views[ 32];

   converted = rect;

// if fromView is nil, first loop runs to root as desired...
// second loop is bypassed
//
//   if( ! fromView)
//   {
//      fromView = (UIWindow *) [self window];
//      assert( fromView);
//   }
//
   _mulle__pointerarray_init_with_static_pointers( &array,
                                                   (void **) views,
                                                   sizeof( views) / sizeof( UIView *));
   for( view = self; view; view = [view superview])
   {
      if( view == fromView)
         goto up;

      // don't add window
      if( ! [view __isUIWindow])
         _mulle__pointerarray_add( &array, view, NULL);
   }

   for( view = fromView; view; view = [view superview])
   {
      if( view == self)
         goto done;

      // don't add window
      if( ! [view __isUIWindow])
      {
         frame               = [view frame];
         bounds              = [view bounds];
         converted           = convertBoundsRectToFrameRect( converted, bounds, frame);
         converted.origin.x += frame.origin.x;
         converted.origin.y += frame.origin.y;
      }
      // convert direction to screen coordinates
   }

up:
   // either start at screen coordinates or at self
   rover = _mulle__pointerarray_reverseenumerate( &array);
   while( _mulle__pointerarrayreverseenumerator_next( &rover, (void **) &view))
   {
      frame               = [view frame];
      bounds              = [view bounds];
      converted.origin.x -= frame.origin.x;
      converted.origin.y -= frame.origin.y;
      converted           = convertFrameRectToBoundsRect( converted, frame, bounds);

   }
   _mulle__pointerarrayreverseenumerator_done( &rover);

done:
   _mulle__pointerarray_done( &array, NULL);

   return( converted);
}


#if 0
static CGPoint   convertFramePointToBoundsPoint( UIView *self, CGPoint point, CGRect frame)
{
   CGRect   bounds;
   CGPoint  scale;

   bounds = [self bounds];

   if( ! CGSizeEqualToSize( frame.size, bounds.size))
   {
      if( frame.size.width == 0.0)
         scale.x = INFINITY;
      else
         scale.x = bounds.size.width / frame.size.width;

      if( frame.size.height == 0.0)
         scale.y = INFINITY;
      else
         scale.y = bounds.size.height / frame.size.height;

      point.x *= scale.x;
      point.y *= scale.y;
   }

   point.x += bounds.origin.x;
   point.y += bounds.origin.y;

   return( point);
}


static CGPoint   convertBoundsPointToFramePoint( UIView *self, CGPoint point, CGRect frame)
{
   CGRect   bounds;
   CGPoint  scale;

   bounds   = [self bounds];

   point.x -= bounds.origin.x;
   point.y -= bounds.origin.y;

   if( ! CGSizeEqualToSize( frame.size, bounds.size))
   {
      if( bounds.size.width == 0.0)
         scale.x = 0;
      else
         scale.x = frame.size.width / bounds.size.width;

      if( bounds.size.height == 0.0)
         scale.y = 0;
      else
         scale.y = frame.size.height / bounds.size.height;

      point.x *= scale.x;
      point.y *= scale.y;
   }

   return( point);
}
#endif

// Reusing the rect code instead of a dedicated point routine,
// we "lose" two fp multiplications per conversion step
// for size/width, if bounds.size and frame.size differ, which
// they rarely do. It saves a lot of code
//
- (CGPoint) convertPoint:(CGPoint) point
                  toView:(UIView *) toView
{
   CGRect   rect;
   CGRect   converted;

   rect.origin      = point;
   rect.size.width  = 0.0;
   rect.size.height = 0.0;

   converted = [self convertRect:rect
                          toView:toView];
   return( converted.origin);
}


- (CGPoint) convertPoint:(CGPoint) point
                fromView:(UIView *) toView
{
   CGRect   rect;
   CGRect   converted;

   rect.origin      = point;
   rect.size.width  = 0.0;
   rect.size.height = 0.0;

   converted = [self convertRect:rect
                        fromView:toView];
   return( converted.origin);
}


- (CGRect) visibleWindowRect
{
   CGRect   rect;
   CGRect   parentBounds;
   UIView   *view;
   UIView   *parent;

   if( [self isHidden])
      return( CGRectZero);

   rect = [self bounds];  // will be converted to frame soon...

   // walk up the conversion chain and clip everything together, we
   // end up with a rect in window space
   for( view = self; (parent = [view superview]); view = parent)
   {
      // this oughta be fairly cheap, as we are only doing one step
      rect = [view convertRect:rect
                        toView:parent];

      if( [parent isHidden])
         return( CGRectNull);  // immediate bail

      // if it don't clip, we don't care
      if( ! [parent clipsToBounds])
         continue;

      parentBounds = [parent bounds];
      rect         = CGRectIntersection( parentBounds, rect);
   }

   return( rect);
}


- (CGRect) visibleRect
{
   CGRect   rect;

   rect = [self visibleWindowRect];
   // turn clipRect back to view space and clip
   rect = [self convertRect:rect
                   fromView:nil];
   return( rect);
}

@end
