#import <MulleUIView/MulleUIView.h>


#include "screen.inc"


int   main( void)
{
   UIView    *view;
   UIView    *subview;
   CGPoint   point;

   view    = [UIView viewWithFrame:CGRectMake( 0, 0, SCREEN_W, SCREEN_H)];

   subview = [UIView viewWithFrame:CGRectMake( 0, 0, SCREEN_W, SCREEN_H / 2.0)];
   [subview setAutoresizingMask:UIViewAutoresizingScaleToFillHorizontal|UIViewAutoresizingBottom];
   [view addSubview:subview];

   printf( "Before:\n");
   UIViewASCIIRender( view, stdout);

   [view layout];

   printf( "After:\n");
   UIViewASCIIRender( view, stdout);

   return( 0);
}

