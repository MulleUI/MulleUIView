#import "import-private.h"


// just an example of bounds
int   main()
{
   UIWindow        *window;
   UIApplication   *app;
   CGRect          bounds;
   UIView          *view;
   UIView          *contentView;

   app = [UIApplication sharedInstance];
   {
      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 640, 400)];
      [window setBackgroundColor:CGColorMakeGray()];

      contentView = [window contentView];
      bounds      = [contentView bounds];
      bounds.origin.x = 50.0; 
      assert( bounds.origin.y == 0.0);
      [contentView setBounds:bounds];

      view  = [UIView viewWithFrame:CGRectMake( 100, 100, 300, 200)];
      [view setBackgroundColor:CGColorMakeDarkOrchid()];
      [view setBorderWidth:4.0];
      [view setBorderColor:CGColorMakeDarkGray()];
      [contentView addSubview:view];

      [app addWindow:window];
   }
   return( [app runApp]);
}

