#import <MulleUIView/MulleUIView.h>


int   main( void)
{
   UIView      *view;
   UIView      *subview;
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

   for( ;i < 10; i++)
   {
      subview = [UIView instance];
      [subview setTag:i];

      [view insertSubview:subview
                  atIndex:0];
   }

   n = [view getSubviews:buf
                    range:MulleMakeFullRange()];
   for( i = 0; i < n; i++)
      printf( "%tu\n", [buf[ i] tag]);

   return( 0);
}

