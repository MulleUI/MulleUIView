#import "UIView+UIEvent.h"

#import "UIInputEvent+UIView.h"

#import "UIView+CGGeometry.h"



//#define EVENT_DEBUG
//#define EVENT_DEBUG_VERBOSE
// #define HITTEST_DEBUG

@implementation UIView ( UIEvent)

+ (CGFloat) mouseMotionSuppressionDelay
{
   return( 0.1);
}


// flat, doesn't recurse
- (UIView *) subviewAtContentLocation:(CGPoint) point
{
   struct mulle_pointerarrayreverseenumerator   rover;
   UIView                                       *view;

   mulle_pointerarray_for_reverse( &_subviews, view)
   {
      if( CGRectContainsPoint( [view frame], point))
         break;
   }
   return( view);
}


- (id <UILayer>) layerAtContentLocation:(CGPoint) point
{
   struct mulle_pointerarrayreverseenumerator   rover;
   id <UILayer>                                 layer;
   CGRect                                       frame;

   frame    = [self frame];
   point.x += frame.origin.x;
   point.y += frame.origin.y;

   mulle_pointerarray_for_reverse( &_layers, layer)
   {
      if( CGRectContainsPoint( [layer frame], point))
         break;
   }
   return( layer);
}


- (BOOL) pointInside:(CGPoint) point
           withEvent:(UIEvent *) event
{
   BOOL     flag;
   CGRect   rect;
   CGRect   bounds;

   rect   = [self contentRect];
   flag = CGRectContainsPoint( rect, point);
   if( flag)
   {
      bounds = [self bounds];
      flag   = CGRectContainsPoint( bounds, point);
   }
#ifdef HITTEST_DEBUG
   MulleUILog( "%s -> %btd",
                  CGPointUTF8String( point),
                  flag);
#endif
   return( flag);
}


- (UIView *) hitTest:(CGPoint) point
           withEvent:(UIEvent *) event
{
   UIView                                       *view;
   struct mulle_pointerarrayreverseenumerator   rover;
   CGPoint                                      contentLocation;
   UIView                                       *found;

   assert( event);

   if( [self isHidden]) // alpha < 0.01: should we care for events ?
   {
#ifdef EVENT_DEBUG
       MulleUILog( "Invisible view ignores event %#@", event);
#endif
      return( nil);
   }

   if( ! [self pointInside:point
                 withEvent:event])
   {
#ifdef EVENT_DEBUG_VERBOSE
      MulleUILog( "Event #%@ does not hit", event);
#endif
      return( nil);
   }

   found = nil;
   mulle_pointerarray_for_reverse( &_subviews, view)
   {
      // "view" is located in the contentRect of self, so location is with
      // respect to "view" now the location within the superview
      contentLocation = [view contentLocationForLocation:point];
      found           = [view hitTest:contentLocation
                              withEvent:event];
      if( found)
         break;
   }

   // if we found a subview the location set has been done already
   if( found)
      return( found);

   [(UIInputEvent *) event _setLocation:point
                                forView:self];
   return( self);
}

@end

