#import <MulleUIView/MulleUIView.h>


#include "screen.inc"


int   main( void)
{
   UIView    *view;
   UIView    *subview;
   CGRect    rect;

   view    = [UIView viewWithFrame:CGRectMake( 2, 2, SCREEN_W - 4, SCREEN_H - 4)];
   [view setNameUTF8String:"parent"];

   rect    = [view bounds];
   rect.size.height /= 2.0;

   subview = [UIView viewWithFrame:rect];

   // not sure, if this isn't stupid. Use contentMode for initial placement
   // in the bottom half of the screen, then use legacy resizing to keep
   // it there. Could be more sanely achieved by using CGRectPlaceInRect before
   // +viewWithFrame:
   [subview setAutoresizingMask:UIViewAutoresizingScaleToFillHorizontal
                                |UIViewAutoresizingBottom
                                |UIViewAutoresizingMixedMode
                                |UIViewAutoresizingFlexibleWidth
                                |UIViewAutoresizingFlexibleHeight
                                |UIViewAutoresizingFlexibleTopMargin];
   [subview setNameUTF8String:"child"];
   [view addSubview:subview];

   // SETUP
   printf( "Before:\n");
   UIViewASCIIRender( view, stdout);

   // FIRST LAYOUT
   [view layout];

   printf( "After:\n");
   UIViewASCIIRender( view, stdout);

   // RESIZE
   [view setFrame:CGRectMake( 0, 0, SCREEN_W, SCREEN_H)];
   [view layout];

   printf( "Resize:\n");
   UIViewASCIIRender( view, stdout);

   return( 0);
}

