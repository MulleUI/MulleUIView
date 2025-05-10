#import "import-private.h"

#import <string.h>


#ifndef LEVELS
# define LEVELS           3
# define TRICKY_BOUNDS
# define OBSCURING_VIEW
#endif


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
@interface PointsLayer : CGGraphicsLayer
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


- (BOOL) drawInContext:(CGContext *) context
{
   struct NVGcontext                     *vg;
   struct mulle_structarrayenumerator    rover;
   struct Point                          *p;

   if( ! [super drawInContext:context])
      return( NO);

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

      nvgBeginPath( vg);
      nvgStrokeWidth( vg, 0.75);
      nvgStrokeColor( vg, CGColorDim( CGColorMakeWhite(), 0.15));
      nvgMoveTo( vg, p->point.x - 2.0, p->point.y);
      nvgLineTo( vg, p->point.x + 2.0, p->point.y);
      nvgMoveTo( vg, p->point.x, p->point.y - 2.0);
      nvgLineTo( vg, p->point.x, p->point.y + 2.0);
      nvgStroke( vg);
   }
   _mulle_structarrayenumerator_done( &rover);
   return( YES);
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

   // MEMO: in terms of API, using _locationForView: is wrong as it is
   //       not guaranteed that we are called by code, following the 
   //       "official" hitTest: code. This is just here to check that 
   //       it works as expected.
   point  = [event _locationForView:self];
   point2 = [event locationInView:self];

   MulleUILog( "**** %#@ -> cL=%s mL=%s (c=%s)",
                  event,
                  CGPointUTF8String( point),
                  CGPointUTF8String( point2),
                  CGRectUTF8String( [self contentRect]));

   layer = (PointsLayer *) _mainLayer;
   if( (rand() & 0x8000) == 0x8000)
   {
      // use _locationForView
      color = CGColorMakeWithHSL( fmod( CGFloatMakeRandom(), 0.5), 0.75, 0.5);
      [layer addCircleAtPoint:point
                        color:color];
   }
   else
   {
      // use locationInView
      color = CGColorMakeWithHSL( fmod( CGFloatMakeRandom(), 0.5) + 0.5, 1.0, 0.5);
      [layer addSquareAtPoint:point2
                        color:color];
   }
   [self setNeedsDisplay]; // need this because we are not UIControl based
   return( nil);
}

@end


@interface UIObscuringView : UIView
@end


typedef NS_ENUM( NSUInteger, CGAxis)
{
   CGHorizontalAxis = 1,
   CGVerticalAxis   = 2
};


static CGPoint   CGRectMirrorPointAlongAxes( CGRect  rect, CGPoint point, CGAxis axes)
{
   //
   //  p 1,2
   //  r: -1,0,5,4  m: 3,2


   if( axes & CGHorizontalAxis)
   {
      // move axis to zero
      point.x -= CGRectGetMidX( rect);
      point.x  = -point.x;
      point.x += CGRectGetMidX( rect);
   }
   if( axes & CGVerticalAxis)
   {
      // move axis to zero
      point.y -= CGRectGetMidY( rect);
      point.y  = -point.y;
      point.y += CGRectGetMidY( rect);
   }
   return( point);
}

@implementation UIObscuringView

- (UIView *) hitSearchSubviews:(CGPoint) contentLocation
         withInputEventPointer:(UIInputEvent **) event_p
{
   struct UIInputState   state;
   CGPoint               point;
   CGPoint               mirrored;
   UIInputEvent          *event;
   UIInputEvent          *newEvent;
   CGRect                rect;

   if( ! event_p)
      return( nil);

   event   = *event_p;
   point   = [event locationInView:self];
   rect    = [self contentRect];

   // mirror on x-axis
   state    = [event inputState];
   mirrored = CGRectMirrorPointAlongAxes( rect, point, CGHorizontalAxis);
   state.locationInWindow = [self convertPoint:mirrored
                                        toView:nil];
   newEvent = [[[[event class] alloc] initWithInputState:&state] autorelease];
   MulleUILog( "Change event: %#@ -> %#@\n", event, newEvent);

   *event_p = newEvent;

   return( nil);
}

@end


static void   setupScene( UIWindowPlane *contentPlane)
{
   UIView         *view;
   CGRect         frame;
   UIEdgeInsets   insets;
#ifdef TRICKY_BOUNDS
   CGRect         bounds;
   CGRect         obscuringViewFrame;
   UIView         *obscuringView;
   UIView         *subview;
   UIView         *subview2;
#endif

#ifdef TRICKY_BOUNDS
   insets = UIEdgeInsetsMake( 25, 25, 25, 25);
#else
   insets = UIEdgeInsetsMake( 50, 50, 50, 50);
#endif

   frame  = UIEdgeInsetsInsetRect( [contentPlane contentRect], insets);

   view   = [UIPointsView viewWithFrame:frame];
   [view setNameUTF8String:"parent"];
   [view setBackgroundColor:CGColorMakeWithRGBA( 0.25, 0.0, 0.0, 1.0)];
   [view setBorderColor:CGColorMakeWithRGBA( 0.75, 0.0, 0.0, 1.0)];
   [view setBorderWidth:1.0];

#ifdef TRICKY_BOUNDS
   bounds.origin       = CGPointZero;
   bounds.size.width   = frame.size.width / 2.0;
   bounds.size.height  = frame.size.height / 2.0;
   [view setBounds:bounds];
#endif

   [contentPlane addSubview:view];

#ifdef OBSCURING_VIEW
   obscuringViewFrame              = frame;
   obscuringViewFrame.size.width  /= 2.5;
   obscuringViewFrame.size.height /= 2.5;
   obscuringViewFrame.origin.x     = frame.size.width / 2.0;
   obscuringViewFrame.origin.y     = frame.size.height / 2.0;

   obscuringView = [UIObscuringView viewWithFrame:obscuringViewFrame];
   [obscuringView setNameUTF8String:"obscure"];
   [obscuringView setBackgroundColor:CGColorMakeWithRGBA( 0.5, 0.5, 0.5, 0.4)];
   [obscuringView setBorderColor:CGColorMakeWithRGBA( 0.75, 0.75, 0.75, 0.8)];
   [obscuringView setBorderWidth:1.0];
   [contentPlane addSubview:obscuringView];

#endif

#if LEVELS > 1
   /*
    *
    */
   frame   = [view contentRect];
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   subview = [UIPointsView viewWithFrame:frame];
   [subview setNameUTF8String:"child"];
   [subview setBackgroundColor:CGColorMakeWithRGBA( 0.0, 0.25, 0.0, 1.0)];
   [subview setBorderColor:CGColorMakeWithRGBA( 0.0, 0.75, 0.0, 1.0)];
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
   [subview2 setNameUTF8String:"grandchild"];
   [subview2 setBackgroundColor:CGColorMakeWithRGBA( 0.0, 0.0, 0.25, 1.0)];
   [subview2 setBorderColor:CGColorMakeWithRGBA( 0.0, 0.0, 0.75, 1.0)];
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
   NSUInteger      styleMask;

   application = [UIApplication sharedInstance];
   
   /*
    * window and app
    */
   styleMask = UIWindowStyleMaskDefault;
   styleMask = UIWindowsStyleMaskBySetting( styleMask, UIWindowStylePlanes, NO);
   styleMask = UIWindowsStyleMaskBySetting( styleMask, UIWindowStyleResizable, NO);

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)
                      titleUTF8String:"Demo"
                            styleMask:styleMask];   

   setupScene( [window contentView]);

   [window dump];

   [application addWindow:window];

   return( [application runApp]);
}

