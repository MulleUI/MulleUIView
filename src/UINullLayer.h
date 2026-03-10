//
// Copyright (c) <|YEAR|> Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "CALayer.h")
#  import "CALayer.h"
# endif
#endif

#import "import.h"

#import "UIView.h"

//
// this layer does nothing, it's just there so we can run tests
// on UIView
//
@interface UINullLayer : MulleObject < MulleAutolockingObjectProtocols,
                                       UILayer>

// not observable, because we don't implement -willChange (this layer
// shouldn't really be used
@property( assign) CGRect              frame;
@property( assign) CGRect              bounds;
@property( assign) CGFloat             rotation;

@property( assign) CGAffineTransform   transform;
@property( assign) CGRect              clipRect;
@property( assign) CGFloat             alpha;
@property( assign) NSInteger           tag;

@property( assign) FILE                *drawCallTracer;
@property( dynamic) char               *nameUTF8String;

@end
