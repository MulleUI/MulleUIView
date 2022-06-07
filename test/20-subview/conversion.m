#import <MulleUIView/MulleUIView.h>


int   main( void)
{
   UIView    *view;
   UIView    *subview;
   CGPoint   point;

   view  = [UIView viewWithFrame:CGRectMake( 0, 0, 800, 400)];
   [view setBounds:CGRectMake( -10, +10, 400, 200)];

   subview = [UIView viewWithFrame:CGRectMake( 0, 0, 400, 200)];
   [subview setBounds:CGRectMake( -10, +10, 200, 100)];
   [view addSubview:subview];

   point = [view convertPoint:CGPointMake( 0, 0) toView:subview];
   printf( "view to subview=%s\n", CGPointUTF8String( point));

   point = [view convertPoint:CGPointMake( 0, 0) fromView:subview];
   printf( "view from subview=%s\n", CGPointUTF8String( point));

   point = [view convertPoint:CGPointMake( 0, 0) toView:nil];
   printf( "view to nil=%s\n", CGPointUTF8String( point));

   point = [view convertPoint:CGPointMake( 0, 0) fromView:nil];
   printf( "view from nil=%s\n", CGPointUTF8String( point));


   point = [subview convertPoint:CGPointMake( 0, 0) toView:view];
   printf( "subview to view=%s\n", CGPointUTF8String( point));

   point = [subview convertPoint:CGPointMake( 0, 0) fromView:view];
   printf( "subview from view=%s\n", CGPointUTF8String( point));

   point = [subview convertPoint:CGPointMake( 0, 0) toView:nil];
   printf( "subview to nil=%s\n", CGPointUTF8String( point));

   point = [subview convertPoint:CGPointMake( 0, 0) fromView:nil];
   printf( "subview from nil=%s\n", CGPointUTF8String( point));

   return( 0);
}

