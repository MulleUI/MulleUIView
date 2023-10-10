//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//
#import "UIAutoresizing.h"

#import "import-private.h"



NS_OPTIONS_TABLE( UIViewAutoresizing, 25) =
{
   NS_OPTIONS_ITEM( UIViewAutoresizingNone),

   NS_OPTIONS_ITEM( UIViewAutoresizingScaleToFill),      // keep above next two
   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleWidth),
   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleHeight),

   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleTopMargin),
   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleBottomMargin),
   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleLeftMargin),
   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleRightMargin),

   NS_OPTIONS_ITEM( UIViewAutoresizingScaleToFill), // keep above next two
   NS_OPTIONS_ITEM( UIViewAutoresizingScaleToFillHorizontal),
   NS_OPTIONS_ITEM( UIViewAutoresizingScaleToFillVertical),
   NS_OPTIONS_ITEM( UIViewAutoresizingScaleAspectFit),
   NS_OPTIONS_ITEM( UIViewAutoresizingScaleAspectFill),

   NS_OPTIONS_ITEM( UIViewAutoresizingCenter), // keep above next two

   NS_OPTIONS_ITEM( UIViewAutoresizingTopLeft), // keep above next two
   NS_OPTIONS_ITEM( UIViewAutoresizingTopRight),
   NS_OPTIONS_ITEM( UIViewAutoresizingBottomLeft),
   NS_OPTIONS_ITEM( UIViewAutoresizingBottomRight),

   NS_OPTIONS_ITEM( UIViewAutoresizingTop),
   NS_OPTIONS_ITEM( UIViewAutoresizingBottom),
   NS_OPTIONS_ITEM( UIViewAutoresizingLeft),
   NS_OPTIONS_ITEM( UIViewAutoresizingRight),

   NS_OPTIONS_ITEM( UIViewAutoresizingClipToBounds),
   NS_OPTIONS_ITEM( UIViewAutoresizingCullAtBounds),
   NS_OPTIONS_ITEM( UIViewAutoresizingIntegralFrame)
};



static char  UIViewAutoresizingUTF8Character( NSUInteger bit)
{
   switch( bit)
   {
   case UIViewAutoresizingNone                  : return( '0');

   case UIViewAutoresizingFlexibleWidth         : return( 'W');
   case UIViewAutoresizingFlexibleHeight        : return( 'H');
   case UIViewAutoresizingFlexibleTopMargin     : return( 'T');
   case UIViewAutoresizingFlexibleBottomMargin  : return( 'B');
   case UIViewAutoresizingFlexibleLeftMargin    : return( 'L');
   case UIViewAutoresizingFlexibleRightMargin   : return( 'R');

   case UIViewAutoresizingScaleToFillHorizontal : return( 'h');
   case UIViewAutoresizingScaleToFillVertical   : return( 'v');
   case UIViewAutoresizingScaleAspectFit        : return( 'f');
   case UIViewAutoresizingScaleAspectFill       : return( 'F');

   case UIViewAutoresizingTop                   : return( 't');
   case UIViewAutoresizingBottom                : return( 'b');
   case UIViewAutoresizingLeft                  : return( 'l');
   case UIViewAutoresizingRight                 : return( 'r');

   case UIViewAutoresizingClipToBounds          : return( 'c');
   case UIViewAutoresizingCullAtBounds          : return( 'C');
   case UIViewAutoresizingIntegralFrame         : return( 'i');
   }
   return( '?');
}


static NSUInteger  UIViewAutoresizingBits[] =
{
   UIViewAutoresizingFlexibleWidth,
   UIViewAutoresizingFlexibleHeight,
   UIViewAutoresizingFlexibleTopMargin,
   UIViewAutoresizingFlexibleBottomMargin,
   UIViewAutoresizingFlexibleLeftMargin,
   UIViewAutoresizingFlexibleRightMargin,

   UIViewAutoresizingScaleToFillHorizontal,
   UIViewAutoresizingScaleToFillVertical,
   UIViewAutoresizingScaleAspectFit,
   UIViewAutoresizingScaleAspectFill,

   UIViewAutoresizingTop,
   UIViewAutoresizingBottom,
   UIViewAutoresizingLeft,
   UIViewAutoresizingRight,

   // user options
   UIViewAutoresizingClipToBounds,
   UIViewAutoresizingCullAtBounds,
   UIViewAutoresizingIntegralFrame
};


char   *UIViewAutoresizingMaskShortUTF8String( NSUInteger bits)
{
   NSUInteger   i;
   char         *s;
   char         c;

   mulle_buffer_do_string( buffer, NULL, s)
   {
      for( i = 0; i < sizeof( UIViewAutoresizingBits) / sizeof( NSUInteger); i++)
      {
         if( bits & UIViewAutoresizingBits[ i])
         {
            c = UIViewAutoresizingUTF8Character( UIViewAutoresizingBits[ i]);
            mulle_buffer_add_byte( buffer, c);
         }
      }
   }

   return( MulleObjCAutoreleaseAllocation( s, NULL));
}


PROTOCOLCLASS_IMPLEMENTATION( UIAutoresizing)


- (CGRect) bounds 
{
   return( CGRectZero);
}


- (UIEdgeInsets) padding 
{
   return( UIEdgeInsetsZero);
}


- (UIEdgeInsets) margins 
{
   return( UIEdgeInsetsZero);
}



#define UIViewLegacyVerticalBits   (UIViewAutoresizingFlexibleHeight         \
                                   | UIViewAutoresizingFlexibleTopMargin     \
                                   | UIViewAutoresizingFlexibleBottomMargin)

#define UIViewLegacyHorizontalBits (UIViewAutoresizingFlexibleWidth          \
                                   | UIViewAutoresizingFlexibleLeftMargin    \
                                   | UIViewAutoresizingFlexibleRightMargin)

static inline CGFloat    autoresizeAmount( CGFloat x, NSUInteger bits)
{
   int   n;

   if( ! bits)
      return( 0.0);

   n = mulle_c_popcountl( bits);
   assert( n);
   return( x / n);
}


- (CGRect) legacyFrameWithBounds:(CGRect) bounds
                autoresizingMask:(UIViewAutoresizing) autoresizingMask
{
   CGSize   change;
   CGSize   sizeChange;
   CGRect   frame;
   CGRect   originalFrame;
   CGRect   lastBounds;

   assert( autoresizingMask);

   //
   // originalFrame will copy _frame if needed, if its zero, we just recopy
   // frame again, until valid. The reason for "originalFrame" is, that we
   // want to a compose a UI with some absolute frame values and then be able
   // to resize it (usually with the window resize or maybe a device geometry
   // change (mobile phone)). But resizes may accumulate errors, so instead
   // of using incremental changes, we calculate from the "original frame" the
   // size change to the desired size. The problem is, that its hard to
   // discern between "intentional" resizes due to direct user interaction and
   // "forced" resizes due to window changes. Currently the -setNeedsLayout
   // method is abused to clear _originalFrame and _originalBounds, thus
   // marking an "intentional" frame change.
   //
   originalFrame = [self originalFrame];
   if( originalFrame.size.width == 0.0)
   {
      originalFrame  = [self frame];
      [self setOriginalFrame:originalFrame];
      [self setLastBounds:bounds];

#ifdef LEGACY_DEBUG
      MulleUILog( "originalFrame change to: %s", CGRectUTF8String( _originalFrame));
#endif
   }
   lastBounds = [self lastBounds];

//   if( sizeChange.width < 0.5 && sizeChange.height < 0.5)
//      return( _originalFrame);

   // adjust top left point (but don't increase size)
   frame             = originalFrame;

   change.width      = CGRectGetWidth( bounds) - CGRectGetWidth( lastBounds);
   change.height     = CGRectGetHeight( bounds) - CGRectGetHeight( lastBounds);

   // can remove this if we divide in the switches
   sizeChange.width  = autoresizeAmount( change.width, autoresizingMask & UIViewLegacyHorizontalBits);
   sizeChange.height = autoresizeAmount( change.height, autoresizingMask & UIViewLegacyVerticalBits);

#ifdef LEGACY_DEBUG
   MulleUILog( "change: %s sizeChange: %s",
                  CGSizeUTF8String( change),
                  CGSizeUTF8String( sizeChange));
#endif

   if( autoresizingMask & UIViewAutoresizingFlexibleLeftMargin)
      frame.origin.x += sizeChange.width;
   if( autoresizingMask & UIViewAutoresizingFlexibleWidth)
      frame.size.width += sizeChange.width;

   if( autoresizingMask & UIViewAutoresizingFlexibleTopMargin)
      frame.origin.y += sizeChange.height;
   if( autoresizingMask & UIViewAutoresizingFlexibleHeight)
      frame.size.height += sizeChange.height;


#ifdef LEGACY_DEBUG
   MulleUILog( "frame: %s -> %s", CGRectUTF8String( originalFrame), CGRectUTF8String( frame));
#endif
   return( frame);
}


//
// we get layoutRect as rect, which includes "padding"
//
- (CGRect) autoresizedFrameOfObject:(id <UIAutoresizing>) obj
                             inRect:(CGRect) rect
                   autoresizingMask:(UIViewAutoresizing) autoresizingMask
{
   CGRect          bounds;
   CGRect          frame;
   CGRect          marginedRect;
   NSUInteger      contentModeBits;
   NSUInteger      legacyBits;
   CGContentMode   contentMode;
   UIEdgeInsets    padding;
   UIEdgeInsets    margins;
   UIEdgeInsets    edges;

   assert( autoresizingMask);

   legacyBits      = autoresizingMask & UIViewAutoresizingLegacyBits;
   contentModeBits = autoresizingMask & UIViewAutoresizingContentModeBits;

   padding         = [self padding];

   if( legacyBits)
   {
      // we can use "bounds" here, because we just care for the size
      bounds        = [self bounds];
      bounds        = UIEdgeInsetsInsetRect( bounds, padding);

      // like resizeWithOldSuperviewSize:
      frame         = [obj legacyFrameWithBounds:bounds
                                autoresizingMask:autoresizingMask];
   }
   else
      frame         = [obj frame];

   if( contentModeBits)
   {
      margins       = [obj margins];
      edges.top     = CGFloatMaximum( padding.top, margins.top);
      edges.left    = CGFloatMaximum( padding.left, margins.left);
      edges.bottom  = CGFloatMaximum( padding.bottom, margins.bottom);
      edges.right   = CGFloatMaximum( padding.right, margins.right);
      marginedRect  = UIEdgeInsetsInsetRect( rect, edges);

      contentMode   = UIViewAutoresizingGetContentMode( autoresizingMask);
      frame         = CGRectPlaceInRect( frame, marginedRect, contentMode);
   }

   //
   // if obj doesn't fit into rect, we do what ?
   // culling is done in the renderQueue step (if clipping is set)
   // If clipping is not set UIViewAutoresizingCullAtBounds will be useful
   // as well
   //
   if( frame.size.width < 0.5)
      frame.size.width = 0.0;
   if( frame.size.height < 0.5)
      frame.size.height = 0.0;

   // use rect here I guess
   if( ! CGRectContainsRect( rect, frame))
   {
      if( autoresizingMask & UIViewAutoresizingCullAtBounds)
         frame.size = CGSizeZero;
      if( autoresizingMask & UIViewAutoresizingClipToBounds)
         frame = CGRectIntersection( rect, frame);
   }
   return( frame);
}


PROTOCOLCLASS_END();
