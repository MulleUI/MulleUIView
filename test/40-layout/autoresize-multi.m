#import <MulleUIView/MulleUIView.h>
#import <MulleUIView/UIView+DebugPrivate.h>


#include "screen.inc"


int   main( void)
{
   UIView    *view;
   UIView    *subview1;
   UIView    *subview2;
   CGPoint   point;

   view     = [UIView viewWithFrame:CGRectMake( 0, 0, SCREEN_W, SCREEN_H)];
   [view setNameUTF8String:"view"];
   [view setDebuggingFlags:UIViewDebugLayout];

   subview1 = [UIView viewWithFrame:CGRectMake( 1, 1, SCREEN_W - 2 , SCREEN_H / 2.0 - 1)];
   [subview1 setNameUTF8String:"subview1"];
   [subview1 setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin];
   [view addSubview:subview1];

   subview2 = [UIView viewWithFrame:CGRectMake( 1, SCREEN_H / 2.0, SCREEN_W - 2, SCREEN_H / 2.0 - 1)];
   [subview2 setNameUTF8String:"subview2"];
   [subview2 setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin];
   [view addSubview:subview2];

   // SETUP
   printf( "Before:\n");
   UIViewASCIIRender( view, stdout);

   [view layout];

   // FIRST LAYOUT
   printf( "After:\n");
   UIViewASCIIRender( view, stdout);

   // RESIZE
   [view setFrame:CGRectMake( 0, 0, SCREEN_W / 2.0, SCREEN_H / 2.0)];
   [view layout];

   printf( "Resize 1:\n");
   UIViewASCIIRender( view, stdout);

   // RESIZE
   [view setFrame:CGRectMake( 0, 0, SCREEN_W, SCREEN_H)];
   [view layout];

   printf( "Resize 2:\n");
   UIViewASCIIRender( view, stdout);

   return( 0);
}

