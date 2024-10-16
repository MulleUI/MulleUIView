#import "import-private.h"

#import <string.h>


//
// This demo demonstates how the bounds affect the hit test. mouseDown: events
// in the white parts (out of bounds) of a View will not be received, as the
// hitTest fails. 
//
@interface View : UIView 
@end  


@implementation View 

- (UIMouseButtonEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   CGColor   color;

   color = [[self backgroundPaint] mainColor];
   color = CGColorInvertRGB( color);
   [self setBackgroundColor:color];
   [self setNeedsDisplay];
   return( nil);
}

- (UIMouseButtonEvent *) mouseUp:(UIMouseButtonEvent *) event
{
   CGColor   color;

   color = [[self backgroundPaint] mainColor];
   color = CGColorInvertRGB( color);
   [self setBackgroundColor:color];
   [self setNeedsDisplay];
   return( nil);
}

@end 


void   setupSceneInContentView( UIView *contentView)
{
   CGRect       contentRect;
   CGRect       frame;
   UIView       *container;
   View         *view;
   View         *subView;
   CGRect       rects[ 3][ 3];
   NSUInteger   x, y;
   CGRect       bounds;
   BOOL         flag;

   contentRect = [contentView contentRect];
   contentRect = CGRectInset( contentRect, 10.0, 10.0);
   CGRectPartition3x3( contentRect, CGSizeMake( 10.0, 10.0), rects);
   for( y = 0; y < 3; y++)
      for( x = 0; x < 3; x++)
      {
         frame     = rects[ y][ x];
         container = [UIView viewWithFrame:frame];
         [container setBorderColor:CGColorMakeBlack()];
         [container setBorderWidth:1.0];
         [contentView addSubview:container];

         frame = [container contentRect];
         view  = [View viewWithFrame:frame];
         [view setBackgroundColor:CGColorMakeWithRandomName()];
         [view setBorderColor:CGColorMakeDarkGray()];
         [view setBorderWidth:2.0];

         [container addSubview:view];

         frame   = [view contentRect];
         frame   = CGSizePlaceInRect( CGSizeMake( frame.size.width / 2.0,
                                                  frame.size.height / 2.0),
                                      frame,
                                      CGContentModeCenterPoint);

         subView = [View viewWithFrame:frame];
         [subView setBackgroundColor:CGColorMakeWithRandomName()];
         [subView setBorderColor:CGColorMakeWhite()];
         [subView setBorderWidth:1.0];
         [view addSubview:subView];


//
         bounds = [view bounds];
         bounds.origin.x = (x < 1) 
                           ? -bounds.size.width / 4.0 
                           : (x > 1)
                             ? bounds.size.width / 4.0
                             : 0.0;
         bounds.origin.y = (y < 1) 
                           ? -bounds.size.height / 4.0 
                           : (y > 1)
                             ? bounds.size.height / 4.0
                             : 0.0;

         [view setBounds:bounds];
      }
}


int   main()
{
   UIWindow        *window;
   UIApplication   *app;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];
   [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];

   setupSceneInContentView( [window contentView]);

   [window dump];

   [app addWindow:window];

   return( [app runApp]);
}

