#import "import-private.h"

#import <string.h>

// See ![](main-canvas-bounds-frame.png) how it should like.
//
// We draw little rectangles exactly 20x20
// as much as we can fit into the canvas
//
static void  drawStuff( CALayer *layer, CGContext *context)
{
   NSUInteger          x;
   NSUInteger          y;
   NSUInteger          w;
   NSUInteger          h;
   CGRect              canvas;
   canvas = [layer canvas];

   w = (NSUInteger) ceil( canvas.size.width / 20.0);
   h = (NSUInteger) ceil( canvas.size.height / 20.0);

   for( y = 0; y < h; y++)
      for( x = 0; x < w; x++)
      {
         CGContextBeginPath( context);
         CGContextRect( context, CGRectMake(x * 20.0, y * 20.0, 20.0, 20.0));
         if( (x ^ y) & 1)
            CGContextFillColor( context, CGColorMakeWithHSL( 0.2 * y / h + 0.8 * x / w, 1.0, 0.8));
         else
            CGContextFillColor( context, CGColorMakeWithHSL( 0.8 * y / h + 0.2 * x / w, 0.8, 0.5));
         CGContextFill( context);
      }
}
// See ![](main-canvas-bounds-frame.png) how it should like.
//
// We draw little rectangles exactly 20x20
// as much as we can fit into the canvas
//
static void   drawCircle( CALayer *layer, CGContext *context)
{
   CGRect              canvas;
   CGPaint            *paint;
   CGFloat             rw;
   CGFloat             rh;
   CGFloat             r;
   canvas = [layer canvas];

   rw = (canvas.size.width - 2.0) / 2.0;
   rh = (canvas.size.height - 2.0) / 2.0;

   r  = rw > rh ? rh : rw;

   CGContextBeginPath( context);
   CGContextEllipse( context, CGPointMake(canvas.size.width / 2.0 + canvas.origin.x, canvas.size.height / 2.0 + canvas.origin.y), rw, rh);

   CGContextSetFillRadialGradient( context,
                                  CACircleMake( rw, rh, r),
                                  CGColorMakeWithHexColor( 0xFF0000FF),
                                  0.0,
                                  CGColorMakeWithHexColor( 0x0000FFFF));
   CGContextFill( context);
}
#define COLS  3
#define ROWS  3
static BOOL   didLayoutGridView( UIView *view)
{
   UIGridView   *gridView = (UIGridView *) view;
   UIView       *subview;
   NSUInteger   row;
   NSUInteger   column;
   CGRect       frame;
   CGRect       bounds;

   for( row = 0; row < ROWS; row++)
      for( column = 0; column < COLS; column++)
      {
         subview = [gridView viewForRow:row
                                 column:column];
         if( ! subview)
            continue;

         frame  = [subview frame];
         bounds = [subview bounds];
         if( row == 1)
         {
            bounds.size.width  = frame.size.width * 2.0;
            bounds.size.height = frame.size.height * 2.0;
         }

         if( row == 2)
         {
            bounds.size.width  = frame.size.width * 0.5;
            bounds.size.height = frame.size.height * 0.5;
         }

         if( column == 1)
         {
            bounds.origin.x     = -10;
            bounds.origin.y     = -10;
         }

         if( column == 2)
         {
            bounds.origin.x     = 10;
            bounds.origin.y     = 10;
         }

         [subview setBounds:bounds];
      }

   return( YES);
}
void   setupSceneInContentView( UIView *contentView)
{
   CGRect       contentRect;
   NSUInteger   row;
   NSUInteger   column;
   UIGridView   *gridView;
   UIView       *view;
   UIView       *subview;

   contentRect = [contentView contentRect];
   contentRect = CGRectInset( contentRect, 20.0, 40.0);

//   contentRect.size.width  = 8 * 20;
//   contentRect.size.height = 8 * 20;
//
//   view  = [UIView viewWithFrame:contentRect];
//   setupViewForRowColumn( view, 2, 0);
//   [contentView addSubview:view];
//   return;

   gridView  = [UIGridView viewWithFrame:contentRect];
   [gridView setRows:ROWS];
   [gridView setColumns:COLS];
   [gridView setSpace:CGSizeMake( 20, 20)];
   [gridView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [contentView addSubview:gridView];
   [gridView setDidLayoutSubviewsCallback:didLayoutGridView];

   for( row = 0; row < ROWS; row++)
      for( column = 0; column < COLS; column++)
      {
         view  = [UIView instance];
         [view setDrawCallback:(CGGraphicsLayerDrawCallback_t *) drawStuff];
         [view setNameUTF8String:"view"];
         [view setBorderWidth:1.0];
         [view setBorderColor:CGColorMakeWithHexColor( 0x00FF00FF)];
         [gridView addSubview:view];

         subview = [UIView viewWithFrame:CGRectMake( 20, 20, 40, 40)];
         [subview setDrawCallback:(CGGraphicsLayerDrawCallback_t *) drawCircle];
         [subview setNameUTF8String:"subview"];
         [subview setBackgroundColor:CGColorMakeTransparent()];
         [subview setBorderColor:CGColorMakeWithHexColor( 0xD0D0D0FF)];
         [subview setBorderWidth:1.0];
         [view addSubview:subview];
      }
}
int   main()
{
   UIWindow        *window;
   UIApplication   *app;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];
   [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];

   setupSceneInContentView( [window contentView]);

   [window dump];

   [app addWindow:window];

   return( [app runApp]);
}

