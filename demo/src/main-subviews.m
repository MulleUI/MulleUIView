#import "import-private.h"

// just three nested views...

void   setupSceneInContentView( UIView *contentView)
{
   CGRect   contentRect;
   UIView   *view;
   UIView   *subview;
   UIView   *subsubview;

   contentRect = [contentView contentRect];

   view  = [UIView viewWithFrame:CGRectInset( contentRect, 40.0, 40.0)];
   [view setBackgroundColor:CGColorMakeDarkOrchid()];
   [view setBorderWidth:4.0];
   [view setBorderColor:CGColorMakeDarkGray()];
   [contentView addSubview:view];

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
   UIWindow        *window;
   UIApplication   *app;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 400, 300)];
   [window setBackgroundColor:CGColorMakeGray()];

   setupSceneInContentView( [window contentView]);

   [window dump];

   [app addWindow:window];

   return( [app runApp]);
}

