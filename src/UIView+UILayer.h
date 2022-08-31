//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//

// we want "import.h" always anyway
#import "UIView.h"


@interface UIView( UILayer)

- (CGPoint) convertPoint:(CGPoint) pos
                 toLayer:(id <UILayer>) layer;
- (CGPoint) convertPoint:(CGPoint) pos 
               fromLayer:(id <UILayer>) layer;


- (CGRect) convertRect:(CGRect) pos
               toLayer:(id <UILayer>) layer;
- (CGRect) convertRect:(CGRect) pos 
             fromLayer:(id <UILayer>) layer;
// will return sublayer if any hit, or returns mainLayer by default
// even if point does not hit
- (id <UILayer>) layerHitTest:(CGPoint) point;

@end
