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

   rover = mulle_pointerarray_reverseenumerate( &_subviews);
   while( _mulle_pointerarrayreverseenumerator_next( &rover, (void **) &view))
      if( CGRectContainsPoint( [view frame], point))
         break;
   mulle_pointerarrayreverseenumerator_done( &rover);
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

   rover = mulle_pointerarray_reverseenumerate( &_layers);
   while( _mulle_pointerarrayreverseenumerator_next( &rover, (void **) &layer))
      if( CGRectContainsPoint( [layer frame], point))
         break;
   mulle_pointerarrayreverseenumerator_done( &rover);
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


- (UIMouseButtonEvent *) handleMouseButtonEvent:(UIMouseButtonEvent *) event
{
   SEL   sel;
   int   action;
   int   button;

   sel    = 0;
   action = [event action];
   button = [event button];

   if( action == UIEventButtonActionDown)
      _clickOrDrag._suppressUntilTimestamp = [event timestamp] +
                                             _clickOrDrag._mouseMotionSuppressionDelay;

   // for support of other buttons, subclass and override
   // handleMouseButtonEvent:
   //
   switch( button)
   {
      case UIEventMouseButtonLeft :
         switch( action)
         {
         case UIEventButtonActionDown :
            sel = @selector( mouseDown:);
            break;
         case UIEventButtonActionUp :
            sel = @selector( mouseUp:);
            break;
         }
         break;

      case UIEventMouseButtonRight  :
         switch( action)
         {
         case UIEventButtonActionDown   :
            sel = @selector( rightMouseDown:);
            break;
         case UIEventButtonActionUp :
            sel = @selector( rightMouseUp:);
            break;
         }
         break;

      case UIEventMouseButtonMiddle :
         switch( action)
         {
         case UIEventButtonActionDown   :
            sel = @selector( otherMouseDown:);
            break;
         case UIEventButtonActionUp :
            sel = @selector( otherMouseUp:);
            break;
         }
   }

   if( sel && [self respondsToSelector:sel])
   {
      event = [self performSelector:sel
                         withObject:event];
   }
   return( event);
}


// general idea: suppress mouseDragged events, until a certain amount of
//               time has passed.
- (UIMouseMotionEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) event
{
   uint64_t   state;
   SEL        sel;

   assert( [event isKindOfClass:[UIMouseMotionEvent class]]);

   if( _clickOrDrag._suppressUntilTimestamp > [event timestamp])
      return( nil);

   sel   = 0;
   state = [event buttonStates];
   if( state)
   {
      sel = @selector( mouseDragged:);
      if( ! (state & (1 << UIEventMouseButtonLeft)))
      {
         if( state & (1 << UIEventMouseButtonRight))
            sel = @selector( rightMouseDragged:);
         else
            sel = @selector( otherMouseDragged:);
      }
   }

   if( sel && [self respondsToSelector:sel])
   {
      event = [self performSelector:sel
                         withObject:event];
   }

#if 0
   //
   // classically, these events do not happen when there is no tracking
   // area set up. But I don't see the point, you just don't implement
   // mouseMoved: and then this should be fairly harmless ?
   //
   if( event && [self respondsToSelector:@selector( mouseMoved:)])
   {
      event = [self performSelector:sel
                         withObject:event];
   }
#endif

   return( event);
}


- (UIMouseScrollEvent *) handleMouseScrollEvent:(UIMouseScrollEvent *) event
{
   // scrollWheel: taken from AppKit
   // https://developer.apple.com/documentation/appkit/nsscrollview/1403494-scrollwheel?language=objc
   //
   if( event && [self respondsToSelector:@selector( scrollWheel:)])
      event = [self scrollWheel:event];

   return( event);
}


- (UIKeyboardEvent *) handleKeyboardEvent:(UIKeyboardEvent *) event
{
   uint64_t   state;
   SEL        sel;

   sel   = 0;
   switch( [event action])
   {
   case UIEventButtonActionRepeat  :  // do keyUp: and keyDown:
      sel = @selector( keyUp:);
      if( sel && [self respondsToSelector:sel])
      {
         // keep UIEventKeyRepeat as action, don't create new event
         // event return value ignored,as to not accidentally prohibit keyDown:
         [self performSelector:sel
                    withObject:event];
      }
      // fall thru

   case UIEventButtonActionDown   :
      sel = @selector( keyDown:);
      break;

   case UIEventButtonActionUp :
      sel = @selector( keyUp:);
      break;
   }

   if( sel && [self respondsToSelector:sel])
   {
      event = [self performSelector:sel
                         withObject:event];
   }
#ifdef EVENT_DEBUG
   MulleUILog( "#%@", event);
#endif

#if 0
   if( [event key] == GLFW_KEY_ESCAPE &&
       [event action] == UIEventButtonActionDown)
   {
#ifdef EVENT_DEBUG
      fprintf( stderr, "request close\n");
#endif
      [[self window] requestClose];

      return( nil);
   }
#endif

   return( event);
}


- (UIUnicodeEvent *) handleUnicodeEvent:(UIUnicodeEvent *) event
{
   uint64_t   state;
   SEL        sel;

   sel = @selector( unicodeCharacterEvent:);
   if( [self respondsToSelector:sel])
   {
      event = [self performSelector:sel
                         withObject:event];
   }
#ifdef EVENT_DEBUG
   MulleUILog( stderr, "#%@", event);
#endif
   return( event);
}


//
// This was written to support MulleMenu. But MulleMenu does it now
// differently.
//
- (void) subviewDidHandleInputEvent:(UIInputEvent *) event
{
   // pass it up, until noone cares anymore
   [[self superview] subviewDidHandleInputEvent:event];
}


- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event
{
   // Handle event myself

   if( [self isUserInteractionEnabled] == NO)
   {
#ifdef EVENT_DEBUG
       MulleUILog( "Disabled view ignores event %#@", event);
#endif
      return( event);
   }

#ifdef EVENT_DEBUG
    MulleUILog( "Try to handle event %#@", event);
#endif

   // this is never nil
   event = (self->_eventCallback)( self, event);

   switch( [event eventType])
   {
   case UIEventTypePresses :
      event = [self handleKeyboardEvent:(UIKeyboardEvent *) event];
      break;

   case UIEventTypeUnicode :
      event = [self handleUnicodeEvent:(UIUnicodeEvent *) event];
      break;

   case UIEventTypeTouches :
      event = [self handleMouseButtonEvent:(UIMouseButtonEvent *) event];
      break;

   case UIEventTypeMotion :
      event = [self handleMouseMotionEvent:(UIMouseMotionEvent *) event];
      break;

   case UIEventTypeScroll :
      event = [self handleMouseScrollEvent:(UIMouseScrollEvent *) event];

   default :
      break;
   }

   return( event);
}

#if 0
- (UIView *) subviewAcceptingInputEvent:(UIInputEvent *) event
                        contentLocation:(CGPoint) contentLocation
{
   struct mulle_pointerarrayreverseenumerator   rover;
   UIView                                       *view;
   BOOL                                         didHandleEvent;
   CGPoint                                      location;

   if( &_subviews)
   {
      rover = _mulle_pointerarray_reverseenumerate( &_subviews);
      while( _mulle_pointerarrayreverseenumerator_next( &rover, (void **) &view))
      {
         // "view" is located in the contentRect of self, so location is with
         // respect to "view" now the location within the superview
         location       = contentLocation;
         didHandleEvent = [view handleInputEvent:event
                                       location:location] == nil;
         if( didHandleEvent)
         {
            [self subviewDidHandleInputEvent:event];
            mulle_pointerarrayreverseenumerator_done( &rover);
            return( view);
         }
      }
      mulle_pointerarrayreverseenumerator_done( &rover);
   }

   return( nil);
}
#endif


// this does the hitTest
- (UIEvent *) handleInputEvent:(UIInputEvent *) event
                      location:(CGPoint) location
{
   CGPoint                               contentLocation;
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;
   UIEvent                               *result;

   assert( event);

   if( [self isHidden]) // alpha < 0.01: should we care for events ?
   {
#ifdef EVENT_DEBUG
       MulleUILog( "Invisible view ignores event %#@", event);
#endif
      return( event);
   }

   // from UIView+CGGeometry
   contentLocation = [self contentLocationForLocation:location];
#ifdef EVENT_DEBUG_VERBOSE
  MulleUILog( "translated: %s -> %s [c=%s]\n",
               CGPointUTF8String( location),
               CGPointUTF8String( contentLocation),
               CGRectUTF8String( [self contentRect]));
#endif

   view = [self hitTest:contentLocation
              withEvent:event];

   for(;;)
   {
      if( ! view)
      {
#ifdef EVENT_DEBUG_VERBOSE
         MulleUILog( "Event #%@ does not hit an interaction view", event);
#endif
         return( event);
      }

      if( [view isUserInteractionEnabled])
         break;

      view = [view superview];
   }

   result = [view handleInputEvent:event];
   if(  ! result && view != self)
      [self subviewDidHandleInputEvent:event];

   return( result);
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
   if( &_subviews)
   {
      rover = _mulle_pointerarray_reverseenumerate( &_subviews);
      while( _mulle_pointerarrayreverseenumerator_next( &rover, (void **) &view))
      {
         // "view" is located in the contentRect of self, so location is with
         // respect to "view" now the location within the superview
         contentLocation = [view contentLocationForLocation:point];
         found           = [view hitTest:contentLocation
                               withEvent:event];
         if( found)
            break;
      }
      mulle_pointerarrayreverseenumerator_done( &rover);
   }

   // if we found a subview the location set has been done already
   if( found)
      return( found);

   [(UIInputEvent *) event _setLocation:point
                                forView:self];
   return( self);
}

@end

