#import "UIInputEvent+UIView.h"

#import "import-private.h"

#import "UIView.h"
#import "UIView+CGGeometry.h"


@implementation UIInputEvent ( UIView)

- (CGPoint) mouseLocationInView:(UIView *) view
{
   CGPoint   point;
   CGPoint   translated;
   UIView    *superview;

   if( ! view)
      return( _locationInWindow);

   // TODO: CHECK THIS!!
#if 0
   point = [self _contentLocationForView:view];
   if ( point.x != CGFLOAT_MIN)
   {
#if DEBUG
      fprintf( stderr, "shortcut");
#endif
      return( point);
   }
#endif

   translated = [view convertPoint:_locationInWindow
                          fromView:NULL];
#if 0
   fprintf( stderr, "%s -> %s\n",
               CGPointUTF8String( _locationInWindow),
               CGPointUTF8String( translated));
#endif
   return( translated);
}


- (CGPoint) _contentLocationForView:(UIView *) view
{
   if( view == _translatedView)
      return( _contentLocation);
   // TODO: could unlazy this instead of bail, but...
   return( CGPointMake( CGFLOAT_MIN, CGFLOAT_MIN));
}


- (void) _setContentLocation:(CGPoint) point
                     forView:(UIView *) view
{
   assert( point.x != CGFLOAT_MIN);
   assert( view);

   _contentLocation = point;
   _translatedView  = view;
}


@end
