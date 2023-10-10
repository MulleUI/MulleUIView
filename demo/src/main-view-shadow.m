#import "import-private.h"


static void   setupSceneInContentView( UIView *contentView)
{
   CGRect          contentRect;
   CGRect          frame;
   CGRect          otherFrame;
   UIView          *view;
   UIView          *otherView;
   CAShadowLayer   *shadowLayer;

   contentRect = [contentView contentRect];
   frame       = CGRectInset( contentRect, 50.0, 50.0);
   otherFrame  = CGRectInset( frame, -20.0, frame.size.height / 3.0f);

   otherView   = [UIView viewWithFrame:otherFrame];
   [otherView setBackgroundColor:CGColorMakeSandyBrown()];
   [contentView addSubview:otherView];

   view  = [UIView viewWithFrame:frame];
   [view setBackgroundColor:CGColorBySettingAlpha( CGColorMakeDodgerBlue(), 0.5)];
   [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [view setShowsShadow:YES];
   [contentView addSubview:view];

   // setup shadow (could do this before adding view to contentView, but
   // we need otherView in contentView for the translation)
   shadowLayer = [view shadowLayer];
   [shadowLayer setShadowColor:CGColorMakeWithRGBA( 0.0, 1.0, 0.0, 0.5)];
   [shadowLayer setShadowHole:[contentView convertRect:otherFrame
                                                toView:view]];
}


int   main()
{
   UIWindow        *window;
   UIApplication   *app;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];

   @autoreleasepool
   {
      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 400, 300)];

      setupSceneInContentView( [window contentView]);

      [app addWindow:window];
   }

   return( [app run]);
}

