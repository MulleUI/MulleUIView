#import <MulleUIView/MulleUIView.h>


#include "screen.inc"


int   main( void)
{
   UIView    *view;
   UIView    *subview;

   view    = [UIView viewWithFrame:CGRectMake( 0, 0, SCREEN_W, SCREEN_H)];
   [view setPadding:UIEdgeInsetsMake( 1, 1, 1, 1)];

   // must place it within padding though
   subview = [UIView viewWithFrame:CGRectMake( 1, 1, 0, 0)];
   [subview setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
   [view addSubview:subview];

   [view layout];
   UIViewASCIIRender( view, stdout);

   return( 0);
}

