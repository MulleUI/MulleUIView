#import "UIView.h"

@class UIMouseScrollEvent;
@class UIMouseButtonEvent;
@class UIMouseMotionEvent;


// only input events are distributed to UIViews

@interface UIView ( UIEvent)


// pointInside is not declared as UIInputEvent, for compatibility
// event is unused.
- (BOOL) pointInside:(CGPoint) point
           withEvent:(UIEvent *) event;

// this will set the locationForView of the event. If you don't want this
// don't pass an event
- (UIView *) hitTest:(CGPoint) point
           withEvent:(UIEvent *) event;


//
// this handles the event without considering subviews
//
- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event;
- (UIEvent *) handleOtherEvent:(UIEvent *) event;

// returns event if it hasn't been handled, this will hitTest subviews
// location is in the superview frame space
- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event
                           location:(CGPoint) location;


- (UIView *) subviewAtContentLocation:(CGPoint) point;
- (id <UILayer>) layerAtContentLocation:(CGPoint) point;

- (UIInputEvent *) handleKeyboardEvent:(UIKeyboardEvent *) event;
- (UIInputEvent *) handleUnicodeEvent:(UIUnicodeEvent *) event;
- (UIInputEvent *) handleActionEvent:(UIActionEvent *) event;
- (UIInputEvent *) handleMouseScrollEvent:(UIMouseScrollEvent *) event;
- (UIInputEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) event;
- (UIInputEvent *) handleMouseButtonEvent:(UIMouseButtonEvent *) event;


- (UIView *) firstUserInteractionEnabledViewAtPoint:(CGPoint) point
                                     withInputEvent:(UIInputEvent *) event;

- (UIView *) nextUserInteractionEnabledViewAtPoint:(CGPoint) point
                                     withInputEvent:(UIInputEvent *) event;                                          
@end


