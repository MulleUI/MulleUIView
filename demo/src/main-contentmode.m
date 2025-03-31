#import "import.h"

#import <string.h>

struct
{
   uint32_t     color1;
   uint32_t     color2;
   NSUInteger   mask;
} subviewInfo[ 12] =
{
   { 0x7F7F7F7F, 0xCFCFCF7F, UIViewAutoresizingScaleToFill           },
   { 0x4040407F, 0x8080807F, UIViewAutoresizingScaleToFillHorizontal },
   { 0x2020207F, 0x6060607F, UIViewAutoresizingScaleToFillVertical   },

   // TL, TC, TR (blueish)
   { 0x20FFFFF, 0, UIViewAutoresizingTop|UIViewAutoresizingLeft },
   { 0xA0FFFFF, 0, UIViewAutoresizingTop },
   { 0x60FFFFF, 0, UIViewAutoresizingTop|UIViewAutoresizingRight },

   // ML, MC, MR (magenta)
   { 0xFF20FFFF, 0, UIViewAutoresizingLeft },
   { 0xFF80FFFF, 0, UIViewAutoresizingCenter },
   { 0xFF40FFFF, 0, UIViewAutoresizingRight },

   // BL, BC, BR (yellow)
   { 0xFFFF20FF, 0, UIViewAutoresizingBottom|UIViewAutoresizingLeft },
   { 0xFFFF80FF, 0, UIViewAutoresizingBottom },
   { 0xFFFF40FF, 0, UIViewAutoresizingBottom|UIViewAutoresizingRight }
};


void   setupScene( UIWindowPlane *contentPlane)
{
   UIView         *view;
   UIView         *subview;
   CGRect         frame;
   UIEdgeInsets   insets;
   NSUInteger     i;
   char           buf[ 64];
   CGPaint        *paint;

   frame = [contentPlane contentRect];
   [contentPlane setPadding:UIEdgeInsetsMake( 4.0, 4.0, 4.0, 4.0)];

   view  = [UIView viewWithFrame:frame];
   [view setNameUTF8String:"parent"];
   [view setAutoresizingMask:UIViewAutoresizingScaleToFill];
   [view setBackgroundColor:CGColorMakeGreen()];

   // padding of the subviews
   [view setPadding:UIEdgeInsetsMake( 4.0, 4.0, 4.0, 4.0)];

   [contentPlane addSubview:view];
#if 1
   for( i = 0; i < 12; i++)
   {
      frame   = CGRectMake( 20, 20, 20, 20);
      subview = [UIView viewWithFrame:frame];

      sprintf( buf, "child #%ld", (long) i);
      [subview setNameUTF8String:buf];
      if( subviewInfo[ i].color2)
      {
         paint = CGGradientCreate( CGColorMakeWithHexColor( subviewInfo[ i].color1), 
                                   CGColorMakeWithHexColor( subviewInfo[ i].color2));
         [subview setBackgroundPaint:paint]; 
      }
      else
         [subview setBackgroundColor:CGColorMakeWithHexColor( subviewInfo[ i].color1)];
      [subview setAutoresizingMask:subviewInfo[ i].mask];
      [view addSubview:subview];
      [view setNeedsLayout];
   }
#endif   
}


int   main()
{
   UIWindow        *window;
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   /*
    * window and app
    */
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];
   [window setBackgroundColor:CGColorMakeWhite()];

   setupScene( [window contentView]);

   [window dump];

   [app addWindow:window];

   return( [app runApp]);
}
