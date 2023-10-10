#import <MulleUIView/MulleUIView.h>


int   main( void)
{
   UIView      *view;
   UIView      *subview;
   NSUInteger   i, n;
   UIView       *buf[ 10];

   view = [UIView object];

   for( i = 0; i < 3; i++)
   {
      subview = [UIView object];
      [subview setTag:i];

      [view insertSubview:subview
                  atIndex:i];
   }

   subview = [UIView object];
   [subview setTag:3];

   [view insertSubview:subview
         belowSubview:[view subviewWithTag:1]];

   n = [view getSubviews:buf
                    range:MulleMakeFullRange()];
   for( i = 0; i < n; i++)
      printf( "%tu\n", [buf[ i] tag]);

   subview = [UIView object];
   [subview setTag:4];

   [view insertSubview:subview
          belowSubview:[view subviewWithTag:2]];

   n = [view getSubviews:buf
                    range:MulleMakeFullRange()];
   for( i = 0; i < n; i++)
      printf( "%tu\n", [buf[ i] tag]);

   return( 0);
}

