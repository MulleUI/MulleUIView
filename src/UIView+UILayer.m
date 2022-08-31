//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "UIView+UILayer.h"

#import "import-private.h"


#if 0
@implementation CALayer ( UIView)

- (void) updateTransform:(CGAffineTransform *) transform
{
   CGRect          frame;
   CGRect          bounds;
   CGPoint         scale;
   _NVGtransform   tmp;

   frame  = [self frame];
   bounds = [self bounds];

   nvgTransformTranslate( tmp, bounds.origin.x, bounds.origin.y);
   nvgTransformPremultiply( transform, tmp);

   scale.x = bounds.size.width / frame.size.width;
   scale.y = bounds.size.height / frame.size.height;

   nvgTransformScale( tmp, scale.x, scale.y);
   nvgTransformPremultiply( transform, tmp);

   nvgTransformTranslate( tmp, -frame.origin.x, -frame.origin.y);
   nvgTransformPremultiply( transform, tmp);
}


- (void) updateReverseTransform:(CGAffineTransform *) transform
{
   CGRect          frame;
   CGRect          bounds;
   CGPoint         scale;
   _NVGtransform   tmp;

   frame  = [self frame];
   bounds = [self bounds];

   nvgTransformTranslate( tmp, frame.origin.x, frame.origin.y);
   nvgTransformMultiply( transform, tmp);

   scale.x = frame.size.width / bounds.size.width;
   scale.y = frame.size.height / bounds.size.height;

   nvgTransformScale( tmp, scale.x, scale.y);
   nvgTransformMultiply( transform, tmp);

   nvgTransformTranslate( tmp, bounds.origin.x, bounds.origin.y);
   nvgTransformMultiply( transform, tmp);
}

@end
#endif


@implementation UIView( UILayer)

- (id <UILayer>) layerHitTest:(CGPoint) point
{
   struct mulle_pointerarrayenumerator   rover;
   id <UILayer>                          layer;
   CGRect                                rect;
   CGPoint                               converted;

   rover = mulle_pointerarray_enumerate( &_layers);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &layer))
   {
      rect = [layer frame];
      if( CGRectContainsPoint( rect, point))
         break;
   }
   mulle_pointerarrayenumerator_done( &rover);

   return( layer ? layer : _mainLayer);
}


//
// We want to translate a point that is in the bounds of the UIView
// to the canvas of the layer.
// The bounds of the UIView are the bounds of the mainLayer. So is there
// anything to do ?
//
// For other layers we translate the point into their canvas.
//
- (CGPoint) convertPoint:(CGPoint) point
                 toLayer:(id <UILayer>) layer
{
   CGPoint             translated;
   CGRect              frame;
   CGRect              bounds;
   CGAffineTransform   xform;

   if( ! layer || layer == _mainLayer)
      return( point);

   xform = CGAffineTransformMakeInverseProjection( [layer frame],
                                                   [layer bounds]);
//   nvgTransformIdentity( transform);
//   [layer updateTransform:transform];

   translated = CGPointApplyAffineTransformInline( point, xform);
   return( translated);
}

// TODO: highly dubious and untested code!!
- (CGPoint) convertPoint:(CGPoint) point
               fromLayer:(id <UILayer>) layer
{
   CGPoint             translated;
   CGRect              frame;
   CGRect              bounds;
   CGAffineTransform   xform;

   if( ! layer || layer == _mainLayer)
      return( point);

   xform = CGAffineTransformMakeInverseProjection( [layer bounds],
                                                   [layer frame]);
   translated = CGPointApplyAffineTransformInline( point, xform);
   return( translated);
}

// TODO: highly dubious and untested code!!
- (CGRect) convertRect:(CGRect) rect
               toLayer:(id <UILayer>) layer
{
   CGRect              translated;
   CGRect              frame;
   CGRect              bounds;
   CGAffineTransform   xform;

   if( ! layer || layer == _mainLayer)
      return( rect);

   xform = CGAffineTransformMakeInverseProjection( [layer frame],
                                                   [layer bounds]);
//   nvgTransformIdentity( transform);
//   [layer updateTransform:transform];

   translated = CGRectApplyAffineTransformInline( rect, xform);
   return( translated);
}              

// TODO: highly dubious and untested code!!
- (CGRect) convertRect:(CGRect) rect 
             fromLayer:(id <UILayer>) layer
{
   CGRect              translated;
   CGRect              frame;
   CGRect              bounds;
   CGAffineTransform   xform;

   if( ! layer || layer == _mainLayer)
      return( rect);

   // can we not use projection and flip arguments ?
   xform = CGAffineTransformMakeInverseProjection( [layer bounds],
                                                   [layer frame]);
   translated = CGRectApplyAffineTransformInline( rect, xform);
   return( translated);
}
             
@end
