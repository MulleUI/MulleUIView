#import <MulleUIView/MulleUIView.h>


int   main( void)
{
   UIView   *view;

   view = [UIView viewWithFrame:CGRectMake( 32, 32, 64, 64)];
   if( ! view)
   {
      fprintf( stderr, "viewWithFrame: failed\n");
      exit( 1);
   }

   return( 0);
}

