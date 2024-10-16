#import <MulleUIView/MulleUIView.h>

#define SCREEN_W  20
#define SCREEN_H  12


#include "screen.inc"

// run legacy resize code

int   main( void)
{
   UIView    *view;
   UIView    *subview1;
   UIView    *subview2;
   CGPoint   point;

   view     = [UIView viewWithFrame:CGRectMake( 0, 0, SCREEN_W / 2.0, SCREEN_H / 2.0)];

   subview1 = [UIView viewWithFrame:CGRectMake( 0, 0, SCREEN_W / 2.0, SCREEN_H / 4.0)];
   [subview1 setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
   [view addSubview:subview1];

   subview2 = [UIView viewWithFrame:CGRectMake( 0, SCREEN_H / 4.0, SCREEN_W / 2.0, SCREEN_H / 4.0)];
   [subview2 setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];
   [view addSubview:subview2];

   printf( "Before:\n");
   UIViewASCIIRender( view, stdout);

   [view layout];

   printf( "After:\n");
   UIViewASCIIRender( view, stdout);

   [view setFrame:CGRectMake( 0, 0, SCREEN_W, SCREEN_H)];
   [view layout];

   printf( "After Resize:\n");
   UIViewASCIIRender( view, stdout);

   return( 0);
}

