//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//

// we want "import.h" always anyway
#import "UIView.h"


@interface UIView( UILayer)

- (CGPoint) convertPoint:(CGPoint) pos
                 toLayer:(id <UILayer>) toView;
//- (CGPoint) convertPoint:(CGPoint) pos fromLayer:(CALayer*) fromView;


// will return sublayer if any hit, or returns mainLayer by default
// even if point does not hit
- (id <UILayer>) layerHitTest:(CGPoint) point;

@end
