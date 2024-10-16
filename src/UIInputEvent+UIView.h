// prefer a local UIEvent over one in import.h
#ifdef __has_include
# if __has_include( "UIEvent.h")
#  import "UIEvent.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"

@class UIView;

@interface UIInputEvent( UIView)

//
// translated mouseLocation to current view bounds (ephemeral)
// set by _handleEvent:position for
//
- (CGPoint) locationInView:(UIView *) view;

// this is to be used by hitTest: exclusively and
// locationInView exclusively. Always use -locationInView to query.
- (CGPoint) _locationForView:(UIView *) view;

- (void) _setLocation:(CGPoint) point
              forView:(UIView *) view;

- (UIView *) _view;

@end




