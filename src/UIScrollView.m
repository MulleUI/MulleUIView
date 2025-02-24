#import "UIScrollView.h"

#import "MulleScrollIndicatorView.h"

#import "UIView+DebugPrivate.h"
#import "UIView+Layout.h"


// #define LAYOUT_DEBUG
// #define EVENT_DEBUG
// #define MOMENTUM_DEBUG
// #define SETUP_DEBUG


@implementation UIScrollView


+ (Class) scrollContentViewClass
{
   return( [UIScrollContentView class]);
}


+ (Class) scrollIndicatorViewClass
{
   return( [MulleScrollIndicatorView class]);
}


- (void) setupSubviewsInRect:(CGRect) rect
{
   Class   viewClass;

   if( _contentView)
      return;

   // contentView draws below indicator views, therefore it is first added
   // to the scrollView. drawback: gets events first, taking them away from
   // the indicator views.
   //
   viewClass    = [[self class] scrollContentViewClass];
   _contentView = [viewClass viewWithFrame:rect];
   [_contentView setDebugNameUTF8String:"ScrollViewContentView"];
   [_contentView setClipsToBounds:YES];
   [self addSubview:_contentView];

   assert( ! _horIndicatorView);
   // hide, and show after relayout
   viewClass         = [[self class] scrollIndicatorViewClass];
   _horIndicatorView = [viewClass object];
   [_horIndicatorView setDebugNameUTF8String:"HoriziontalIndicatorView"];
   [self addSubview:_horIndicatorView];

   assert( ! _verIndicatorView);

   _verIndicatorView = [viewClass object];
   [_verIndicatorView setDebugNameUTF8String:"VerticalIndicatorView"];
   [self addSubview:_verIndicatorView];
}


- (id) initWithLayer:(id <UILayer>) layer
               frame:(CGRect) frame
{
   CGRect   rect;

   self = [super initWithLayer:layer
                         frame:frame];

   _showsHorizontalScrollIndicator = YES;
   _showsVerticalScrollIndicator   = YES;

   rect.origin = CGPointZero;
   rect.size   = frame.size;

   _appearance = (struct UIScrollViewAppearance)
   {
      .scrollerWidth          = 8,
      .scrollerOffsetStart    = 8,
      .scrollerOffsetEnd      = (8 + 8 * 1.5), // .scrollerWidth + .scrollerOffsetStart * 1.5
      .scrollerOffsetEndAlone = 8             // .scrollerWidth
   };

   [self setupSubviewsInRect:rect];

   return( self);
}


// remove as window delegate via setMomentum...
- (void) finalize
{
   [self setMomentum:CGPointZero
           timestamp:0];
   [super finalize];
}


- (CGPoint) zoomFactor
{
   CGRect   contentBounds;
   CGSize   contentSize;
   CGPoint  zoomFactor;

   if( ! _zoomEnabled)
      return( CGPointMake( 1.0, 1.0));

   contentBounds = [_contentView bounds];

   if( contentBounds.size.width <= 0.1 || contentBounds.size.height <= 0.1)
      return( CGPointMake( 0.0, 0.0));

   // the current scroll factor
   contentSize  = [_contentView contentSize];

   zoomFactor.x = contentSize.width / contentBounds.size.width;
   zoomFactor.y = contentSize.height / contentBounds.size.height;

   return( zoomFactor);
}


//
// implicitly resets the zoom back to 1.0 and sets the bounds
// if this is not desired, get old zoomFactor and reset afterwards
//
- (void) setContentSize:(CGSize) size
{
   [_contentView setContentSize:size];
}

// passed to contentView
- (void) setContentOffset:(CGPoint) offset
{
   [_contentView setContentOffset:offset];
   [_delegate scrollViewDidScroll:self];
}


- (void) scrollContentOffsetBy:(CGPoint) diff
{
   [_contentView scrollContentOffsetBy:diff];
   [_delegate scrollViewDidScroll:self];
}


- (CGPoint) contentOffset
{
   return( [_contentView contentOffset]);
}


- (CGSize) contentSize
{
   return( [_contentView contentSize]);
}


- (UIView <UIScrollContent> *) contentView  // subview index #0
{
   return( _contentView);
}


- (UIView *) horizontalScrollIndicatorView  // subview index #n - 2
{
   return( _horIndicatorView);
}


- (UIView *) verticalScrollIndicatorView    // subview index #n - 1
{
   return( _verIndicatorView);
}


#define HZ60         (1.0/60.0)
#define DRAGFACTOR   0.95

- (BOOL) setMomentum:(CGPoint) momentum
           timestamp:(mulle_absolutetime_t) timestamp
{
   BOOL   hadMomentum;
   BOOL   haveMomentum;

   hadMomentum  = _momentum.x != 0.0 || _momentum.y != 0.0;
   haveMomentum = momentum.x != 0.0 || momentum.y != 0.0;

#ifdef MOMENTUM_DEBUG
   fprintf( stderr, "momentum (%s) %s -> (%s) %s\n",
                        CGPointUTF8String( _momentum),
                        hadMomentum ? "YES" : "NO",
                        CGPointUTF8String( momentum),
                        haveMomentum ? "YES" : "NO");
#endif

   _momentum          = momentum;
   _momentumTimestamp = timestamp;
   if( ! haveMomentum)
   {
      if( hadMomentum)
         [[self window] removeFromRenderDelegates:self];
      [self updateIndicatorViewValues]; // one more time
   }
   else
      if( ! hadMomentum)
         [[self window] addToRenderDelegates:self];

   return( haveMomentum);
}


- (BOOL) applyMomentumToContentWithAbsoluteTime:(mulle_absolutetime_t) now
{
   CGPoint                offset;
   CGPoint                newOffset;
   CGPoint                momentum;
   mulle_relativetime_t   diff;
   CGFloat                friction;
   BOOL                   haveMomentum;

   diff = mulle_timeinterval_subtract( now, _momentumTimestamp);

   // 1/60 = 0.166  so if our last render was 0.0s before, we use 1.0
   //                  if the last render was 0.166s before,we use 0.95
   //                  interpolate other numbers

   // diff is 0        : friction is 1
   // diff is 0.5/60.0 : friction is (1-0.95) * diff + 0.95
   // diff is 1.0/60.0 : friction is 0.95
   // diff is 2.0/60.0 : friction is (1-0.95) * diff + 0.95

   diff     = diff / HZ60;
   friction = 1 - (1 - DRAGFACTOR) * diff;

   momentum.x = _momentum.x * friction;
   momentum.y = _momentum.y * friction;
   if( fabs( momentum.x) < 0.01)
      momentum.x = 0.0;
   if( fabs( momentum.y) < 0.01)
      momentum.y = 0.0;

#ifdef MOMENTUM_DEBUG
   if( momentum.x != 0.0 || momentum.y != 0.0)
      fprintf( stderr, "momentum: %.2f,%.2f [d:%.4f f:%.4f] @%.4f\n",
                                    momentum.x, momentum.y,
                                    diff, friction,
                                    mulle_absolutetime_now());
#endif

   haveMomentum = [self setMomentum:momentum
                          timestamp:now];
   if( haveMomentum)
   {
      offset      = [_contentView contentOffset];
      newOffset.x = offset.x + momentum.x;
      newOffset.y = offset.y + momentum.y;

      offset = [_contentView clampedContentOffset:newOffset];
      [_contentView setContentOffset:offset];
   }
   return( haveMomentum);
}


- (UIWindowDisplayBits) willRenderWithAbsoluteTime:(mulle_absolutetime_t) now
{
   UIViewLog( "%.5f", now);

   // MEMO: setupIndicatorViews needs to run also, when ContentOffset has
   //       changed or ContentSize has changes, but
   //       applyMomentumToContentWithAbsoluteTime doesn't really know about
   //       this.
   [self applyMomentumToContentWithAbsoluteTime:now];
   //[self setupIndicatorViews];

   return( UIWindowDisplayNeedsLayout);
}


// TODO: rename
- (BOOL) updateIndicatorViewValues
{
   CGPoint   contentOffset;
   CGSize    contentSize;
   CGRect    bounds;
   BOOL      wasHiddenH;
   BOOL      wasHiddenV;
   BOOL      isHiddenH;
   BOOL      isHiddenV;

   // TODO: this should be the frameInfo now!
   contentSize   = [_contentView contentSize];
   contentOffset = [_contentView contentOffset];
   bounds        = [_contentView bounds];

#ifdef SETUP_DEBUG
   MulleUILog( "bubbleOffset.x: %.2f bubbleLength.width: %.2f contentLength: %.2f",
               contentOffset.x, bounds.size.width, contentSize.width);
#endif

   [_horIndicatorView setBubbleOffset:contentOffset.x];
   [_horIndicatorView setBubbleLength:bounds.size.width];
   [_horIndicatorView setContentLength:contentSize.width];
   //
   // don't paint scrollbar if content fits inside scrollView
   //
   wasHiddenH = [_horIndicatorView isHidden];
   isHiddenH = ! _showsHorizontalScrollIndicator;
   if( bounds.size.width >= contentSize.width)
      isHiddenH = YES;
   [_horIndicatorView setHidden:isHiddenH];

   [_verIndicatorView setBubbleOffset:contentOffset.y];
   [_verIndicatorView setBubbleLength:bounds.size.height];
   [_verIndicatorView setContentLength:contentSize.height];

   wasHiddenV = [_verIndicatorView isHidden];
   isHiddenV  = ! _showsVerticalScrollIndicator;
   if( bounds.size.height >= contentSize.height)
      isHiddenV = YES;
   [_verIndicatorView setHidden:isHiddenV];

   if( isHiddenH ^ wasHiddenH || isHiddenV ^ wasHiddenV)
      return(YES);
   return( NO);
}


// TODO: if there is only a vertical indicator, enlarge it so that it takes
//       up empty space otherwise used by the horizontal indicator
- (void) layoutKnownSubviews
{
   CGRect         rect;
   CGRect         horFrame;
   CGRect         verFrame;
   CGRect         contentFrame;
   UIEdgeInsets   insets;
   CGFloat        end;
   CGRect         contentRect;
   UIEdgeInsets   padding;

   contentRect = [self contentRect];
   padding     = [self padding];
   rect = UIEdgeInsetsInsetRect( contentRect, padding);

#ifdef LAYOUT_DEBUG
   MulleUILog( "layout rect: %s", CGRectUTF8String( rect));
#endif

//
// determined solely by contentSize/offset and own bounds
// putting margins on the contentView is not a good thing though
//
   contentFrame = UIEdgeInsetsInsetRect( rect, _contentInsets);
   [_contentView setFrame:contentFrame];

   end = _appearance.scrollerOffsetEnd;
   if( [_horIndicatorView isHidden] || [_verIndicatorView isHidden])
      end = _appearance.scrollerOffsetEndAlone;

   // currently these scrollers are 8 pixel wide and 4 pixels offset
   // the 6.0 is so that scrollers don't overlap if both are visible
   insets   = UIEdgeInsetsMake( 0.0, _appearance.scrollerOffsetStart, _appearance.scrollerOffsetStart, end);
   horFrame = UIEdgeInsetsInsetRect( contentFrame, insets);

   horFrame.origin.y    = horFrame.size.height + horFrame.origin.y - _appearance.scrollerWidth;
   horFrame.size.height = _appearance.scrollerWidth;

#ifdef LAYOUT_DEBUG
   fprintf( stderr, "%s %s rect: %s\n",
                  __PRETTY_FUNCTION__,
                  [_horIndicatorView UTF8String],
                  CGRectUTF8String( horFrame));
#endif
   [_horIndicatorView setFrame:horFrame];

   insets   = UIEdgeInsetsMake( _appearance.scrollerOffsetStart, 0.0, end, _appearance.scrollerOffsetStart);
   verFrame = UIEdgeInsetsInsetRect( contentFrame, insets);

   verFrame.origin.x   = verFrame.size.width + verFrame.origin.x - _appearance.scrollerWidth;
   verFrame.size.width = _appearance.scrollerWidth;

#ifdef LAYOUT_DEBUG
   fprintf( stderr, "%s %s rect: %s\n",
                  __PRETTY_FUNCTION__,
                  [_verIndicatorView UTF8String],
                  CGRectUTF8String( verFrame));
#endif
   [_verIndicatorView setFrame:verFrame];
}


- (BOOL) layoutSubviews
{
   UIView   *view;
   CGRect   bounds;
   BOOL     flag;

   if( (*_willLayoutSubviewsCallback)( self))
   {
      // TODO: could "cull" subviews here, that, after layout, are not
      //       visible.. is this beneficial ?
      //
      [self layoutKnownSubviews];

      bounds = [self contentRect];
      UIViewSubviewsFor( self, view)
      {
         if( view == _contentView || view == _horIndicatorView || view == _verIndicatorView)
            continue;

         [self layoutSubview:view
                      inRect:bounds
            autoresizingMask:[view autoresizingMask]];
      }
   }
   flag = (*_didLayoutSubviewsCallback)( self);
   return( flag);
}


- (void) layout
{
   [super layout];
   [self updateIndicatorViewValues];
}


- (void) scrollRectToVisible:(CGRect) rect
                    animated:(BOOL) animated
{
}


#if 0
- (void) dumpWithIndent:(NSUInteger) indent
                   FILE:(FILE *) fp
{
   [super dumpWithIndent:indent
                    FILE:fp];

   [_contentView dumpWithIndent:indent + 3
                           FILE:fp];
}
#endif

@end



PROTOCOLCLASS_IMPLEMENTATION( UIScrollContent)

- (CGRect) contentRect
{
   CGSize    contentSize;

   contentSize = [self contentSize];
   return( CGRectMake( 0.0f, 0.0f, contentSize.width, contentSize.height));
}


- (CGPoint) clampedContentOffset:(CGPoint) offset
{
   CGPoint   newOffset;
   CGSize    size;
   CGRect    bounds;
   CGSize    contentSize;

   bounds      = [self bounds];
   // this ensures that everything is visible...
   contentSize = [self contentSize];
   size        = CGSizeMake( contentSize.width - bounds.size.width,
                             contentSize.height - bounds.size.height);
                         
   newOffset = CGPointClampToSize( offset, size);
   return( newOffset);
}


- (void) scrollContentOffsetBy:(CGPoint) diff
{
   CGPoint   offset;
   CGPoint   newOffset;

   offset      = [self contentOffset];
   newOffset.x = offset.x + diff.x;
   newOffset.y = offset.y + diff.y;
   offset      = [self clampedContentOffset:newOffset];
   [self setContentOffset:offset];
}


- (CGRect) clampedBounds:(CGRect) bounds
{
   CGRect       frame;
   CGRect       oldBounds;
   CGRect       clampedBounds;
   CGPoint      zoomFactor;
   CGPoint      minZoom;
   CGSize       contentSize;
   CGFloat      aspect;
   CGFloat      propose;
   NSUInteger   bits;

   oldBounds = [self bounds];
   if( bounds.size.width <= 1.0 || bounds.size.height <= 1.0)
      return( oldBounds);

   contentSize = [self contentSize];
   if( contentSize.width <= 1.0 || contentSize.height <= 1.0)
      return( oldBounds);

   frame        = [self frame];

   zoomFactor.x = frame.size.width / bounds.size.width;
   zoomFactor.y = frame.size.height / bounds.size.height;

   minZoom.x    = frame.size.width / contentSize.width;
   minZoom.y    = frame.size.height / contentSize.height;


#ifdef DEBUG
   fprintf( stderr, "zoomFactor: %s\n", CGPointUTF8String( zoomFactor));
   fprintf( stderr, "minZoom: %s\n", CGPointUTF8String( minZoom));
#endif

   bits  = zoomFactor.x < minZoom.x ? 1 : 0;
   bits |= zoomFactor.y < minZoom.y ? 2 : 0;
   if( ! bits)
      return( bounds);

   if( [self clampsConservatively])
      return( oldBounds);

   if( bits < 3)
      return( bounds);

   aspect               = CGRectGetAspectRatio( bounds);
   clampedBounds.origin = bounds.origin;

   // both axis too close, scale to better fit, keeping aspect ratio
   propose = contentSize.height * aspect;
   if( propose < contentSize.width)
   {
      clampedBounds.size.width  = contentSize.width;
      clampedBounds.size.height = contentSize.width / aspect;
   }
   else
   {
      clampedBounds.size.width  = contentSize.height * aspect;
      clampedBounds.size.height = contentSize.height;
   }
   return( clampedBounds);
}


#if 0
      if( bounds.size.width <= contentSize.width)
      {
         bounds.size.height = oldBounds.size.height / oldBounds.size.width * bounds.size.width;
      }
      else
      {
         bounds.size.height  = minZoom.y * contentSize.height;
         bounds.size.width   = oldBounds.size.width / oldBounds.size.height * bounds.size.width;
      }
      return( bounds);
   }

   // x is too zoomed out
   if( bits == 1) // x 
   {
      if( oldBounds.size.width == 0.0)
         return( oldBounds);

      bounds.size.width  = minZoom.x * contentSize.width;
      bounds.size.height = oldBounds.size.height / oldBounds.size.width * bounds.size.width;

      return( bounds);
   }

   if( oldBounds.size.height == 0.0)
      return( oldBounds);

   bounds.size.height  = minZoom.y * contentSize.height;
   bounds.size.width   = oldBounds.size.width / oldBounds.size.height * bounds.size.height;
   return( bounds);
#endif


//
// point is within { { 0, 0}, contentSize }
//
- (void) centerOnPoint:(CGPoint) point
{
   CGPoint   contentOffset;
   CGRect    bounds;

   bounds          = [self bounds];

   // center mouse in the middle of the screen
   contentOffset.x = point.x - bounds.size.width / 2.0;
   contentOffset.y = point.y - bounds.size.height / 2.0;

   contentOffset = [self clampedContentOffset:contentOffset];
   [self setContentOffset:contentOffset];
}

PROTOCOLCLASS_END()



@implementation UIScrollContentView 

- (instancetype) initWithLayer:(id <UILayer>) layer
                         frame:(CGRect) frame
{
   [super initWithLayer:layer
                  frame:frame];

   _contentSize = frame.size;
   
   return( self);
}


- (void) layoutLayer:(id <UILayer>) layer
              inRect:(CGRect) rect
{
   // fprintf( stderr, "layout...\n");
   if( layer == _mainLayer)
   {
      [layer setFrame:rect];
      // [layer setBounds:[self bounds]];
   }
}


- (CGPoint) contentOffset
{
//   CGPoint   offset;
//
//   offset    = _bounds.origin;
//   offset.x *= -1.0;
//   offset.y *= -1.0;
   return( [self bounds].origin);
}


- (void) setContentOffset:(CGPoint) offset
{
//   id<UILayer>   layer;
//   CGRect        layerBounds;
   CGRect   bounds;

   bounds = [self bounds];
   bounds.origin = offset;
   [self setBounds:bounds];

//   layer              = [self layer];
//   layerBounds        = [layer bounds];
//   layerBounds.origin = offset;
//   [layer setBounds:layerBounds];
//
//   [[self layer] setBounds:[self bounds]];

//   _bounds.origin.x = offset.x * -1.0;
//   _bounds.origin.y = offset.y * -1.0;
//   [[self superview] setNeedsLayout];
}

@end 
