#import "UIView+UIEvent.h"

#import "UIEvent+UIView.h"

#import "UIView+CGGeometry.h"


@interface UIResponder
@end


@interface UIResponder( PrivateFuture)

- (UIEvent *) _handleEvent:(UIEvent *) event;

@end


//#define EVENT_DEBUG
//#define EVENT_DEBUG_VERBOSE
//#define HITTEST_DEBUG

@implementation UIView ( UIEvent)

+ (CGFloat) mouseMotionSuppressionDelay
{
   return( 0.1);
}


//
// checks if point is in the visible area
// point is in the bounds coordinate system
// Does not recurse to subviews. Query those separately
//
- (BOOL) hitTest:(CGPoint) point
       withEvent:(UIEvent *) event
{
   BOOL     flag;
   CGRect   bounds;

   bounds          = [self bounds];
   bounds.origin.x = -bounds.origin.x;
   bounds.origin.y = -bounds.origin.y;
   flag            = CGRectContainsPoint( bounds, point);

#ifdef HITTEST_DEBUG
   fprintf( stderr, "%s: %s [%s] @%s -> %s\n",
                        __PRETTY_FUNCTION__,
                        [self UTF8String],
                        CGRectUTF8String( bounds),
                        CGPointUTF8String( point),
                        flag ? "YES" : "NO");
#endif
   return( flag);
}


- (UIEvent *) handleMouseButtonEvent:(UIMouseButtonEvent *) event
{
   SEL   sel;
   int   action;
   int   button;

   sel    = 0;
   action = [event action];
   button = [event button];

   if( action == UIEventButtonDown)
      _clickOrDrag._suppressUntilTimestamp = [event timestamp] +
                                             _clickOrDrag._mouseMotionSuppressionDelay;

   switch( button)
   {
      case UIEventMouseButtonLeft :
         switch( action)
         {
         case UIEventButtonDown :
            sel = @selector( mouseDown:);
            break;
         case UIEventButtonUp :
            sel = @selector( mouseUp:);
            break;
         }
         break;

      case UIEventMouseButtonRight  :
         switch( action)
         {
         case UIEventButtonDown   :
            sel = @selector( rightMouseDown:);
            break;
         case UIEventButtonUp :
            sel = @selector( rightMouseUp:);
            break;
         }
         break;

      case UIEventMouseButtonMiddle :
         switch( action)
         {
         case UIEventButtonDown   :
            sel = @selector( otherMouseDown:);
            break;
         case UIEventButtonUp :
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
- (UIEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) event
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


- (UIEvent *) handleMouseScrollEvent:(UIMouseScrollEvent *) event
{
   // scrollWheel: taken from AppKit
   // https://developer.apple.com/documentation/appkit/nsscrollview/1403494-scrollwheel?language=objc
   //
   if( event && [self respondsToSelector:@selector( scrollWheel:)])
      event = (UIMouseScrollEvent *) [self scrollWheel:event];

   return( event);
}


- (UIEvent *) handleKeyboardEvent:(UIKeyboardEvent *) event
{
   uint64_t   state;
   SEL        sel;

   sel   = 0;
   switch( [event action])
   {
   case UIEventButtonRepeat  :  // do keyUp: and keyDown:
      sel = @selector( keyUp:);
      if( sel && [self respondsToSelector:sel])
      {
         // keep UIEventKeyRepeat as action, don't create new event
         // event return value ignored,as to not accidentally prohibit keyDown:
         [self performSelector:sel
                    withObject:event];
      }
      // fall thru

   case UIEventButtonDown   :
      sel = @selector( keyDown:);
      break;

   case UIEventButtonUp :
      sel = @selector( keyUp:);
      break;
   }

   if( sel && [self respondsToSelector:sel])
   {
      event = [self performSelector:sel
                         withObject:event];
   }
#ifdef EVENT_DEBUG
   fprintf( stderr, "event %p\n", event);
#endif

#if 0
   if( [event key] == GLFW_KEY_ESCAPE &&
       [event action] == UIEventButtonDown)
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


- (UIEvent *) handleUnicodeEvent:(UIUnicodeEvent *) event
{
   uint64_t   state;
   SEL        sel;

   sel = @selector( unicodeCharacter:);
   if( [self respondsToSelector:sel])
   {
      event = [self performSelector:sel
                         withObject:event];
   }
#ifdef EVENT_DEBUG
   fprintf( stderr, "event %p\n", event);
#endif
   return( event);
}


// flat, doesn't recurse
- (UIView *) subviewAtPoint:(CGPoint) point
{
   struct mulle_pointerarrayreverseenumerator   rover;
   UIView                                       *view;

   rover = mulle_pointerarray_reverseenumerate( _subviews);
   while( _mulle_pointerarrayreverseenumerator_next( &rover, (void **) &view))
      if( CGRectContainsPoint( [view frame], point))
         break;
   mulle_pointerarrayreverseenumerator_done( &rover);
   return( view);
}


- (id <UILayer>) layerAtPoint:(CGPoint) point
{
   struct mulle_pointerarrayreverseenumerator   rover;
   id <UILayer>                                 layer;
   CGRect                                       frame;

   frame    = [self frame];
   point.x += frame.origin.x;
   point.y += frame.origin.y;

   rover = mulle_pointerarray_reverseenumerate( _layers);
   while( _mulle_pointerarrayreverseenumerator_next( &rover, (void **) &layer))
      if( CGRectContainsPoint( [layer frame], point))
         break;
   mulle_pointerarrayreverseenumerator_done( &rover);
   return( layer);
}



- (UIEvent *) _handleEvent:(UIEvent *) event
{
   if( [self isUserInteractionEnabled] == NO)
   {
#ifdef EVENT_DEBUG
       fprintf( stderr, "Disabled view %s ignores event\n", [self UTF8String]);
#endif
      return( event);
   }

#ifdef EVENT_DEBUG
    fprintf( stderr, "Try to handle event %s\n", [self UTF8String]);
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

//
// This was written to support MulleMenu. But MulleMenu does it now
// differently.
//
- (void) mulleSubviewDidHandleEvent:(UIEvent *) event
{
   // pass it up, until noone cares anymore
   [[self superview] mulleSubviewDidHandleEvent:event];
}


- (UIView *) mulleLetSubviewHandleEvent:(UIEvent *) event
                   atTranslatedPosition:(CGPoint) translated
{
   struct mulle_pointerarrayreverseenumerator   rover;
   UIView                                       *view;
   BOOL                                         didHandleEvent;

   if( _subviews)
   {
      rover = _mulle_pointerarray_reverseenumerate( _subviews);
      while( _mulle_pointerarrayreverseenumerator_next( &rover, (void **) &view))
      {
         didHandleEvent = [view handleEvent:event
                                 atPosition:translated] == nil;
         if( didHandleEvent)
         {
            [self mulleSubviewDidHandleEvent:event];
            mulle_pointerarrayreverseenumerator_done( &rover);
            return( view);
         }
      }
      mulle_pointerarrayreverseenumerator_done( &rover);
   }

   return( nil);
}


// this does the hitTest
- (UIEvent *) handleEvent:(UIEvent *) event
               atPosition:(CGPoint) position
{
   CGPoint                               translated;
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;
   UIEvent                               *memo;

   assert( event);

   if( [self isHidden]) // alpha < 0.01: should we care for events ?
   {
#ifdef EVENT_DEBUG
       fprintf( stderr, "Invisible view %s ignores event\n", [self UTF8String]);
#endif
      return( event);
   }

   // from UIView+CGGeometry
   translated = [self translatedPoint:position];

#ifdef HITTEST_DEBUG
  fprintf( stderr, "translated: %s %s -> %s\n",
               [self UTF8String],
               CGPointUTF8String( position),
               CGPointUTF8String( translated));
#endif

   if( ! [self hitTest:translated
             withEvent:event])
   {
#ifdef EVENT_DEBUG_VERBOSE
       fprintf( stderr, "Event does not hit view %s\n", [self UTF8String]);
#endif
      return( event);
   }

   // if a subview handled the event, we are done
   view = [self mulleLetSubviewHandleEvent:event
                      atTranslatedPosition:translated];
   if( view)
   {
#ifdef EVENT_DEBUG
      fprintf( stderr, "Subview %s did consume event\n", [view UTF8String]);
#endif
      return( nil);
   }

   if( ! [self isUserInteractionEnabled]) // alpha < 0.01: should we care for events ?
   {
      // TODO: check if event type is of type user interaction
#ifdef EVENT_DEBUG
      fprintf( stderr, "User interaction disabled on view %s\n", [self UTF8String]);
#endif
      return( event);
   }

   //
   // current position relative to visible bounds
   //
   [event _setTranslatedPoint:translated
                      forView:self];
   return( [self _handleEvent:event]);
}


- (UIEvent *) responder:(id <UIResponder>) responder
            handleEvent:(UIEvent *) event
{
#ifdef EVENT_DEBUG
   fprintf( stderr, "%s %s\n", __PRETTY_FUNCTION__, (char *) [responder UTF8String]);
#endif

   do
   {
      // TODO: translate positions
      //       UIViewController could also be the responde here
      event = [(UIView *) responder _handleEvent:event];
      if( ! event)
      {
#ifdef EVENT_DEBUG
         fprintf( stderr, "Responder %s consumed event\n", (char *) [responder UTF8String]);
#endif
         break;
      }
#ifdef EVENT_DEBUG
      fprintf( stderr, "Responder %s did not consume event, try next\n", (char *) [responder UTF8String]);
#endif
      responder = [responder nextResponder];
   }
   while( responder);

   return( event);
}


//
// This is called and supersed on UIWindow
//
- (UIEvent *) handleEvent:(UIEvent *) event
{
   CGPoint   position;

   position = [event locationInWindow]; // TODO locationInRootView:
   return( [self handleEvent:event
                  atPosition:position]);
}

@end

