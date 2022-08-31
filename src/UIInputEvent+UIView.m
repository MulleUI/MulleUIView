#import "UIInputEvent+UIView.h"

#import "import-private.h"

#import "UIView.h"
#import "UIView+CGGeometry.h"


@implementation UIInputEvent ( UIView)

- (CGPoint) locationInView:(UIView *) view
{
   CGPoint   point;
   CGPoint   translated;
   UIView    *superview;

   if( ! view)
      return( _locationInWindow);
   if( view == _locationView)
      return( _location);

   translated = [view convertPoint:_locationInWindow
                          fromView:NULL];
   return( translated);
}


- (CGPoint) _locationForView:(UIView *) view
{
   if( ! view)
      return( _locationInWindow);
   if( view == _locationView)
      return( _location);

   return( CGPointMake( CGFLOAT_MIN, CGFLOAT_MIN));
}


- (void) _setLocation:(CGPoint) point
              forView:(UIView *) view
{
   assert( point.x != CGFLOAT_MIN);

   _location      = point;
   _locationView  = view;
}

@end
