#import <MulleUIWidgets/MulleUIWidgets.h>
#import <MulleImage/MulleImage.h>

#import <string.h>


static BOOL   drawGradient( CGGraphicsLayer *layer, CGContext *context)
{
   CGPaint      *paint;
   CGRect       canvas;
   CGFloat      x, y;

   canvas = [layer canvas];
   // TODO: paint allocation is painful here...

   paint  = [CGPaint paintWithStartColor:CGColorMakeWithHexColor( 0x202020FF)
                               endColor:CGColorMakeWithHexColor( 0xE0E0E0FF)];

   // Replaced mvgFillRectWithPaint with CGContextFillRectWithPaint
   CGContextFillRectWithPaintable( context, canvas, paint);

   // Replaced nvgBeginPath with CGContextBeginPath
   CGContextBeginPath( context);
   for( y = 20; y < canvas.size.height; y += 20)
   {
      // Replaced nvgMoveTo with CGContextMoveTo using CGPointMake
      CGContextMoveTo( context, CGPointMake(CGRectGetMinX( canvas), y));
      // Replaced nvgLineTo with CGContextLineTo using CGPointMake
      CGContextLineTo( context, CGPointMake(CGRectGetMaxX( canvas), y));

      for( x = 20; x < canvas.size.width; x += 20)
      {
         // Replaced nvgMoveTo with CGContextMoveTo using CGPointMake
         CGContextMoveTo( context, CGPointMake(x, CGRectGetMinY( canvas)));
         // Replaced nvgLineTo with CGContextLineTo using CGPointMake
         CGContextLineTo( context, CGPointMake(x, CGRectGetMaxY( canvas)));
      }
   }
   // Replaced nvgStrokeColor with CGContextStrokeColor
   CGContextStrokeColor( context, CGColorMakeLightGray());
   // Replaced nvgStrokeWidth with CGContextStrokeWidth
   CGContextStrokeWidth( context, 1.0);
   // Replaced nvgStroke with CGContextStroke
   CGContextStroke( context);

   return( YES);
}


static void   setupSceneInContentPlane( UIWindowPlane  *contentPlane)
{
   CGRect                frame;
   CGRect                rect;
   NSUInteger            x, y;
   UIEdgeInsets          insets;
   UIScrollContentView   *contentView;
   UIScrollView          *scroller;
   UIView                *subview;

   [contentPlane setPadding:UIEdgeInsetsMake( 20, 20, 20, 20)];

   frame    = [contentPlane contentRect];
   scroller = [UIScrollView viewWithFrame:frame];
   [scroller setBorderColor:CGColorMakeWithHexColor( 0xFF0000FF)];
   [scroller setBorderWidth:2.0];
   [scroller setAutoresizingMask:UIViewAutoresizingScaleToFill];
   [scroller setZoomEnabled:YES];
   [scroller setBackgroundColor:CGColorMakeWithHexColor( 0x33AA33FF)];
   [scroller setPadding:UIEdgeInsetsMake( 20, 20, 20, 20)];

   [scroller setContentSize:CGSizeMake( 1000, 1000)];
   [contentPlane addSubview:scroller];

   contentView = MULLE_OBJC_CLASS_CAST( UIScrollContentView, [scroller contentView]);
   [contentView setBackgroundColor:CGColorMakeWithHexColor( 0x000000FF)];
   [contentView setBorderColor:CGColorMakeWithHexColor( 0xFFFFFFFF)];
   [contentView setBorderWidth:2.0];
   [contentView setDrawCallback:drawGradient];

   insets = UIEdgeInsetsMake( 45, 45, 45, 45);
   for( y = 0; y < 10; y++)
       for( x = 0; x < 10; x++)
       {
          rect = CGRectMake( x * 100.0, y * 100.0 , 100.0, 100.0);
          rect = UIEdgeInsetsInsetRect( rect, insets);
          subview = [UIView viewWithFrame:rect];
          [subview setBackgroundColor:CGColorMakeRandomOpaque()];
          [contentView addSubview:subview];
       }
}



int   main( int argc, char *argv[])
{
   UIWindow           *window;
   UIApplication      *app;

   app = [UIApplication sharedInstance];

   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 640, 400)];
   assert( window);
   [window setBackgroundColor:CGColorMakeWithHexColor( 0x555555FF)];

   setupSceneInContentPlane( [window contentView]);

   [app addWindow:window];

   return( [app runApp]);
}

