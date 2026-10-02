#import <MulleUIView/MulleUIView.h>


int   main( void)
{
   UIView       *view;
   UIView       *subview;
   NSUInteger   i, n;
   UIView       *buf[ 10];

   view = [UIView instance];

   for( i = 0; i < 5; i++)
   {
      subview = [UIView instance];
      [subview setTag:i];

      [view insertSubview:subview
                  atIndex:i];
   }

   // swap index 1 and index 3 (tags 1 and 3)
   [view exchangeSubviewAtIndex:1
             withSubviewAtIndex:3];

   n = [view getSubviews:buf
                    range:MulleMakeFullRange()];
   for( i = 0; i < n; i++)
      printf( "%tu\n", [buf[ i] tag]);

   return( 0);
}
