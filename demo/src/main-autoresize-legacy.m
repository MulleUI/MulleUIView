#import "import-private.h"

#import <string.h>


#define DEBUG_ROW -1
#define DEBUG_COL -1

#define WIN_W   800
#define WIN_H   600

#define COLS  5
#define ROWS  4

#define DISTANCE   20.0

#define W  (((double) WIN_W - (COLS * DISTANCE)) / COLS)
#define H  (((double) WIN_H - (ROWS * DISTANCE)) / ROWS)

#define PADDING  2


static BOOL   drawGrid( CGGraphicsLayer *layer, CGContext *_context)
{
   CGContext    *context = _context;
   CGRect       canvas;
   CGFloat      xstep, ystep;
   NVGcontext   *vg;
   NSUInteger   x, y;

   canvas = [layer canvas];
   canvas = CGRectInset( canvas, PADDING, PADDING);  // padding

   vg = CGContextGetNVGContext( context);

   nvgBeginPath( vg);

   xstep = DISTANCE;
   ystep = DISTANCE;

   for( y = ystep; y < canvas.size.height; y += ystep)
   {
      nvgMoveTo( vg, 0, y);
      nvgLineTo( vg, canvas.size.width, y);
   }

   for( x = xstep; x < canvas.size.width; x += xstep)
   {
      nvgMoveTo( vg, x, 0);
      nvgLineTo( vg, x, canvas.size.height);
   }

   nvgStrokeWidth( vg, 0.5);
   nvgStrokeColor( vg, [UIColor darkGrayColor]);
   nvgStroke( vg);

   return( YES);
}


static NSUInteger   autoresizingMask[ ROWS][ COLS] =
{
   { 
      UIViewAutoresizingFlexibleLeftMargin
      | UIViewAutoresizingFlexibleTopMargin,

      UIViewAutoresizingFlexibleLeftMargin
      | UIViewAutoresizingFlexibleBottomMargin,

      UIViewAutoresizingFlexibleTopMargin
      | UIViewAutoresizingFlexibleRightMargin,

      UIViewAutoresizingFlexibleTopMargin,

      UIViewAutoresizingFlexibleLeftMargin
      | UIViewAutoresizingFlexibleRightMargin
      | UIViewAutoresizingFlexibleTopMargin
      | UIViewAutoresizingFlexibleBottomMargin
   },
   {
      UIViewAutoresizingFlexibleWidth
      | UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin,

      UIViewAutoresizingFlexibleWidth
      | UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin,

      UIViewAutoresizingFlexibleWidth
      | UIViewAutoresizingFlexibleTopMargin,

      UIViewAutoresizingFlexibleWidth
      | UIViewAutoresizingFlexibleRightMargin,

      UIViewAutoresizingFlexibleWidth
      | UIViewAutoresizingFlexibleLeftMargin
      | UIViewAutoresizingFlexibleRightMargin
      | UIViewAutoresizingFlexibleTopMargin
      | UIViewAutoresizingFlexibleBottomMargin,
   },
   { 
      UIViewAutoresizingFlexibleHeight
      | UIViewAutoresizingFlexibleLeftMargin,

      UIViewAutoresizingFlexibleHeight
      | UIViewAutoresizingFlexibleRightMargin,

      UIViewAutoresizingFlexibleHeight
      | UIViewAutoresizingFlexibleTopMargin,

      UIViewAutoresizingFlexibleHeight
      | UIViewAutoresizingFlexibleBottomMargin,

      UIViewAutoresizingFlexibleHeight
      | UIViewAutoresizingFlexibleLeftMargin
      | UIViewAutoresizingFlexibleRightMargin
      | UIViewAutoresizingFlexibleTopMargin
      | UIViewAutoresizingFlexibleBottomMargin,
   },
   { 
      UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight,
      0,
      0,
      0,
      0
   }
};


static void   setupViewForRowColumn( UIView *view, int row, int column)
{
   UIView       *subview;

   [view setDebugNameUTF8String:"view"];
   [view setBorderWidth:1.0];
   [view setBorderColor:CGColorMakeWithHexColor( 0x606060FF)];
   [view setPadding:UIEdgeInsetsMake( PADDING, PADDING, PADDING, PADDING)];
   [view setDrawCallback:drawGrid];

#define S_X   DISTANCE
#define S_Y   DISTANCE
#define S_W   DISTANCE
#define S_H   DISTANCE

   subview = [UIView viewWithFrame:CGRectMake( S_X, S_Y, S_W, S_H)];
   [subview setDebugNameUTF8String:"blue"];
   [subview setBackgroundColor:CGColorMakeTransparent()];
   [subview setBorderColor:CGColorMakeWithHexColor( 0xA0A0F0FF)];
   [subview setBorderWidth:2.0];
   [subview setAutoresizingMask:autoresizingMask[ row][ column]];
   [view addSubview:subview];

   subview = [UIView viewWithFrame:CGRectMake( S_X, S_Y + S_H, S_W, S_H)];
   [subview setDebugNameUTF8String:"red"];
   [subview setBackgroundColor:CGColorMakeTransparent()];
   [subview setBorderColor:CGColorMakeWithHexColor( 0xF0A0A0FF)];
   [subview setBorderWidth:2.0];
   [subview setAutoresizingMask:autoresizingMask[ row][ column]];
   [view addSubview:subview];
}


static void   willLayoutCallback( UIWindow *window,
                                  struct CGFrameInfo *frameInfo)
{
   UIWindowPlane      *plane;
   CGFloat            distance;
   CGRect             contentRect;
   CGRect             frame;
   CGRect             row_frames[ ROWS];
   CGRect             frames[ ROWS][ COLS];
   NSUInteger         row;
   NSUInteger         column;
   UIView             *view;
   float              anim;

   anim        = fmod( frameInfo->now, 3.0) / 3.0;
   plane       = [window contentView];
   contentRect = CGRectInset( [plane contentRect], DISTANCE, DISTANCE);

   distance    = DISTANCE + ((anim < 0.5) ? (anim * H) : (H - anim * H)); 
   CGRectPartitionVertically( contentRect, distance, ROWS, row_frames);
   for( row = 0; row < ROWS; row++)
   {
      distance = DISTANCE + ((anim < 0.5) ? (anim * W) : (W - anim * W)); 

      CGRectPartitionHorizontally( row_frames[ row], distance, COLS, frames[ row]);
      for( column = 0; column < COLS; column++)
      {
         if( (DEBUG_ROW < 0 || row == DEBUG_ROW) && (DEBUG_COL < 0 || column == DEBUG_COL))
         {
            frame = CGRectIntegral( frames[ row][ column]);
            view  = [plane subviewAtIndex:row * COLS + column];
            [view setFrame:frame];
            [view setNeedsLayout];
         }
      }
   }
}


void   setupScene( UIView *plane)
{
   NSUInteger   row;
   NSUInteger   column;
   UIView       *view;

   for( row = 0; row < ROWS; row++)
   {
      for( column = 0; column < COLS; column++)
      {
         if( (DEBUG_ROW < 0 || row == DEBUG_ROW) && (DEBUG_COL < 0 || column == DEBUG_COL))
         {
            view = [UIView object];
            setupViewForRowColumn( view, row, column);
            [plane addSubview:view];
         }
      }
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

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, WIN_W, WIN_H)
                      titleUTF8String:"Demo"
                            styleMask:UIWindowStyleMaskDefault & ~UIWindowStylePlanes];
   [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];

   setupScene( [window contentView]);

   [window setFrameRateHz:30.0];
   [window setWillLayoutViewsCallback:willLayoutCallback];
   [window dump];

   [app addWindow:window];

   return( [app runApp]);
}

