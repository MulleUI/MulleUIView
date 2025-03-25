#import <MulleUIView/MulleUIView.h>


#include "screen.inc"


int   main( void)
{
   UIView       *view;
   UIView       *subview;
   NSUInteger   contentMode;

   for( contentMode = 0; contentMode <= UIViewAutoresizingContentModeBits; contentMode++)
   {
      if( ! CGContentModeIsValid( contentMode))
         continue;

      view    = [UIView viewWithFrame:CGRectMake( 0, 0, SCREEN_W, SCREEN_H)];
      [view setPadding:UIEdgeInsetsMake( 1, 1, 1, 1)];

      // must place it within padding though
      subview = [UIView viewWithFrame:CGRectMake( 4, 3, 3, 4)];
      [subview setAutoresizingMask:contentMode];
      [view addSubview:subview];

      [view layout];
      mulle_printf( "%s:\n", CGContentModeUTF8String( contentMode));
      UIViewASCIIRender( view, stdout);
   }

   return( 0);
}

