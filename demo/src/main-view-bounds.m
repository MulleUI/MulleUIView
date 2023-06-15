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
   struct NVGcontext   *vg;
   CGRect              bounds;
   CGFloat             col;
   CGFloat             col_inc;
   CGRect              canvas;

   vg = CGContextGetNVGContext( context);

   canvas = [layer canvas];

   w = (NSUInteger) ceil( canvas.size.width / 20.0);
   h = (NSUInteger) ceil( canvas.size.height / 20.0);

   for( y = 0; y < h; y++)
      for( x = 0; x < w; x++)
      {
         nvgBeginPath( vg);
         nvgRect( vg, x * 20.0, y * 20.0, 20.0, 20.0);
         if( (x ^ y) & 1)
            nvgFillColor( vg, CGColorMakeWithHSL( 0.2 * y / h + 0.8 * x / w, 1.0, 0.8));
         else
            nvgFillColor( vg, CGColorMakeWithHSL( 0.8 * y / h + 0.2 * x / w, 0.8, 0.5));
         nvgFill( vg);
      }
}


// See ![](main-canvas-bounds-frame.png) how it should like.
//
// We draw little rectangles exactly 20x20
// as much as we can fit into the canvas
//
static void   drawCircle( CALayer *layer, CGContext *context)
{
   struct NVGcontext   *vg;
   CGRect              canvas;
   NVGpaint            paint;
   CGFloat             rw;
   CGFloat             rh;
   CGFloat             r;

   vg = CGContextGetNVGContext( context);

   canvas = [layer canvas];

   rw = (canvas.size.width - 2.0) / 2.0;
   rh = (canvas.size.height - 2.0) / 2.0;

   r  = rw > rh ? rh : rw;

   nvgBeginPath( vg);
   nvgEllipse( vg, canvas.size.width / 2.0 + canvas.origin.x,
                   canvas.size.height / 2.0 + canvas.origin.y,
                   rw, rh);

   paint = nvgRadialGradient( vg, rw,
                                  rh,
                                  0.0, r,
                                  CGColorMakeWithHexColor( 0x0000FFFF),
                                  CGColorMakeWithHexColor( 0xFF0000FF));
   nvgFillPaint( vg, paint);
   nvgFill( vg);
}




#define COLS  3
#define ROWS  3


static void   setupViewForRowColumn( UIView *view, int row, int column)
{
   CGRect   bounds;
   UIView   *subview;

   [view setDebugNameUTF8String:"view"];
   [view setDrawCallback:(CALayerDrawCallback_t *) drawStuff];
   [view setBorderWidth:1.0];
   [view setBorderColor:CGColorMakeWithHexColor( 0x00FF00FF)];

   bounds = [view bounds];
   if( row == 1)
   {
      bounds.size.width  *= 2.0;
      bounds.size.height *= 2.0;
   }
   if( row == 2)
   {
      bounds.size.width  *= 0.5;
      bounds.size.height *= 0.5;
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
   [view setBounds:bounds];

   subview = [UIView viewWithFrame:CGRectMake( 20, 20, 40, 40)];
   [subview setDrawCallback:(CALayerDrawCallback_t *) drawCircle];
   [subview setDebugNameUTF8String:"subview"];
   [subview setBackgroundColor:CGColorMakeTransparent()];
   [subview setBorderColor:CGColorMakeWithHexColor( 0xD0D0D0FF)];
   [subview setBorderWidth:1.0];
   [view addSubview:subview];
}


void   setupSceneInContentPlane( UIWindowPlane *plane)
{
   CGRect             contentRect;
   CGRect             bounds;
   CGRect             frame;
   CGRect             row_frames[ ROWS];
   CGRect             frames[ ROWS][ COLS];
   NSUInteger         row;
   NSUInteger         column;
   UIView             *view;
   UIView             *subview;

   contentRect = [plane contentRect];
   contentRect = CGRectInset( contentRect, 20.0, 40.0);

//   contentRect.size.width  = 8 * 20;
//   contentRect.size.height = 8 * 20;
//
//   view  = [UIView viewWithFrame:contentRect];
//   setupViewForRowColumn( view, 2, 0);
//   [plane addSubview:view];
//   return;

   CGRectPartitionVertically( contentRect, 20.0, ROWS, row_frames);

   for( row = 0; row < ROWS; row++)
   {
      CGRectPartitionHorizontally( row_frames[ row], 20.0, COLS, frames[ row]);
      for( column = 0; column < COLS; column++)
      {
         frame = CGRectInset( frames[ row][ column], 5, 5);

         view  = [UIView viewWithFrame:frame];
         setupViewForRowColumn( view, row, column);
         [plane addSubview:view];

         fprintf( stderr, "view %ld.%ld: f=[%s] b=[%s]\n\n",
                     column, row,
                     CGRectUTF8String( [view frame]),
                     CGRectUTF8String( [view bounds]));
      }
   }
}


int   main()
{
   CGContext       *context;
   UIWindow        *window;
   UIApplication   *app;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];
   [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];

   setupSceneInContentPlane( [window contentPlane]);

   [window dump];

   [app addWindow:window];

   return( [app run]);
}

