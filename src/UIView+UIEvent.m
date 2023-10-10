#import "UIView+UIEvent.h"

#import "UIInputEvent+UIView.h"

#import "UIView+DebugPrivate.h"
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
   UIView   *view;

   mulle_pointerarray_for_reverse( &_subviews, view)
   {
      if( CGRectContainsPoint( [view frame], point))
         break;
   }
   return( view);
}


- (id <UILayer>) layerAtContentLocation:(CGPoint) point
{
   id <UILayer>   layer;
   CGRect         frame;

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

   rect = [self contentRect];
   flag = CGRectContainsPoint( rect, point);
   if( flag)
   {
      bounds = [self bounds];
      flag   = CGRectContainsPoint( bounds, point);
   }
   UIViewEventLogVerbose( event, "%s -> %btd", CGPointUTF8String( point), flag);
   return( flag);
}


- (BOOL) respondsToInputEvents
{
   if( ! [self isUserInteractionEnabled])
      return( NO);

   // if hidden or invisible
   if( [self isHidden] || ([self alpha] < 0.01))
      return( NO);
   return( YES);
}


// This method will get clobbered by UIView+UIResponder later, to
// implement a super call to UIResponder
- (UIMouseMotionEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) event
{
   // _mouseMotionEventCallback is never nil
   return( (self->_mouseMotionEventCallback)( self, event));
}


// This methods will get clobbered by UIView+UIResponder later, to
// implement a super call to UIResponder
- (UIEvent *) handleEvent:(UIEvent *) event
{
   // _eventCallback is never nil
   return( (self->_eventCallback)( self, event));
}


//
// this is no longer used by UIWindow to determine the view for 
// the event reception. If you pass in an event, the locationInView: of
// the event will be set, if the hitTest succeeds.
//
- (UIView *) hitTest:(CGPoint) point
           withEvent:(UIEvent *) event
{
   UIView   *view;
   CGPoint  contentLocation;
   UIView   *found;

   if( ! [self respondsToInputEvents])
   {
      UIViewEventLog( event, "Invisible or disabled view ignores event %#@", event);
      return( nil);
   }

   if( ! [self pointInside:point
                 withEvent:event])
   {
      UIViewEventLogVerbose( event, "Event %#@ does not hit", event);
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


//
// Enable "enclosing" views to filter events for the user interaction
// enabled subview, that will get the event.
//
// Check that the hit is inside and that the view is user
// interaction enabled, if not search subviews for a recipient.
//
// Q: isn't this always the main window though ? likely at first...
//    but it will then step through the nextUserInteractionEnabledViewAtPoint:
//    subviews, which will then use this method again.
//
// This functionality is needed for events that are transformed into different
// events, to be passed "forwards"
//
- (BOOL) directHitTest:(CGPoint) point
        withInputEvent:(UIInputEvent *) event
{
   if( ! [self respondsToInputEvents])
      return( NO);

   if( ! [self pointInside:point
                 withEvent:event])
      return( NO);

   [event _setLocation:point
               forView:self];
   return( YES);
}


- (UIView *) hitSearchSubviews:(CGPoint) contentLocation
         withInputEventPointer:(UIInputEvent **) event_p
{
   CGPoint        location;
   UIView         *view;
   UIView         *found;
   UIView         *best;
   UIInputEvent   *event;
   UIInputEvent   *oldEvent;

   if( ! event_p)
      return( nil);

   event    = *event_p;

   best     = nil;
   location = contentLocation;
   mulle_pointerarray_for_reverse( &_subviews, view)
   {
      // "view" is located in the contentRect of self, so location is with
      // respect to "view" now the location within the superview

      contentLocation = [view contentLocationForLocation:location];
      if( ! [view directHitTest:contentLocation
                 withInputEvent:event])
      {
         continue;
      }

      oldEvent = event;
      found    = [view hitSearchSubviews:contentLocation
                   withInputEventPointer:&event];
      if( event != oldEvent)
      {
         if( ! event)
         {
            *event_p = event;
            return( nil);
         }

         // need to recalc location now
         location = [self convertPoint:[event locationInWindow]
                              fromView:nil];
      }
      if( found && ! best)
         best = found;
   }

   *event_p = event;
   return( best ? best : self);
}

@end

