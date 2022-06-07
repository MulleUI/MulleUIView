#import <MulleUIView/MulleUIView.h>


int   main( void)
{
   UIView    *view;
   UIView    *subview;
   CGPoint   point;

   view    = [UIView viewWithFrame:CGRectMake( 1, 2, 800, 400)];

   point = [view contentLocationForLocation:CGPointMake( 3, 4)];
   printf( "p1=%s\n", CGPointUTF8String( point));

   subview = [UIView viewWithFrame:CGRectMake( 400, 0, 300, 150)];
   [view addSubview:subview];

   point = [subview contentLocationForLocation:CGPointMake( 3, 4)];
   printf( "p=%s\n", CGPointUTF8String( point));

   point = [subview convertPoint:CGPointMake( 3, 4) toView:nil];
   printf( "to=%s\n", CGPointUTF8String( point));

   point = [subview convertPoint:point fromView:nil];
   printf( "from=%s\n", CGPointUTF8String( point));

   return( 0);
}

