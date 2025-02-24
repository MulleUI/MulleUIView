#import "MulleScrollIndicatorView.h"

#import "import-private.h"

#import "UIView+UIEvent.h"
#import "UIScrollView+UIEvent.h"


// #define LAYOUT_DEBUG

#ifdef DEBUG
//# define EVENT_DEBUG
#endif


PROTOCOLCLASS_IMPLEMENTATION( MulleScrollIndicatorLayer)

- (CGRect) bubbleFrameWithBounds:(CGRect) bounds
{
   float         x;
   float         y;
   float         w;
   float         h;
   float         xLimit;
   float         yLimit;
   CGRect        frame;
   CGFloat       contentLength;
   BOOL          isHorizontal;
   UIEdgeInsets  insets;

   insets = UIEdgeInsetsMake( 1.0, 1.0, 1.0, 1.0);
   frame  = UIEdgeInsetsInsetRect( bounds, insets);

   isHorizontal  = bounds.size.width > bounds.size.height;
   contentLength = [self contentLength];
   if( isHorizontal)
   {
      xLimit = frame.origin.x + frame.size.width;

      w = frame.size.width * [self bubbleLength] / contentLength;
      x = frame.size.width * [self bubbleOffset] / contentLength + frame.origin.x;
      if( x + w > xLimit)
         w = xLimit - x;
      if( x < frame.origin.x)
      {
         w -= frame.origin.x - x;
         x  = frame.origin.x;
      }

      // don't let bubble vanish leave a dot of size
      // frame.size.height
      if( w < frame.size.height)
      {
         w = frame.size.height;
         if( x + w > xLimit)
            x = xLimit - w;
      }

      if( x + w <= xLimit)
      {
         frame.origin.x   = x;
         frame.size.width = w;
      }
   }
   else
   {
      yLimit = frame.origin.y + frame.size.height;

      h = frame.size.height * [self bubbleLength] / contentLength;
      y = frame.size.height * [self bubbleOffset] / contentLength + frame.origin.y;

      if( y + h > yLimit)
         h = yLimit - y;
      if( y < frame.origin.y)
      {
         h -= frame.origin.y - y;
         y  = frame.origin.y;
      }

      // don't let bubble vanish leave a dot of size
      // frame.size.width
      if( h < frame.size.width)
      {
         h = frame.size.width;
         if( y + h > yLimit)
            y = yLimit - h;
      }

      if( y + h <= yLimit)
      {
         frame.origin.y    = y;
         frame.size.height = h;
      }
   }

   return( frame);
}


//
// if point is in bubble, return -1
// otherwise where the bubble would go
//
- (BOOL) isInsideBubbleAtPoint:(CGPoint) point
                        bounds:(CGRect) bounds
                      offsetAt:(CGPoint *) offset
{
   CGRect   bubbleFrame;
   BOOL     isHorizontal;

   // the frame as actually drawn
   bubbleFrame  = [self bubbleFrameWithBounds:bounds];

   isHorizontal = bounds.size.width > bounds.size.height;
   if( isHorizontal)
   {
      fprintf( stderr, "P: %s F: %s B:%s:",
            CGPointUTF8String( point),
            CGRectUTF8String( bubbleFrame),
            CGRectUTF8String( bounds));
      offset->y = 0.0;
      offset->x = point.x - CGRectGetMinX( bubbleFrame);
      return( point.x >= CGRectGetMinX( bubbleFrame) &&
              point.x <= CGRectGetMaxX( bubbleFrame));
   }

   offset->x = 0.0;
   offset->y = point.y - CGRectGetMinY( bubbleFrame);

   return( point.y >= CGRectGetMinY( bubbleFrame) &&
           point.y <= CGRectGetMaxY( bubbleFrame));
}


//
// if point is in bubble, return -1
// otherwise where the bubble would go
//
- (CGFloat) bubbleValueAtPoint:(CGPoint) point
                        bounds:(CGRect) bounds
                isInsideBubble:(BOOL *) isInsideBubble
{
   CGRect         bubbleFrame;
   BOOL           isHorizontal;
   UIEdgeInsets   insets;

   // the frame as actually drawn
   bubbleFrame  = [self bubbleFrameWithBounds:bounds];

   // actual limit of bubbleFrame
   insets = UIEdgeInsetsMake( 1.0, 1.0, 1.0, 1.0);
   bounds = UIEdgeInsetsInsetRect( bounds, insets);

   isHorizontal = bounds.size.width > bounds.size.height;
   if( isHorizontal)
   {
      fprintf( stderr, "P: %s F: %s B:%s:",
            CGPointUTF8String( point),
            CGRectUTF8String( bubbleFrame),
            CGRectUTF8String( bounds));

      *isInsideBubble = point.x >= CGRectGetMinX( bubbleFrame) &&
                        point.x <= CGRectGetMaxX( bubbleFrame);
      if( *isInsideBubble)
      {
         fprintf( stderr, "stay put\n");
         return( bubbleFrame.origin.x);
      }

      // center bubble around click
      point.x -= bubbleFrame.size.width / 2.0;

      if( point.x < CGRectGetMinX( bounds))
      {
         fprintf( stderr, "left edge\n");
         return( CGRectGetMinX( bounds));
      }
      if( point.x + bubbleFrame.size.width > CGRectGetMaxX( bounds))
      {
         fprintf( stderr, "right edge\n");
         return( CGRectGetMaxX( bounds) - bubbleFrame.size.width);
      }

      fprintf( stderr, "%.2f\n", point.x);
      return( point.x);
   }

   *isInsideBubble = point.y >= CGRectGetMinY( bubbleFrame) &&
                     point.y <= CGRectGetMaxY( bubbleFrame);
      if( *isInsideBubble)
         return( bubbleFrame.origin.x);

   point.y -= bubbleFrame.size.height / 2.0;

   if( point.y < CGRectGetMinY( bounds))
      return( CGRectGetMinY( bounds));
   if( point.y + bubbleFrame.size.height > CGRectGetMaxY( bounds))
      return( CGRectGetMaxY( bounds) - bubbleFrame.size.height);
   return( point.y);
}

PROTOCOLCLASS_END()


@implementation MulleScrollIndicatorView

/*
 * left mouse
 */
- (UIInputEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   UIInputEvent   *result;
   UIScrollView   *scrollView;

#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif

   scrollView = MULLE_OBJC_CLASS_CAST( UIScrollView, [self superview]);
   result     = [scrollView mouseDown:event];
   if( result)
      return( result);

   // only if we consumed the event, do we want to become first responder
   // for the subsequent mouseUp: or mouseDragged: events
   [self becomeFirstResponder];
   return( nil);
}


// pass upwards
- (UIMouseMotionEvent *) mouseDragged:(UIMouseMotionEvent *) event
{
#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif
   return( event);
}


- (UIInputEvent *) mouseUp:(UIMouseButtonEvent *) event
{
   UIInputEvent   *result;
   UIView         *superview;

#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif

   superview = [self superview];
   result    = [superview mouseUp:event];
   if( result)
      return( result);

   // can only resign here, because UIScrollView still needs to figure out
   // if event came from us
   [self resignFirstResponder];
   return( nil);
}

/*
 * right mouse events: pass to superview
 */
- (UIInputEvent *) rightMouseDown:(UIMouseButtonEvent *) event
{
#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif
   return( event);
}


- (UIMouseMotionEvent *) rightMouseDragged:(UIMouseMotionEvent *) event
{
#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif
   return( event);
}


- (UIInputEvent *) rightMouseUp:(UIMouseButtonEvent *) event
{
#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif
   return( event);
}

@end
