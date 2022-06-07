#import "import-private.h"

#import <string.h>



struct Point
{
   CGPoint   point;
   CGColor   color;
   int       type;
};


static inline void   Circle_init( struct Point *p, CGPoint point, CGColor color)
{
   if( p)
   {
      p->point = point;
      p->color = color;
      p->type  = 0;
   }
}


static inline void   Square_init( struct Point *p, CGPoint point, CGColor color)
{
   if( p)
   {
      p->point = point;
      p->color = color;
      p->type  = 1;
   }
}


//
// The PointsLayer draws an array of points
//
@interface PointsLayer : CALayer
{
   struct mulle_structarray   _points;
}

@end


@implementation PointsLayer


- (instancetype) initWithFrame:(CGRect) rect
{
   [super initWithFrame:rect];

   _mulle_structarray_init( &_points,
                            sizeof( struct Point),
                            alignof( struct Point),
                            0,
                            NULL);
   return( self);
}


- (void) dealloc
{
   _mulle_structarray_done( &_points);
   [super dealloc];
}



- (void) addCircleAtPoint:(CGPoint) point
                    color:(CGColor) color
{
   struct Point   p;

   Circle_init( &p, point, color);

   _mulle_structarray_add( &_points, &p);
}


- (void) addSquareAtPoint:(CGPoint) point
                    color:(CGColor) color
{
   struct Point   p;

   Square_init( &p, point, color);

   _mulle_structarray_add( &_points, &p);
}


- (void) drawInContext:(CGContext *) context
{
   struct NVGcontext                     *vg;
   struct mulle_structarrayenumerator    rover;
   struct Point                          *p;

   [super drawInContext:context];

   vg    = CGContextGetNVGContext( context);
   rover = _mulle_structarray_enumerate( &_points);
   while( _mulle_structarrayenumerator_next( &rover, (void **) &p))
   {
      nvgBeginPath( vg);
      nvgFillColor( vg, p->color);
      if( p->type)
         nvgRect( vg, p->point.x - 2.5, p->point.y - 2.5, 5.0, 5.0);
      else
         nvgCircle( vg, p->point.x, p->point.y, 3.0);
      nvgFill( vg);
   }
   _mulle_structarrayenumerator_done( &rover);
}

@end


//
// The PointsView uses the PointsLayer to draw points. It accepts events
// and creates the points.
//
@interface UIPointsView : UIView
@end



@implementation UIPointsView

+ (Class) layerClass
{
   return( [PointsLayer class]);
}


- (UIMouseButtonEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   CGPoint        point;
   CGPoint        point2;
   CGColor        color;
   PointsLayer    *layer;

   // faster
   point  = [event _contentLocationForView:self];
   point2 = [event mouseLocationInView:self];

   MulleUILog( "**** %#@ -> cL=%s mL=%s (c=%s)",
                  event,
                  CGPointUTF8String( point),
                  CGPointUTF8String( point2),
                  CGRectUTF8String( [self contentRect]));

   layer = (PointsLayer *) _mainLayer;
   if( (rand() & 0x8000) == 0x8000)
   {
      // use translatedPointForView
      color = CGColorMakeHSL( fmod( CGFloatMakeRandom(), 0.5), 0.75, 0.5);
      [layer addCircleAtPoint:point
                        color:color];
   }
   else
   {
      // use mouseLocationInView
      color = CGColorMakeHSL( fmod( CGFloatMakeRandom(), 0.5) + 0.5, 1.0, 0.5);
      [layer addSquareAtPoint:point2
                        color:color];
   }
   [self setNeedsDisplay];
   return( nil);
}

@end


#define LEVELS          3

#define TRICKY_BOUNDS

static void   setupScene( UIWindowPlane *contentPlane)
{
   UIView         *view;
   UIView         *subview;
   UIView         *subview2;
   CGRect         frame;
   UIEdgeInsets   insets;


#ifdef TRICKY_BOUNDS
   insets = UIEdgeInsetsMake( 25, 25, 25, 25);
#else
   insets = UIEdgeInsetsMake( 50, 50, 50, 50);
#endif

   frame  = UIEdgeInsetsInsetRect( [contentPlane contentRect], insets);

   view   = [UIPointsView viewWithFrame:frame];
   [view setDebugNameUTF8String:"parent"];
   [view setBackgroundColor:CGColorMakeRGBA( 0.25, 0.0, 0.0, 1.0)];
   [view setBorderColor:CGColorMakeRGBA( 0.75, 0.0, 0.0, 1.0)];
   [view setBorderWidth:1.0];

#ifdef TRICKY_BOUNDS
   frame.origin       = CGPointZero;
   frame.size.width  /= 2.0;
   frame.size.height /= 2.0;
   [view setBounds:frame];
#endif

   [contentPlane addSubview:view];

#if LEVELS > 1
   /*
    *
    */
   frame   = [view contentRect];
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   subview = [UIPointsView viewWithFrame:frame];
   [subview setDebugNameUTF8String:"child"];
   [subview setBackgroundColor:CGColorMakeRGBA( 0.0, 0.25, 0.0, 1.0)];
   [subview setBorderColor:CGColorMakeRGBA( 0.0, 0.75, 0.0, 1.0)];
   [subview setBorderWidth:1.0];

# ifdef TRICKY_BOUNDS
   frame.origin       = CGPointMake( -10, 0);
   frame.size.width  /= 3.0;
   frame.size.height /= 3.0;
   [subview setBounds:frame];
# endif

   [view addSubview:subview];


# if LEVELS > 2

   /*
    *
    */

   frame  = [subview contentRect];
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   // clipped by view, but not by subview, which doesn't clip
   subview2 = [UIPointsView viewWithFrame:frame];
   [subview2 setDebugNameUTF8String:"grandchild"];
   [subview2 setBackgroundColor:CGColorMakeRGBA( 0.0, 0.0, 0.25, 1.0)];
   [subview2 setBorderColor:CGColorMakeRGBA( 0.0, 0.0, 0.75, 1.0)];
   [subview2 setBorderWidth:1.0];

#  ifdef TRICKY_BOUNDS
   frame.origin       = CGPointZero;
   frame.size.width  *= 2.0;
   frame.size.height *= 2.0;
   [subview2 setBounds:frame];
#  endif

   [subview addSubview:subview2];
# endif
#endif

}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *application;

   application = [UIApplication sharedInstance];
   /*
    * window and app
    */
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];

   setupScene( [window contentPlane]);

   [window dump];

   [application addWindow:window];

   return( [application run]);
}

