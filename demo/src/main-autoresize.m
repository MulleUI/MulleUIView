#import "import-private.h"

#import <string.h>


#define WIN_W   800
#define WIN_H   600

#define COLS  5
#define ROWS  4

#define DISTANCE   20.0

#define W  (((double) WIN_W - (COLS * DISTANCE)) / COLS)
#define H  (((double) WIN_H - (ROWS * DISTANCE)) / ROWS)

#define PADDING  2


// #define PICK_COL  4
// #define PICK_ROW  3


@interface DebugView : UIView
@end


@implementation DebugView

- (void) setFrame:(CGRect) frame
{
   [super setFrame:frame];
}

@end


static BOOL   drawGrid( CALayer *layer, void *_context)
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
      0,
      UIViewAutoresizingScaleToFill,
      UIViewAutoresizingScaleAspectFill,
      UIViewAutoresizingScaleAspectFit,
      UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingScaleToFill,
   },
   {
      UIViewAutoresizingFlexibleWidth,
      UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth,
      UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth,
      UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth,
      UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin
   },
   { 
      UIViewAutoresizingFlexibleHeight, 
      UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleHeight, 
      UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight, 
      UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight, 
      UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin
   },   
   { 
      UIViewAutoresizingTop,
      UIViewAutoresizingLeft,
      UIViewAutoresizingBottom,
      UIViewAutoresizingRight,
      0
   }
};

static NSUInteger   stickyMask[ 9] =
{
   UIViewAutoresizingTopLeft,
   UIViewAutoresizingTop,
   UIViewAutoresizingTopRight,

   UIViewAutoresizingLeft,
   UIViewAutoresizingCenter,
   UIViewAutoresizingRight,

   UIViewAutoresizingBottomLeft,
   UIViewAutoresizingBottom,
   UIViewAutoresizingBottomRight
};



static void   setupViewForRowColumn( UIView *view, int row, int column)
{
   UIView       *subview;
   NSUInteger   i;

   [view setDebugNameUTF8String:"view"];
   [view setBorderWidth:1.0];
   [view setBorderColor:CGColorMakeWithHexColor( 0x606060FF)];
   [view setPadding:UIEdgeInsetsMake( PADDING, PADDING, PADDING, PADDING)];
   [view setDrawCallback:drawGrid];

#define S_X   DISTANCE
#define S_Y   DISTANCE
#define S_W   DISTANCE
#define S_H   DISTANCE

   if( row == 3 && column == 4)
   {
      for( i = 0; i < 9; i++)
      {
         subview = [DebugView viewWithFrame:CGRectMake( S_X, S_Y, S_W, S_H)];
         [subview setDebugNameUTF8String:"subview"];
         [subview setBackgroundColor:CGColorMakeTransparent()];
         [subview setBorderColor:CGColorMakeWithHSL( i / 9.0, 0.7, 0.7)];
         [subview setBorderWidth:2.0];
         [subview setAutoresizingMask:stickyMask[ i]];
         [view addSubview:subview];
      }
   }
   else
      if( row == 3 && column == 3)
      {
         // make room for subviews + padding
         [view setFrame:CGRectMake( 0, 0, S_W + S_W + 2 + 2, S_H + S_H + 2 + 2)];
         [view setDebugNameUTF8String:"parent"];

         subview = [UIView viewWithFrame:CGRectMake( 0, 0, S_W, S_H)];
         [subview setDebugNameUTF8String:"blue"];
         [subview setBackgroundColor:CGColorMakeTransparent()];
         [subview setBorderColor:CGColorMakeWithHexColor( 0xA0A0F0FF)];
         [subview setBorderWidth:2.0];
         [subview setAutoresizingMask:UIViewAutoresizingTopLeft];
         [view addSubview:subview];

         subview = [UIView viewWithFrame:CGRectMake( S_W, 0, S_W, S_H)];
         [subview setDebugNameUTF8String:"red"];
         [subview setBackgroundColor:CGColorMakeTransparent()];
         [subview setBorderColor:CGColorMakeWithHexColor( 0xF0A0A0FF)];
         [subview setBorderWidth:2.0];
         [subview setAutoresizingMask:UIViewAutoresizingTopRight];
         [view addSubview:subview];

         subview = [UIView viewWithFrame:CGRectMake( S_H, S_W, S_W, S_H)];
         [subview setDebugNameUTF8String:"green"];
         [subview setBackgroundColor:CGColorMakeTransparent()];
         [subview setBorderColor:CGColorMakeWithHexColor( 0xA0F0A0FF)];
         [subview setBorderWidth:2.0];
         [subview setAutoresizingMask:UIViewAutoresizingBottomRight];
         [view addSubview:subview];

         subview = [UIView viewWithFrame:CGRectMake( 0, S_W, S_W, S_H)];
         [subview setDebugNameUTF8String:"magenta"];
         [subview setBackgroundColor:CGColorMakeTransparent()];
         [subview setBorderColor:CGColorMakeWithHexColor( 0xF080F0FF)];
         [subview setBorderWidth:2.0];
         [subview setAutoresizingMask:UIViewAutoresizingBottomLeft];
         [view addSubview:subview];
      }
      else
      {
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
#if defined( PICK_COL) && defined( PICK_ROW)
         if( column == PICK_COL && row == PICK_ROW)
#endif
         {
            view = [UIView object];
            setupViewForRowColumn( view, row, column);
            [plane addSubview:view];
         }
      }
   }
}


static void   willLayoutCallback( UIWindow *window,
                                  id <UIGraphicsContext> context,
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
   NSUInteger         i;

   anim        = fmod( frameInfo->now, 3.0) / 3.0;
   plane       = [window contentView];
   contentRect = CGRectInset( [plane contentRect], DISTANCE, DISTANCE);

   distance    = DISTANCE + ((anim < 0.5) ? (anim * H) : (H - anim * H)); 
   CGRectPartitionVertically( contentRect, distance, ROWS, row_frames);
   i = 0;
   for( row = 0; row < ROWS; row++)
   {
      distance = DISTANCE + ((anim < 0.5) ? (anim * W) : (W - anim * W)); 

      CGRectPartitionHorizontally( row_frames[ row], distance, COLS, frames[ row]);
      for( column = 0; column < COLS; column++)
      {
#if defined( PICK_COL) && defined( PICK_ROW)
         if( column == PICK_COL && row == PICK_ROW)
#endif
         {
            frame = CGRectIntegral( frames[ row][ column]);
            view  = [plane subviewAtIndex:i++];
            [view setFrame:frame];
            [view setNeedsLayout];
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
                            styleMask:UIWindowStyleMaskDefault & ~UIWindowStylePanes];
   [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];

   assert( ! [window contentPlane]);
   setupScene( window);

   [window setFrameRateHz:30.0];
   [window setWillLayoutCallback:willLayoutCallback];
   [window dump];

   [app addWindow:window];

   return( [app run]);
}

