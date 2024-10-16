#import "UIView.h"

@class UIMouseScrollEvent;
@class UIMouseButtonEvent;
@class UIMouseMotionEvent;


// only input events are distributed to UIViews

@interface UIView ( UIEvent) < UIResponder>


// pointInside is not declared as UIInputEvent, for compatibility
// event is unused.
- (BOOL) pointInside:(CGPoint) point
           withEvent:(UIEvent *) event;

// this will set the locationForView of the event. If you don't want this
// don't pass an event. Returns the farthest view, that is not transparent
// and has userInteraction enabled. (not used by event handling)
- (UIView *) hitTest:(CGPoint) point
           withEvent:(UIEvent *) event;

// this checks userInteractionEnabled and tests with pointInside:withEvent:
// inputEvent cache will be set for the view, if the hitTest succeeds
- (BOOL) directHitTest:(CGPoint) point
        withInputEvent:(UIInputEvent *) event;

// this method is actually used for event deliver. Event can be changed to
// nil to block propagation
- (UIView *) hitSearchSubviews:(CGPoint) contentLocation
         withInputEventPointer:(UIInputEvent **) event_p;

//
// this handles the event without considering subviews
//
- (UIView *) subviewAtContentLocation:(CGPoint) point;
- (id <UILayer>) layerAtContentLocation:(CGPoint) point;

// UIResponder...
- (UIMouseMotionEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) event;
- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event;
- (UIEvent *) handleEvent:(UIEvent *) event;

// used by customers of the eventCallback (i.e. Controller) to avoid recursion
// in special cases.
- (UIEvent *) handleForwardedEvent:(UIEvent *) event;

- (void) didBecomeFirstResponder;
- (void) didResignFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;
- (BOOL) isFirstResponder;
- (id <UIResponder>) nextResponder;


@end



