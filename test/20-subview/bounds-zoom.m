#import <MulleUIView/MulleUIView.h>


int   main( void)
{
   UIView    *view;
   UIView    *subview;
   CGPoint   point;

   view = [UIView viewWithFrame:CGRectMake( 1, 2, 800, 400)];
   // bounds are half the frame, so we zoom x2
   [view setBounds:CGRectMake( 0, 0, 400, 200)];

   // the location in "frame" coordinates is translated to
   // contentRect: therefore this should be smack dab in the middle
   //
   point = [view contentLocationForLocation:CGPointMake( 401, 202)];
   printf( "p1=%s\n", CGPointUTF8String( point));

   point = [view locationForContentLocation:point];
   printf( "p2=%s\n", CGPointUTF8String( point));

   subview = [UIView viewWithFrame:CGRectMake( 100, 0, 200, 100)];
   [view addSubview:subview];

   point = [subview contentLocationForLocation:CGPointMake( 1, 1)];
   printf( "p1=%s\n", CGPointUTF8String( point));

   point = [subview locationForContentLocation:point];
   printf( "p2=%s\n", CGPointUTF8String( point));

   point = [subview convertPoint:CGPointMake( 3, 4) toView:nil];
   printf( "to=%s\n", CGPointUTF8String( point));

   point = [subview convertPoint:point fromView:nil];
   printf( "from=%s\n", CGPointUTF8String( point));

   return( 0);
}

