#import "UIView.h"

@class UIMouseScrollEvent;
@class UIMouseButtonEvent;
@class UIMouseMotionEvent;


// only input events are distributed to UIViews

@interface UIView ( UIEvent)


// pointInside is not declared as UIInputEvent, for compatibility
// event is unused
- (BOOL) pointInside:(CGPoint) point
           withEvent:(UIEvent *) event;

// this will set the contentLocation of the event. If you don't want this
// don't pass the event
- (UIView *) hitTest:(CGPoint) point
           withEvent:(UIEvent *) event;


//
// this handles event without subviews
//
- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event;

// returns event if it hasn't been handled, this will hitTest subviews
// location is in the superview frame space
- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event
                           location:(CGPoint) location;


- (UIView *) subviewAtContentLocation:(CGPoint) point;
- (id <UILayer>) layerAtContentLocation:(CGPoint) point;

@end


//
// methods *optionally* implemented by UIView subclasses
//
@interface UIView ( UIFutureEvents)

- (UIKeyboardEvent *) keyUp:(UIKeyboardEvent *) event;
- (UIKeyboardEvent *) keyDown:(UIKeyboardEvent *) event;

- (UIMouseScrollEvent *) scrollWheel:(UIMouseScrollEvent *) event;

- (UIMouseButtonEvent *) mouseDown:(UIMouseButtonEvent *) event;
- (UIMouseButtonEvent *) otherMouseDown:(UIMouseButtonEvent *) event;
- (UIMouseButtonEvent *) rightMouseDown:(UIMouseButtonEvent *) event;

- (UIMouseButtonEvent *) mouseUp:(UIMouseButtonEvent *) event;
- (UIMouseButtonEvent *) otherMouseUp:(UIMouseButtonEvent *) event;
- (UIMouseButtonEvent *) rightMouseUp:(UIMouseButtonEvent *) event;

- (UIMouseMotionEvent *) mouseDragged:(UIMouseMotionEvent *) event;
- (UIMouseMotionEvent *) otherMouseDragged:(UIMouseMotionEvent *) event;
- (UIMouseMotionEvent *) rightMouseDragged:(UIMouseMotionEvent *) event;

- (UIMouseMotionEvent *) mouseEntered:(UIMouseMotionEvent *) event;
- (UIMouseMotionEvent *) mouseExited:(UIMouseMotionEvent *) event;
- (UIMouseMotionEvent *) mouseMoved:(UIMouseMotionEvent *) event;

+ (CGFloat) mouseMotionSuppressionDelay;

@end

