#import "import-private.h"


int   main()
{
   UIWindow        *window;
   UIApplication   *app;
   CALayer         *layer;
   UIView          *view;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];
   {
      view  = [UIView viewWithFrame:CGRectMake( 0, 0, 200, 200)];
      [view setMargins:UIEdgeInsetsMake( 10, 10, 10, 10)];
      [view setBackgroundColor:CGColorMakeLightGray()];

      layer = [CALayer layerWithFrame:CGRectMake( 2, 2, 96, 96)];
      [layer setBackgroundColor:CGColorMakeMintCream()];
      [layer setBorderColor:CGColorMakeMistyRose()];
      [layer setCornerRadius:25.0];
      [layer setBorderWidth:5.0];

      [view addLayer:layer];

      layer = [CALayer layerWithFrame:CGRectMake( 102, 2, 96, 96)];
      [layer setBackgroundColor:CGColorMakeMoccasin()];
      [layer setBorderColor:CGColorMakeNavajoWhite()];
      [layer setCornerRadius:25.0];
      [layer setBorderWidth:5.0];

      [view addLayer:layer];

      layer = [CALayer layerWithFrame:CGRectMake( 2, 102, 96, 96)];
      [layer setBackgroundColor:CGColorMakeSandyBrown()];
      [layer setBorderColor:CGColorMakePapayaWhip()];
      [layer setCornerRadius:25.0];
      [layer setBorderWidth:5.0];

      [view addLayer:layer];

      layer = [CALayer layerWithFrame:CGRectMake( 102, 102, 96, 96)];
      [layer setBackgroundColor:CGColorMakeOliveDrab()];
      [layer setBorderColor:CGColorMakeBlanchedAlmond()];
      [layer setCornerRadius:25.0];
      [layer setBorderWidth:5.0];

      [view addLayer:layer];


      window = [UIWindow windowWithView:view
                        titleUTF8String:NULL];

      [window dump];

      [app addWindow:window];
   }
   return( [app run]);
}

