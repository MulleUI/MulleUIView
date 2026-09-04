//
//  UIView+UILayer.m
//  MulleUIView
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "UIView+UILayer.h"

#import "import-private.h"

#import "UIView+DebugPrivate.h"


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
   id <UILayer>   layer;
   CGRect         rect;

   mulle_pointerarray_for( &_layers, layer)
   {
      rect = [layer frame];
      if( CGRectContainsPoint( rect, point))
         break;
   }

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
