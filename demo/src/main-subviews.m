#import "import-private.h"

// just three nested views...

void   setupSceneInContentPlane( UIWindowPlane *plane)
{
   CGRect   contentRect;
   UIView   *view;
   UIView   *subview;
   UIView   *subsubview;

   contentRect = [plane contentRect];

   view  = [UIView viewWithFrame:CGRectInset( contentRect, 40.0, 40.0)];
   [view setBackgroundColor:CGColorMakeDarkOrchid()];
   [view setBorderWidth:4.0];
   [view setBorderColor:CGColorMakeDarkGray()];
   [plane addSubview:view];

   contentRect = [view contentRect];

   subview  = [UIView viewWithFrame:CGRectInset( contentRect, 40.0, 40.0)];
   [subview setBackgroundColor:CGColorMakePaleGoldenrod()];
   [subview setBorderWidth:4.0];
   [subview setBorderColor:CGColorMakeGray()];
   [view addSubview:subview];

   contentRect = [subview contentRect];

   subsubview  = [UIView viewWithFrame:CGRectInset( contentRect, 40.0, 40.0)];
   [subsubview setBorderWidth:4.0];
   [subsubview setBorderColor:CGColorMakeGray()];
   [subsubview setBackgroundColor:CGColorMakeFuchsia()];
   [subview addSubview:subsubview];

}


int   main()
{
   CGContext       *context;
   UIWindow        *window;
   UIApplication   *app;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 400, 300)];
   [window setBackgroundColor:CGColorMakeGray()];

   setupSceneInContentPlane( [window contentPlane]);

   [window dump];

   [app addWindow:window];

   return( [app run]);
}

