#import "import-private.h"


int   main()
{
   UIWindow          *window;
   UIApplication     *app;
   CGGraphicsLayer   *layer;
   UIView            *view;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];
   {
      view  = [UIView viewWithFrame:CGRectMake( 0, 0, 200, 75)];
      [view setMargins:UIEdgeInsetsMake( 10, 10, 10, 10)];

      layer = MULLE_OBJC_CLASS_CAST( CGGraphicsLayer, [view layer]);
      [layer setBackgroundColor:CGColorMakeWithRGB( 0.0, 1.0, 0.0)];
      [layer setBorderColor:CGColorMakeWithRGB( 1.0, 0.0, 0.0)];
      [layer setCornerRadius:20];
      [layer setBorderWidth:25];

      window = [UIWindow windowWithView:view
                        titleUTF8String:NULL];

      [window dump];

      [app addWindow:window];
   }
   return( [app runApp]);
}

