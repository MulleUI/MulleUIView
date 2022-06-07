#import <MulleUIView/MulleUIView.h>


int   main( void)
{
   UIView   *view;

   view = [UIView viewWithFrame:CGRectMake( 32, 64, 128, 256)];

   printf( "f=%s\n", CGRectUTF8String( [view frame]));
   printf( "b=%s\n", CGRectUTF8String( [view bounds]));

   [view setFrame:CGRectMake( 16, 8, 4, 2)];

   printf( "f=%s\n", CGRectUTF8String( [view frame]));
   printf( "b=%s\n", CGRectUTF8String( [view bounds]));

   [view setBounds:CGRectMake( -8, -4, 4, 2)];

   printf( "f=%s\n", CGRectUTF8String( [view frame]));
   printf( "b=%s\n", CGRectUTF8String( [view bounds]));

   [view setFrame:CGRectMake( 32, 64, 128, 256)];

   printf( "f=%s\n", CGRectUTF8String( [view frame]));
   printf( "b=%s\n", CGRectUTF8String( [view bounds]));

   return( 0);
}

