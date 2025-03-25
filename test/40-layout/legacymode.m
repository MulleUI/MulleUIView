#import <MulleUIView/MulleUIView.h>


#include "screen.inc"


#define START   0x10000
#define END     UIViewAutoresizingLegacyBits // inclusive
#define STEP    0x10000


int   main( void)
{
   UIView       *view;
   UIView       *subview;
   NSUInteger   autoresizingMask;

   for( autoresizingMask = START; autoresizingMask <= END; autoresizingMask += STEP)
   {
      view    = [UIView viewWithFrame:CGRectMake( 0, 0, SCREEN_W / 3 * 2, SCREEN_H / 3 * 2)];
      [view setPadding:UIEdgeInsetsMake( 1, 1, 1, 1)];

      // must place it within padding though
      subview = [UIView viewWithFrame:CGRectMake( 3, 2, 2, 3)];
      [subview setAutoresizingMask:autoresizingMask];
      [view addSubview:subview];
      mulle_printf( "%s:\n", UIViewAutoresizingMaskUTF8String( autoresizingMask));
      // initial layout
      UIViewASCIIRender( view, stdout);

      // layouting it now, shouldn't change anything (since the parent view
      // did not get resized)
      [view layout];  // subview shouldn't really change here or ?
      mulle_printf( "   vvv\n");
      UIViewASCIIRender( view, stdout);

      // one more time just to be sure
      [view layout];  // subview shouldn't really change here or ?
      mulle_printf( "   vvv\n");
      UIViewASCIIRender( view, stdout);

      // now change the parent, so subviews will be autoresizing
      [view setFrame:CGRectMake( 0, 0, SCREEN_W, SCREEN_H)];
      [view layout];  // now the autoresizing mask comes into play
      mulle_printf( "   vvv\n");
      UIViewASCIIRender( view, stdout);
      mulle_printf( "\n");

      // a second run should not change anything
      [view layout];  // now the autoresizing mask comes into play
      mulle_printf( "   vvv\n");
      UIViewASCIIRender( view, stdout);
      mulle_printf( "\n");
   }

   return( 0);
}

