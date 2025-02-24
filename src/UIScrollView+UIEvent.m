#import "UIScrollView+UIEvent.h"

#import "import-private.h"

#import "MulleScrollIndicatorView.h"

#import "UIView+DebugPrivate.h"
#import "UIView+Layout.h"
#import "UIView+CGGeometry.h"
#import "UIView+UIEvent.h"
#import "UIInputEvent+UIView.h"


//#define LAYOUT_DEBUG
//#define EVENT_DEBUG
//#define ZOOM_DEBUG
//#define SCROLL_DEBUG


@implementation UIScrollView( UIEvent)

//
// event handling
// In category ?
//


#define ZOOM_FACTOR    0.075
#define MIN_ZOOM       0.1
#define SCROLL_FACTOR  0.25

- (CGPoint) scrollFactor
{
   CGRect   contentBounds;
   CGPoint  scrollFactor;

   contentBounds = [_contentView bounds];

   if( contentBounds.size.width <= 0.1 || contentBounds.size.height <= 0.1)
      return( CGPointMake( 0.0, 0.0));

   // the current scroll factor
   // contentSize  = [self contentSize];

   scrollFactor.x = SCROLL_FACTOR;
   scrollFactor.y = SCROLL_FACTOR;

   return( scrollFactor);
}

//
// event handling
// In category ?
// Won't zoom out, so that UIScrollView is not filled anymore ?
// Zooming in should stop at a certain magnifying factor, like what ?
//
- (UIInputEvent *) scrollWheel:(UIMouseScrollEvent *) event
{
   BOOL      zoomOut;
   CGFloat   amount;
   CGPoint   contentOffset;
   CGPoint   diff;
   CGPoint   factor;
   CGPoint   mouseLocation;
   CGPoint   newContentOffset;
   CGPoint   newZoomFactor;
   CGPoint   scrollFactor;
   CGPoint   zoomFactor;
   CGRect    bounds;
   CGRect    clampedContentBounds;
   CGRect    contentBounds;
   CGRect    newContentBounds;
   CGSize    contentSize;

   UIViewEventLog( event, "%#@", event);

   diff = [event scrollOffsetWithAcceleration:YES
                                 useModifiers:YES];

   contentOffset = [_contentView contentOffset];
   contentSize   = [_contentView contentSize];

   // get unscaled position before zoom
   contentBounds = [_contentView bounds];

   UIViewEventLogVerbose( event, "scrollWheel: %s\n", CGPointUTF8String( diff));

   //
   // TODO: if not zooming possibly scroll up/down
   //
   if( ! [self isZoomEnabled])
   {
      scrollFactor       = [self scrollFactor];

      newContentOffset.x = contentOffset.x + diff.x * scrollFactor.x;
      newContentOffset.y = contentOffset.y + diff.y * scrollFactor.y;

      newContentOffset   = [_contentView clampedContentOffset:newContentOffset];
      [self setContentOffset:newContentOffset];
      [self setNeedsDisplay];

      UIViewEventLogVerbose( event, "scrollFactor: %s\n",
                                    CGPointUTF8String( scrollFactor));

      UIViewEventLogVerbose( event, "contentOffset: %s -> %s\n",
                                    CGPointUTF8String( contentOffset),
                                    CGPointUTF8String( newContentOffset));
      return( nil);
   }

   /*
    *  Zoom
    */
   zoomFactor = [self zoomFactor];
   if( zoomFactor.x <= 0.0)
      return( nil);

   //
   // use zoom factor relative to current zoom, that makes the zoom
   // smoother
   //

   // ensure that we do some zoom
   amount = zoomFactor.x * ZOOM_FACTOR;
   if( amount < MIN_ZOOM)
      amount = MIN_ZOOM;

   if( diff.y < 0)      // scrollwheel is Y
   {
      newZoomFactor.x = zoomFactor.x + amount;
      zoomOut         = NO;
   }
   else
   {
      newZoomFactor.x = zoomFactor.x - amount;
      zoomOut         = YES;
   }

   // make X nicey and more reproducable, zooming in and out
   newZoomFactor.x = round( newZoomFactor.x * (1.0 / MIN_ZOOM)) / (1.0 / MIN_ZOOM);

   // keep aspect ratio stable on Y axis
   newZoomFactor.y = newZoomFactor.x * zoomFactor.y / zoomFactor.x;

   UIViewEventLogVerbose( event, "zoomFactor: %s (%g) -> %s (%g) (tentative)\n",
                                 CGPointUTF8String( zoomFactor),
                                 CGPointGetAspectRatio( zoomFactor),
                                 CGPointUTF8String( newZoomFactor),
                                 CGPointGetAspectRatio( newZoomFactor));

   newContentBounds.origin       = contentBounds.origin;
   newContentBounds.size.width   = contentSize.width / newZoomFactor.x;
   newContentBounds.size.height  = contentSize.height / newZoomFactor.y;

   if( zoomOut)
   {
      clampedContentBounds = [_contentView clampedBounds:newContentBounds];
   }
   else 
   {
      clampedContentBounds = newContentBounds;
   }

   UIViewEventLogVerbose( event, "contentBounds: %s (%g) -> %s %s (%g)\n",
                                  CGRectUTF8String( contentBounds),
                                  CGRectGetAspectRatio( contentBounds),
                                  zoomOut ? "clamped " : "",
                                  CGRectUTF8String( clampedContentBounds),
                                  CGRectGetAspectRatio( clampedContentBounds));

   //
   // look at the position of the mouse cursor, keep contents under it at
   // the same place zoomed or unzoomed
   //
   // ...--------------------+ contentView
   // scrollView             |
   // +----------------+     |
   // |   *            |     |  * mouseLocation in contentView points
   // |                |     |
   // +----------------+     |
   //                        :
   //

   bounds        = [self bounds];
   mouseLocation = [event locationInView:self];

   factor.x = mouseLocation.x / bounds.size.width;
   factor.y = mouseLocation.y / bounds.size.height;

   // we need to set this now so the contentOffset clamp works correctly
   [_contentView setBounds:clampedContentBounds];

   // adjust contentOffset
   newContentOffset    = contentOffset;
   newContentOffset.x -= (clampedContentBounds.size.width - contentBounds.size.width) * factor.x;
   newContentOffset.y -= (clampedContentBounds.size.height - contentBounds.size.height) * factor.y;

   // If we don't clamp here, the content may be partially obscured

   newContentOffset    = [_contentView clampedContentOffset:newContentOffset];

   // fprintf( stderr, "scale: %f\n", scale.y);

   UIViewEventLogVerbose( event, "factor: %s\n", CGPointUTF8String( factor));

   UIViewEventLogVerbose( event, "zoomFactor: %s (%g) -> %s (%g)\n",
                     CGPointUTF8String( zoomFactor),
                     CGPointGetAspectRatio( zoomFactor),
                     CGPointUTF8String( newZoomFactor),
                     CGPointGetAspectRatio( newZoomFactor));

   UIViewEventLogVerbose( event, "position: %s in %s\n",
                     CGPointUTF8String( mouseLocation),
                     CGRectUTF8String( bounds));

   UIViewEventLogVerbose( event, "bounds: %s (%g) -> %s (%g)\n",
                     CGRectUTF8String( contentBounds),
                     CGRectGetAspectRatio( contentBounds),
                     CGRectUTF8String( clampedContentBounds),
                     CGRectGetAspectRatio( clampedContentBounds));

   UIViewEventLogVerbose( event, "contentOffset: %s -> %s\n",
                     CGPointUTF8String( contentOffset),
                     CGPointUTF8String( newContentOffset));

   [self setContentOffset:newContentOffset];
   [self setNeedsDisplay];

   return( nil);
}


- (MulleScrollIndicatorView *) scrollIndicatorViewForInputEvent:(UIInputEvent *) event
{
   CGPoint                     point;
   MulleScrollIndicatorView    *view;

   point = [event locationInView:self];
   view  = (MulleScrollIndicatorView *) [self subviewAtContentLocation:point];

   if( view == _horIndicatorView || view == _verIndicatorView)
      return( view);

   //
   // check  if one of the indicator views is
   // first responder, then use it as view
   //
   if( [_horIndicatorView isFirstResponder])
      return( _horIndicatorView);
   if( [_verIndicatorView isFirstResponder])
      return( _verIndicatorView);
   return( nil);
}


// left mouse button clicked down (not yet up)
// behaviour os x (TextEdit) : click atop bubble: pageup, click on bubble: niente
// we are also handling mouseDragged events here!
//
- (UIInputEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   CGPoint                     point;
   CGPoint                     contentOffset;
   CGSize                      contentSize;
   CGPoint                     newContentOffset;
   MulleScrollIndicatorView    *indicatorView;
   CGRect                      bounds;

   UIViewEventLog( event, "%#@", event);

   // pass thru events, we don't consume, to contained views
   indicatorView = [self scrollIndicatorViewForInputEvent:event];
   if( ! indicatorView)
      return( event);

   contentSize = [self contentSize];
   if( contentSize.width == 0.0 || contentSize.height == 0.0)
      return( nil);

   // if we let the indicator view become firstResponder we know which one
   // is getting draggedEvents (indicatorView already does this for us,
   // if we return nil)
   // [indicatorView becomeFirstResponder];

   point = [event locationInView:indicatorView];

   // if click is inside the bubble, then don't do anything visible
   // maybe store offset for positioning in a later drag
   bounds = [indicatorView bounds];
   if( [indicatorView isInsideBubbleAtPoint:point
                                     bounds:bounds
                                   offsetAt:&_bubbleDragOffset])
      return( nil);

   // use this to calculate offset into bubble, we want to maintain
   contentOffset = [self contentOffset];
   if( indicatorView == _horIndicatorView)
   {
      newContentOffset.x = point.x * (contentSize.width / bounds.size.width);
      newContentOffset.y = contentOffset.y;
   }
   else
   {
      newContentOffset.y = point.y * (contentSize.height / bounds.size.height);
      newContentOffset.x = contentOffset.x;
   }

   newContentOffset = [_contentView clampedContentOffset:newContentOffset];

#ifdef EVENT_DEBUG
   MulleUILog( "x:%s b:%s s:%s o:%s -> n:%s",
                        CGPointUTF8String( point),
                        CGRectUTF8String( bounds),
                        CGSizeUTF8String( contentSize),
                        CGPointUTF8String( contentOffset),
                        CGPointUTF8String( newContentOffset));
#endif

   [self setContentOffset:newContentOffset];
   [self setNeedsDisplay];
   return( nil);
}


- (UIMouseMotionEvent *) mouseDragged:(UIMouseMotionEvent *) event
{
   CGPoint                     point;
   CGPoint                     contentOffset;
   CGSize                      contentSize;
   CGPoint                     newContentOffset;
   MulleScrollIndicatorView    *indicatorView;
   CGRect                      bounds;

   UIViewEventLog( event, "%#@", event);

   indicatorView = (MulleScrollIndicatorView *) [[self window] firstResponder];
   assert( [indicatorView isKindOfClass:[MulleScrollIndicatorView class]]);
// return( event); // can't really happen

   contentSize = [_contentView contentSize];
   assert( contentSize.width != 0.0 && contentSize.height != 0.0);

   contentOffset = [self contentOffset];
   bounds        = [indicatorView bounds];
   point         = [event locationInView:indicatorView];

   // are the viewspace pixels in the same domain ?
   point.x      -= _bubbleDragOffset.x;
   point.y      -= _bubbleDragOffset.y;

   if( indicatorView == _horIndicatorView)
   {
      newContentOffset.x = point.x * (contentSize.width / bounds.size.width);
      newContentOffset.y = contentOffset.y;
   }
   else
   {
      newContentOffset.y = point.y * (contentSize.height / bounds.size.height);
      newContentOffset.x = contentOffset.x;
   }

   newContentOffset = [_contentView clampedContentOffset:newContentOffset];

#ifdef EVENT_DEBUG
   MulleUILog( "x:%s b:%s s:%s o:%s -> n:%s\n",
                        CGPointUTF8String( point),
                        CGRectUTF8String( bounds),
                        CGSizeUTF8String( contentSize),
                        CGPointUTF8String( contentOffset),
                        CGPointUTF8String( newContentOffset));
#endif

   [self setContentOffset:newContentOffset];
   [self setNeedsDisplay];
   return( nil);
}


//
// consume mouseUp events if they hit indicator views
//
- (UIInputEvent *) mouseUp:(UIMouseButtonEvent *) event
{
   UIView    *view;

   view = [self scrollIndicatorViewForInputEvent:event];
   if( ! view)
      return( event);

   // consume
   return( nil);
}


/*
 * RIGHT MOUSE : pan
 */
- (UIInputEvent *) rightMouseDown:(UIMouseButtonEvent *) event
{
   UIViewEventLog( event, "%#@", event);

   [self setMomentum:CGPointZero
           timestamp:0];

   _scrollStartTime  = [event timestamp];
   _locationInWindow = [event locationInWindow];

   MullePointHistoryStart( &_locationInWindowHistory, _scrollStartTime, _locationInWindow);
   [self becomeFirstResponder];
   [self setNeedsDisplay]; // needed to refresh to get mouse events (...)

#ifdef EVENT_DEBUG
   fprintf( stderr, "scrollStartTime: %.2f\n", _scrollStartTime);
#endif
   return( nil);
}

//
// we want the pixel we are dragging to stick to the mouse cursor
// if possible
//
- (UIInputEvent *) rightMouseDragged:(UIMouseMotionEvent *) event
{
   CGPoint   mouseLocation;
   CGPoint   diff;
   CGPoint   contentMousePosition;
   CGPoint   oldContentMousePosition;

   UIViewEventLog( event, "%#@", event);

   [self setDragging:YES];

   mouseLocation           = [event locationInWindow];
   contentMousePosition    = [_contentView convertPoint:mouseLocation
                                               fromView:nil];
   oldContentMousePosition = [_contentView convertPoint:_locationInWindow
                                               fromView:nil];

   diff.x = oldContentMousePosition.x - contentMousePosition.x;
   diff.y = oldContentMousePosition.y - contentMousePosition.y;

//  zoomFactor = [self zoomFactor];
//
//   diff.x *= 1.0 / zoomFactor.x;
//   diff.y *= 1.0 / zoomFactor.y;

   [self scrollContentOffsetBy:diff];
   [self setNeedsDisplay];

   MullePointHistoryAdd( &_locationInWindowHistory, [event timestamp], mouseLocation);
#ifdef EVENT_DEBUG
   fprintf( stderr, "{ timestamp=%.9f, point=%.2f,%2.f (diff=%.2f,%2.f) }\n",
                  [event timestamp],
                  mouseLocation.x, mouseLocation.y,
                  diff.x, diff.y);
#endif
   _locationInWindow = mouseLocation;

   return( nil);
}

#define HZ60                  (1.0/60.0)
#define MIN_SCROLLDURATION    0.05
#define SWIPEDURATION         0.05


// TODO: fix momentum when zoomed in, probably by using _locationInWindow
//       and history like in the pan code, translated to the contentView
//       which will implicitly pick up the bounds scaling
//
- (UIInputEvent *) rightMouseUp:(UIMouseButtonEvent *) event
{
   mulle_absolutetime_t           scrollEndTime;
   mulle_relativetime_t           scrollDuration;
   CGSize                         scrollAmount;
   CGPoint                        mouseLocation;
   struct MullePointHistoryItem   item;
   mulle_relativetime_t           diff;
   CGPoint                        momentum;

   UIViewEventLog( event, "%#@", event);

   if( ! [self isDragging])
      return( nil);

   [self setDragging:NO];

   scrollEndTime  = [event timestamp];
#ifdef SCROLLVIEW_DEBUG
   fprintf( stderr, "scrollEndTime: %.2f\n", scrollEndTime);
#endif
   mouseLocation = [event locationInWindow];
   momentum      = CGPointZero;

#ifdef EVENT_DEBUG
   MullePointHistoryPrint( stderr, &_locationInWindowHistory);
#endif
   item = MullePointHistoryGetItemForTimestamp( &_locationInWindowHistory, scrollEndTime - SWIPEDURATION);

#ifdef EVENT_DEBUG
   fprintf( stderr, "%s mouseLocation: %s\n", __PRETTY_FUNCTION__, CGPointUTF8String( mouseLocation));
   MullePointHistoryItemPrintf( stderr, &item);
#endif

   if( item.timestamp >= scrollEndTime - SWIPEDURATION)
   {
      //
      // https://medium.com/homullus/recreating-native-ios-scroll-and-momentum-2906d0d711ad
      //
      // On touch end Apple would get momentum by dividing number of pixels that
      // the user had swiped, and time that the user has swiped for. If the number
      // of pixels was less than 10 or time was less than 0.5, momentum would be
      // clamped to zero.
      //
      scrollDuration = mulle_timeinterval_subtract( scrollEndTime, _scrollStartTime);

      fprintf( stderr, "scrollDuration: %.2f\n", scrollDuration);
      if( scrollDuration < MIN_SCROLLDURATION)
         return( nil);

      // some value < SWIPEDURATION
      diff  = mulle_timeinterval_subtract( scrollEndTime, item.timestamp);

      scrollAmount.width  = item.point.x - mouseLocation.x;
      scrollAmount.height = item.point.y - mouseLocation.y;

      fprintf( stderr, "scrollAmount: %.2f,%.2f\n", scrollAmount.width, scrollAmount.height);

      //
      // the general idea is, that you calculate for SWIPEDURATION but actually
      // the sampled time is in "diff". The momentum is scaled for 60Hz updates
      // --- but I don't really know why this works nicely :) trial and error
      //
      if( fabs( scrollAmount.width) >= 10.0)
         momentum.x = scrollAmount.width * SWIPEDURATION / diff * HZ60;
      if( fabs( scrollAmount.height) >= 10.0)
         momentum.y = scrollAmount.height * SWIPEDURATION / diff * HZ60;
   }

   [self setMomentum:momentum
           timestamp:scrollEndTime];
   [self resignFirstResponder];

   return( nil);
}

@end

