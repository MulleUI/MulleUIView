#import "import-private.h"

#import <string.h>


//
// A simple example, where we have a view controller which manages events
// on behalf of its views. You click on a "button" and the other changes 
// color. Obviously there has to be a connection, and that's the view 
// controller.
//
@interface Button : UIView
@end



@implementation Button

- (UIMouseButtonEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   [self setBackgroundColor:CGColorMakeRandomHueOpaque()];
   [self setNeedsDisplay]; // need this because we are not UIControl based
   return( nil);
}

@end


//
// controllers do not retain the views, views are retained by the window
//
@interface Controller : UIViewController

@property( assign) UIView   *aButton;
@property( assign) UIView   *bButton;

@end


@implementation Controller

// need these property setters to properly wire up buttons to
- (void) setAButton:(UIView *) view
{
   if( view)
      [self addView:view];
   else
      [self removeView:_aButton];
   _aButton = view;
}


- (void) setBButton:(UIView *) view
{
   if( view)
      [self addView:view];
   else
      [self removeView:_bButton];
   _bButton = view;
}


- (UIEvent *) handleEvent:(UIEvent *) event
                   ofView:(UIView *) view
{
   UIEvent   *modifiedEvent;

   // need to use -handleForwardedEvent: to avoid recursion
   if( view == _aButton)
      modifiedEvent = [_bButton handleForwardedEvent:event];
   else
      modifiedEvent = [_aButton handleForwardedEvent:event];
   return( modifiedEvent);
}

@end



int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *application;
   UIView          *contentView;
   Button          *aButton;
   Button          *bButton;
   Controller      *controller;
   CGRect          rect;
   CGRect          frame;
   CGRect          aFrame;
   CGRect          bFrame;

   application = [UIApplication sharedInstance];
   
   /*
    * window and app
    */
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];

   contentView        = [window contentView];
   frame              = [contentView frame];
   rect               = CGRectInset( frame, frame.size.width / 4, frame.size.height / 4);

   aFrame.size.height = rect.size.height / 2.0;
   aFrame.size.width  = rect.size.width;
   aFrame.origin.y    = CGRectGetMidY( rect) - aFrame.size.height - aFrame.size.height / 4.0;
   aFrame.origin.x    = rect.origin.x;

   bFrame.size.height = rect.size.height / 2.0;
   bFrame.size.width  = rect.size.width;
   bFrame.origin.y    = CGRectGetMidY( rect) + bFrame.size.height / 4.0;
   bFrame.origin.x    = rect.origin.x;

   aButton = [Button viewWithFrame:aFrame];
   [aButton setBackgroundColor:CGColorMakePapaya()];
   [contentView addSubview:aButton];

   bButton = [Button viewWithFrame:bFrame];
   [bButton setBackgroundColor:CGColorMakeChartreuse()];
   [contentView addSubview:bButton];

   controller = [Controller object];
   [controller setAButton:aButton];
   [controller setBButton:bButton];
   [window addToViewControllers:controller];

   [window dump];

   [application addWindow:window];

   return( [application runApp]);
}

