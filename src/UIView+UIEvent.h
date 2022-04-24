#import "UIView.h"

@class UIMouseScrollEvent;


// only input events are distributed to UIViews

@interface UIView ( UIEvent)


- (BOOL) hitTest:(CGPoint) point
  withInputEvent:(UIInputEvent *) event;


// returns event if it hasn't been handled
- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event;

- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event
                         atPosition:(CGPoint) position;


- (UIView *) subviewAtPoint:(CGPoint) point;
- (id <UILayer>) layerAtPoint:(CGPoint) point;

@end


//
// methods *optionally* implemented by UIView subclasses
//
@interface UIView ( UIFutureEvents)

- (UIEvent *) keyUp:(UIEvent *) event;
- (UIEvent *) keyDown:(UIEvent *) event;

- (UIEvent *) scrollWheel:(UIEvent *) event;

- (UIEvent *) mouseDown:(UIEvent *) event;
- (UIEvent *) otherMouseDown:(UIEvent *) event;
- (UIEvent *) rightMouseDown:(UIEvent *) event;

- (UIEvent *) mouseUp:(UIEvent *) event;
- (UIEvent *) otherMouseUp:(UIEvent *) event;
- (UIEvent *) rightMouseUp:(UIEvent *) event;

- (UIEvent *) mouseDragged:(UIMouseMotionEvent *) event;
- (UIEvent *) otherMouseDragged:(UIMouseMotionEvent *) event;
- (UIEvent *) rightMouseDragged:(UIMouseMotionEvent *) event;

- (UIEvent *) mouseEntered:(UIEvent *) event;
- (UIEvent *) mouseExited:(UIEvent *) event;
- (UIEvent *) mouseMoved:(UIEvent *) event;

+ (CGFloat) mouseMotionSuppressionDelay;

@end

