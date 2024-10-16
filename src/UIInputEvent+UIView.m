#import "UIInputEvent+UIView.h"

#import "import-private.h"

#import "UIView.h"
#import "UIView+CGGeometry.h"


@implementation UIInputEvent ( UIView)

- (CGPoint) locationInView:(UIView *) view
{
   CGPoint   translated;

   if( ! view)
      return( _inputState.locationInWindow);
   if( view == _locationView)
      return( _location);

   translated = [view convertPoint:_inputState.locationInWindow
                          fromView:NULL];
   return( translated);
}


- (CGPoint) _locationForView:(UIView *) view
{
   if( ! view)
      return( _inputState.locationInWindow);
   if( view == _locationView)
      return( _location);

   return( CGPointNull);
}


- (void) _setLocation:(CGPoint) point
              forView:(UIView *) view
{
   assert( ! CGPointIsNull( point));

   _location      = point;
   _locationView  = view;
}


- (UIView *) _view
{
   return( _locationView);
}

@end
