//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//
#import "UIAutoresizing.h"

#import "import-private.h"


#ifdef DEBUG
//# define LEGACY_DEBUG
#endif

MULLE_UI_VIEW_GLOBAL_VAR
NS_OPTIONS_TABLE( UIViewAutoresizing, 25) =
{
   NS_OPTIONS_ITEM( UIViewAutoresizingNone),

   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleSize),  // keep above next two
   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleWidth),
   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleHeight),

   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleTopMargin),
   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleBottomMargin),
   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleLeftMargin),
   NS_OPTIONS_ITEM( UIViewAutoresizingFlexibleRightMargin),

   NS_OPTIONS_ITEM( UIViewAutoresizingScaleToFill), // keep above next four
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


//
// bounds is actually contentRect - padding. contentRect is zero, bounds.size
//
CGRect   UIAutoresizingLegacyResize( CGRect originalFrame,
                                     CGRect lastBounds,
                                     CGRect bounds,
                                     UIViewAutoresizing autoresizingMask)
{
   CGSize   change;
   CGSize   sizeChange;
   CGRect   frame;

   assert( autoresizingMask);

   frame             = originalFrame;

   change.width      = CGRectGetWidth( bounds) - CGRectGetWidth( lastBounds);
   change.height     = CGRectGetHeight( bounds) - CGRectGetHeight( lastBounds);

   // can remove this if we divide in the switches
   sizeChange.width  = autoresizeAmount( change.width, autoresizingMask & UIViewLegacyHorizontalBits);
   sizeChange.height = autoresizeAmount( change.height, autoresizingMask & UIViewLegacyVerticalBits);

#ifdef LEGACY_DEBUG
   MulleUICLog( "change: %s sizeChange: %s",
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

   return( frame);
}


//
// We get contentRect as rect, which does not include "padding"
// contentRect is { { 0, 0 }, bounds.size }
//
- (CGRect) autoresizeWithLayoutInfo:(struct UILayoutInfo *) info
                   autoresizingMask:(UIViewAutoresizing) autoresizingMask
{
   CGContentMode   contentMode;
   CGRect          frame;
   CGRect          lastBounds;
   CGRect          marginedRect;
   CGRect          originalFrame;
   NSUInteger      contentModeBits;
   NSUInteger      legacyBits;
   UIEdgeInsets    edges;
   UIEdgeInsets    margins;

   legacyBits      = autoresizingMask & UIViewAutoresizingLegacyBits;
   contentModeBits = autoresizingMask & UIViewAutoresizingContentModeBits;

#ifdef LEGACY_DEBUG
   MulleUICLog( "%#@ legacy: 0x%tx contentMode: 0x%tx %s (%s)",
                self,
                legacyBits,
                contentModeBits,
                CGRectUTF8String( [self frame]),
                CGRectUTF8String( [self originalFrame]));
#endif


   //
   // in mixed mode, the initial positioning is done by the contentModeBits
   // but resizes are only performed with legacy resizing, since then
   // originalFrame is used and the modified "contentMode" frame is ignored
   //
   if( ! (autoresizingMask & UIViewAutoresizingMixedMode))
   {
      if( legacyBits && contentModeBits)
      {
         fprintf( stderr, "Do not mix legacy autoresizing and contentMode autoresizing\n");
         abort();
      }
   }


   margins      = [self margins];
   edges.top    = CGFloatMaximum( info->padding.top, margins.top);
   edges.left   = CGFloatMaximum( info->padding.left, margins.left);
   edges.bottom = CGFloatMaximum( info->padding.bottom, margins.bottom);
   edges.right  = CGFloatMaximum( info->padding.right, margins.right);
   marginedRect = UIEdgeInsetsInsetRect( info->rect, edges);

   frame        = [self frame];

   //
   // TODO: could use marginedRect for legacyBounds ?
   //
   if( contentModeBits)
   {
      contentMode  = UIViewAutoresizingGetContentMode( autoresizingMask);
      frame        = CGRectPlaceInRect( frame, marginedRect, contentMode);
   }

   if( legacyBits)
   {
      //
      // originalFrame will copy frame if needed, if its zero, we just recopy
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
      // use "contentRect" really

      originalFrame = [self originalFrame];
      if( originalFrame.size.width == 0.0)
      {
         originalFrame  = frame;
         lastBounds     = marginedRect;
         //
         // if the original frame had zero components, it will want to stretch out
         // most likely, we can't have the lastBounds hampering this. If this turns
         // out to be a problem in the long run: rethink when do set lastBounds.
         // probably this part of the code shouldn't run yet at all
         //
         if( originalFrame.size.width == 0.0)
            lastBounds.size.width = 0.0;
         if( originalFrame.size.height == 0.0)
            lastBounds.size.height = 0.0;

         [self setOriginalFrame:originalFrame];
         [self setLastBounds:lastBounds];

#ifdef LEGACY_DEBUG
         MulleUILog( "%#@ -originalFrame change to: %s", self, CGRectUTF8String( originalFrame));
#endif
      }
      else
      {
         lastBounds = [self lastBounds];

         // like resizeWithOldSuperviewSize:
         frame      = UIAutoresizingLegacyResize( originalFrame,
                                                  lastBounds,
                                                  marginedRect,
                                                  autoresizingMask);
      }
   }

   //
   // if self doesn't fit into rect, we do what ?
   // culling is done in the drawingQueue step (if clipping is set)
   // If clipping is not set UIViewAutoresizingCullAtBounds will be useful
   // as well
   //
   if( frame.size.width < 0.5)
      frame.size.width = 0.0;
   if( frame.size.height < 0.5)
      frame.size.height = 0.0;

   // use rect here I guess
   if( ! CGRectContainsRect( info->rect, frame))
   {
      if( autoresizingMask & UIViewAutoresizingCullAtBounds)
         frame.size = CGSizeZero;
      if( autoresizingMask & UIViewAutoresizingClipToBounds)
         frame = CGRectIntersection( info->rect, frame);
   }

#ifdef LEGACY_DEBUG
   MulleUICLog( "%#@ frame: -> %s (%s)",
                self,
                CGRectUTF8String( frame),
                CGRectUTF8String( [self originalFrame]));
#endif
   return( frame);
}


PROTOCOLCLASS_END();
