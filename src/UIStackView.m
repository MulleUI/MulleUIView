//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "UIStackView.h"

#import "import-private.h"


struct UIStackViewLayoutContext
{
   CGRectU              layoutRect;
   NSUInteger           n_views;
   UIViewAutoresizing   defaultMask;
};


@implementation UIStackView

- (instancetype) initWithLayer:(id <UILayer>) layer
                         frame:(CGRect) frame
{
   self = [super initWithLayer:layer
                         frame:frame];
   if( self)
   {
      _axisIndex               = UILayoutConstraintAxisVerticalIndex;
      _minimumInteritemSpacing = 10.0;
      _minimumLineSpacing      = 10.0;
   }
   return( self);
}


- (void) setSubviewLayoutSizeIfNeeded
 {
   CGSize   size;
   CGRect   rect;
   UIView   *view;

   UIViewSubviewsFor( self, view)
   {
      size = [view mulleLayoutSize];
      if( ! CGSizeEqualToSize( size, CGSizeZero))
         continue;

      rect = MulleEdgeInsetsExtrudeRect( [view margins], [view frame]);
      [view mulleSetLayoutSize:rect.size];
   }
}


- (BOOL) setupLayoutContext:(struct UIStackViewLayoutContext *) ctxt
{
   [self setSubviewLayoutSizeIfNeeded];

   ctxt->n_views = mulle_pointerarray_get_count( &_subviews);
   if( ctxt->n_views == 0)
      return( NO);

   // calculate area, where we can layout
   ctxt->layoutRect = CGRectAsRectU( UIEdgeInsetsInsetRect( [self contentRect], [self padding]));

   switch( _alignment)
   {
   case UIStackViewAlignmentTop      : ctxt->defaultMask = UIViewAutoresizingTop; break;
   case UIStackViewAlignmentBottom   : ctxt->defaultMask = UIViewAutoresizingBottom; break;
   case UIStackViewAlignmentLeading  : ctxt->defaultMask = UIViewAutoresizingLeft; break;
   case UIStackViewAlignmentTrailing : ctxt->defaultMask = UIViewAutoresizingRight; break;
   default                           : ctxt->defaultMask = UIViewAutoresizingTop
                                                           | UIViewAutoresizingBottom
                                                           | UIViewAutoresizingLeft
                                                           | UIViewAutoresizingRight; break;
   }

//   if( self->_axisIndex == UILayoutConstraintAxisHorizontalIndex)
//   {
//      if( ! (ctxt->defaultMask & (UIViewAutoresizingLeft|UIViewAutoresizingRight)))
//         ctxt->defaultMask |= UIViewAutoresizingLeft;
//   }
//   else
//   {
//      if( ! (ctxt->defaultMask & (UIViewAutoresizingTop|UIViewAutoresizingBottom)))
//         ctxt->defaultMask |= UIViewAutoresizingTop;
//   }

   return( YES);
}


- (CGSize) areaCoveredByStackingSubviews
 {
   CGSizeU   size;
   CGSizeU   area;
   UIView    *view;
   int       axis;
   int       otherAxis;
   CGFloat   spacing;

   area      = CGSizeUZero;
   axis      = _axisIndex;
   otherAxis = ! axis;
   spacing   = 0.0;

   UIViewSubviewsFor( self, view)
   {
      size = CGSizeAsSizeU( [view mulleLayoutSize]);
      area.value[ otherAxis] = size.value[ otherAxis] > area.value[ otherAxis]
                                   ? size.value[ otherAxis]
                                   : area.value[ otherAxis];
      area.value[ axis]     += size.value[ axis] + spacing;
      spacing                = _minimumLineSpacing;
   }

   return( CGSizeUAsSize( area));
}

static UIViewAutoresizing
   UIStackViewLayoutContextAutoresizingMaskForView( struct UIStackViewLayoutContext *ctxt, UIView *view)
{
   UIViewAutoresizing  mask;

   mask  = [view autoresizingMask];
   // we have to change the stacking order though
   mask &= ~(UIViewAutoresizingTop|UIViewAutoresizingBottom|UIViewAutoresizingLeft|UIViewAutoresizingRight);
   mask |= ctxt->defaultMask;

   return( mask);
}

// UIStackViewDistributionFillEqually
- (void) layoutSubviewsFillEqually
{
   CGRectU                           rect;
   int                               axis;
   UIView                            *view;
   UIViewAutoresizing                mask;
   struct UIStackViewLayoutContext   ctxt;

   if( ! [self setupLayoutContext:&ctxt])
      return;

   rect = ctxt.layoutRect;
   axis = _axisIndex;

   rect.size.value[ axis] = rect.size.value[ axis] / ctxt.n_views;

   UIViewSubviewsFor( self, view)
   {
      mask = UIStackViewLayoutContextAutoresizingMaskForView( &ctxt, view);

      [self layoutSubview:view
                   inRect:CGRectUAsRect( rect)
         autoresizingMask:mask];
      rect.origin.value[ axis] += rect.size.value[ axis] + _minimumLineSpacing;
   }
}

//
// UIStackViewDistributionFill
//
// Basically just add views, left to right or top to bottom. If there is space
// left at the end, the last view will get it. If views exhaust the space, they
// will get 0 size
//
// UIStackViewDistributionFillProportionally. Only really useful if there
// are resizable views in there, possibly all of them
//
- (void) layoutSubviewsFillWithDistribution:(UIStackViewDistribution) mode
{
   CGFloat                           factor;
   CGFloat                           remainder;
   CGRectU                           rect;
   CGSizeU                           area;
   CGSizeU                           size;
   int                               axis;
   UIView                            *lastView;
   UIView                            *view;
   UIViewAutoresizing                flexBit;
   UIViewAutoresizing                mask;
   struct UIStackViewLayoutContext   ctxt;

   if( ! [self setupLayoutContext:&ctxt])
      return;

   axis     = _axisIndex;
   lastView = _mulle_pointerarray_get_last( &_subviews);
   area     = CGSizeAsSizeU( [self areaCoveredByStackingSubviews]);
   rect     = ctxt.layoutRect;
   factor   = 1.0;

   flexBit = (axis == UILayoutConstraintAxisHorizontalIndex)
                  ?  UIViewAutoresizingFlexibleWidth
                  : UIViewAutoresizingFlexibleHeight;

   remainder = rect.size.value[ axis];
   if( mode == UIStackViewDistributionFillProportionally && area.value[ axis] != 0.0)
      factor = rect.size.value[ axis] / area.value[ axis];

   UIViewSubviewsFor( self, view)
   {
      mask = UIStackViewLayoutContextAutoresizingMaskForView( &ctxt, view);

      // if the view is resizable and we are doing just Fill, then
      // the first candidate gets all the remaining space or gets shrunk
      // by it
      size = CGSizeAsSizeU( [view mulleLayoutSize]);
      switch( mode)
      {
      case UIStackViewDistributionFillProportionally :
         size.value[ axis] *= factor;
         if( size.value[ axis] > remainder || view == lastView)
            rect.size.value[ axis] = remainder;
         else
            rect.size.value[ axis] = size.value[ axis];
         break;

      case UIStackViewDistributionFill               :
         if( mask & flexBit)
         {
            // calc space as height - height given to others
            size.value[ axis] = ctxt.layoutRect.size.value[ axis] - (area.value[ axis] - size.value[ axis]);
            if( size.value[ axis] < 0.0)
               size.value[ axis] = 0.0;
            rect.size.value[ axis] = size.value[ axis];
         }
         else
         {
            if( size.value[ axis] > remainder || view == lastView)
               rect.size.value[ axis] = remainder;
            else
               rect.size.value[ axis] = size.value[ axis];
         }
         break;

      case UIStackViewDistributionUnbounded :
         rect.size.value[ axis] = size.value[ axis];
      default :
         break;
      }

      // each view autoresizes in the layoutRect we divided it up for
      [self layoutSubview:view
                   inRect:CGRectUAsRect( rect)
         autoresizingMask:mask];

      rect.origin.value[ axis] += rect.size.value[ axis] + _minimumLineSpacing;
      remainder                -= rect.size.value[ axis] - _minimumLineSpacing;
   }
}


// UIStackViewDistributionEqualSpacing
- (void) layoutSubviewsEquallySpaced:(CGFloat) edge
{
   CGRectU                           rect;
   int                               axis;
   UIView                            *view;
   UIViewAutoresizing                mask;
   CGFloat                           space;
   CGSizeU                           size;
   CGSizeU                           area;
   struct UIStackViewLayoutContext   ctxt;

   if( ! [self setupLayoutContext:&ctxt])
      return;

   axis  = _axisIndex;
   area  = CGSizeAsSizeU( [self areaCoveredByStackingSubviews]);
   space = 0;
   if( ctxt.n_views > 1)
      space = (ctxt.layoutRect.size.value[ axis] - area.value[ axis] - edge) / (ctxt.n_views - 1);

   rect = ctxt.layoutRect;
   UIViewSubviewsFor( self, view)
   {
      // each view autoresizes in the layoutRect we divided it up for
      mask = UIStackViewLayoutContextAutoresizingMaskForView( &ctxt, view);

      size                   = CGSizeAsSizeU( [view mulleLayoutSize]);
      rect.size.value[ axis] = size.value[ axis];
      [self layoutSubview:view
                   inRect:CGRectUAsRect( rect)
         autoresizingMask:mask];
      rect.origin.value[ axis] += rect.size.value[ axis] + space;
   }
}


// UIStackViewDistributionEqualCentering
// See: https://spin.atomicobject.com/2016/06/22/uistackview-distribution/
// for what this does. It's probably useless

- (void) layoutSubviewsEquallyCentered
{
   int                                   axis;
   UIView                                *firstView;
   UIView                                *lastView;
   UIView                                *view;
   struct UIStackViewLayoutContext       ctxt;
   UIViewAutoresizing                    mask;
   CGFloat                               leftEdge;
   CGFloat                               rightEdge;
   CGFloat                               space;
   CGRectU                               rect;
   CGSizeU                               size;
   NSUInteger                            i;

   if( ! [self setupLayoutContext:&ctxt])
      return;

   firstView = _mulle_pointerarray_get( &_subviews, 0);
   lastView  = _mulle_pointerarray_get_last( &_subviews);
   axis      = _axisIndex;
   leftEdge  = CGSizeAsSizeU( [firstView mulleLayoutSize]).value[ axis] / 2.0;
   rightEdge = CGSizeAsSizeU( [lastView mulleLayoutSize]).value[ axis] / 2.0;

   space = 0;
   if( ctxt.n_views)
      space = (ctxt.layoutRect.size.value[ axis] - leftEdge - rightEdge) / (ctxt.n_views - 1);

   rect = ctxt.layoutRect;
   i    = 0;

   UIViewSubviewsFor( self, view)
   {
      // each view autoresizes in the layoutRect we divided it up for
      mask = UIStackViewLayoutContextAutoresizingMaskForView( &ctxt, view);

      size                     = CGSizeAsSizeU( [view mulleLayoutSize]);
      rect.size.value[ axis]   = size.value[ axis];
      rect.origin.value[ axis] = ctxt.layoutRect.origin.value[ axis]
                                 + leftEdge
                                 + (space * i)
                                 - rect.size.value[ axis] / 2;
      [self layoutSubview:view
                   inRect:CGRectUAsRect( rect)
         autoresizingMask:mask];
      ++i;
   }
}


//
// layout in row, column fashion. The views need to be fixed size currently
//
- (void) layoutSubviewsFillRowColumn
{
   UIView       *view;
   CGRectU      layoutRect;
   CGRectU      rect;
   CGRectU      rowLayoutRect;
   CGRectU      frame;
   CGSizeU      spacing;
   CGFloat      rowHeight;
   int          axis;
   int          otherAxis;

   axis      = [self axisIndex];
   otherAxis = ! axis;

   spacing.value[ axis]      = [self minimumInteritemSpacing];
   spacing.value[ otherAxis] = [self minimumLineSpacing];

   layoutRect    = CGRectAsRectU( UIEdgeInsetsInsetRect( [self contentRect], [self padding]));
   rowLayoutRect = layoutRect;

   UIViewSubviewsFor( self, view)
   {
      frame = CGRectAsRectU( [view frame]);
      if( frame.size.value[ axis] > rowLayoutRect.size.value[ axis])
      {
         // start a new row
         rowLayoutRect.size.value[ axis]        = layoutRect.size.value[ axis];
         rowLayoutRect.origin.value[ axis]      = layoutRect.origin.value[ axis];
         rowLayoutRect.origin.value[ otherAxis] = rowLayoutRect.origin.value[ otherAxis] \
                                                  + rowHeight \
                                                  + spacing.value[ otherAxis];
         rowLayoutRect.size.value[ otherAxis]   = layoutRect.size.value[ otherAxis] \
                                                  - rowLayoutRect.origin.value[ otherAxis];
         rowHeight = frame.size.value[ otherAxis];
      }
      rect.origin = rowLayoutRect.origin;
      if( frame.size.value[ otherAxis] > rowLayoutRect.size.value[ otherAxis])
         rect.size = CGSizeUZero;
      else
         rect.size = frame.size;

      [self layoutSubview:view
                   inRect:CGRectUAsRect( rect)
         autoresizingMask:UIViewAutoresizingTop|UIViewAutoresizingLeft];

      // advance preshrunk remaining row
      rowLayoutRect.origin.value[ axis] += frame.size.value[ axis] + spacing.value[ axis];
      rowLayoutRect.size.value[ axis]   -= frame.size.value[ axis] + spacing.value[ axis];
      rowHeight                          = frame.size.value[ otherAxis] > rowHeight ? frame.size.value[ otherAxis] : rowHeight;
   }
}


// take all "odd" subviews, treat them as keys. All "even" subviews are values.
// Arrange in rows of key/value. All subviews are sized to the max. width of
// the key. the "values" fill the remaining space.
//
- (void) layoutSubviewsFillKeyValue
{
   UIView                                *keyView;
   UIView                                *spacerView;
   UIView                                *valueView;
   CGSizeU                               size;
   CGRectU                               layoutRect;
   CGRectU                               rowLayoutRect;
   CGRectU                               keyFrame;
   CGRectU                               spacerFrame;
   CGRectU                               valueFrame;
   CGSizeU                               spacing;
   int                                   axis;
   int                                   otherAxis;
   CGFloat                               keyValue;
   CGFloat                               spacerValue;
   CGFloat                               valueValue;
   CGFloat                               valueSpacing;
   struct mulle_pointerarrayenumerator   rover;

   axis      = [self axisIndex]; // usually Y
   otherAxis = ! axis;           // usually X

   spacing.value[ otherAxis] = [self minimumInteritemSpacing];
   spacing.value[ axis]      = [self minimumLineSpacing];

   layoutRect    = CGRectAsRectU( UIEdgeInsetsInsetRect( [self contentRect], [self padding]));
   rowLayoutRect = layoutRect;

   keyValue    = 0.0;
   spacerValue = 0.0;
   valueValue  = 0.0;
   spacerView  = nil;

   // cant use mulle_pointerarray_for, need more control here
   rover = mulle_pointerarray_enumerate( &_subviews);
   while( mulle_pointerarrayenumerator_next( &rover, (void **) &keyView))
   {
      size     = CGSizeUMakeWithSize( [keyView sizeThatFits:CGSizeMake( INFINITY, INFINITY)]);
      keyValue = size.value[ otherAxis] > keyValue
                 ? size.value[ otherAxis]
                 : keyValue;

      if( _showsSpacerView)
      {
         if( ! mulle_pointerarrayenumerator_next( &rover, (void **) &spacerView))
            break;
         size        = CGSizeUMakeWithSize( [spacerView sizeThatFits:CGSizeMake( INFINITY, INFINITY)]);
         spacerValue = size.value[ otherAxis] > spacerValue
                       ? size.value[ otherAxis]
                       : spacerValue;
      }

      if( ! mulle_pointerarrayenumerator_next( &rover, (void **) &valueView))
         break;

      // set prelimary width for calculation
//      if( UIViewAutoresizingIsFlexibleInAxis( [valueView autoresizingMask], otherAxis))
//      {
//         valueFrame                        = CGRectAsRectU( [valueView frame]);
//         valueFrame.size.value[ otherAxis] = rowLayoutRect.size.value[ otherAxis] - spacerValue - keyValue;
//      }
      size       = CGSizeUMakeWithSize( [valueView sizeThatFits:CGSizeMake( INFINITY, INFINITY)]);
      valueValue = size.value[ otherAxis] > valueValue
                 ? size.value[ otherAxis]
                 : valueValue;

   }
   mulle_pointerarrayenumerator_done( &rover);

   rover = mulle_pointerarray_enumerate( &_subviews);
   while( mulle_pointerarrayenumerator_next( &rover, (void **) &keyView))
   {
      if( _showsSpacerView)
      {
         if( ! mulle_pointerarrayenumerator_next( &rover, (void **) &spacerView))
            break;
      }

      if( ! mulle_pointerarrayenumerator_next( &rover, (void **) &valueView))
         break;

      // todo: use margin info ?

      keyFrame    = CGRectUMakeWithRect( [keyView frame]);
      spacerFrame = CGRectUMakeWithRect( [spacerView frame]);
      valueFrame  = CGRectUMakeWithRect( [valueView frame]);
      rowLayoutRect.size.value[ axis] = keyFrame.size.value[ axis] > spacerFrame.size.value[ axis]
                                        ? keyFrame.size.value[ axis]
                                        : spacerFrame.size.value[ axis];
      rowLayoutRect.size.value[ axis] = rowLayoutRect.size.value[ axis] > valueFrame.size.value[ axis]
                                        ? rowLayoutRect.size.value[ axis]
                                        : valueFrame.size.value[ axis];

      // set x/y/w for both (could place intermediate divider view here)
      keyFrame.origin.value[ otherAxis]    = rowLayoutRect.origin.value[ otherAxis];
      keyFrame.origin.value[ axis]         = rowLayoutRect.origin.value[ axis];
      keyFrame.size.value[ otherAxis]      = keyValue;
      keyFrame.size.value[ axis]           = rowLayoutRect.size.value[ axis];

      spacerFrame.origin.value[ otherAxis] = keyValue + spacing.value[ otherAxis];
      spacerFrame.origin.value[ axis]      = rowLayoutRect.origin.value[ axis];
      spacerFrame.size.value[ otherAxis]   = spacerValue;
      spacerFrame.size.value[ axis]        = rowLayoutRect.size.value[ axis];

      valueSpacing                         = spacerValue + spacing.value[ otherAxis];
      if( _showsSpacerView)
         valueSpacing += spacing.value[ otherAxis];

      if( UIViewAutoresizingIsFlexibleInAxis( [valueView autoresizingMask], otherAxis))
         valueValue = rowLayoutRect.size.value[ otherAxis] - valueSpacing - keyValue;

      valueFrame.origin.value[ otherAxis]  = keyValue + valueSpacing;
      valueFrame.origin.value[ axis]       = rowLayoutRect.origin.value[ axis];
      valueFrame.size.value[ otherAxis]    = valueValue;
      valueFrame.size.value[ axis]         = rowLayoutRect.size.value[ axis];

      [keyView setFrame:CGRectMakeWithRectU( keyFrame)];
      [spacerView setFrame:CGRectMakeWithRectU( spacerFrame)];
      [valueView setFrame:CGRectMakeWithRectU( valueFrame)];

      if( spacing.value[ axis] > valueFrame.size.value[ axis])
         rowLayoutRect.origin.value[ axis] += spacing.value[ axis];
      else
         rowLayoutRect.origin.value[ axis] += valueFrame.size.value[ axis];
   }
   mulle_pointerarrayenumerator_done( &rover);
}


- (BOOL) layoutSubviews
{
   switch( _distribution)
   {
   case UIStackViewDistributionFill :
      [self layoutSubviewsFillWithDistribution:UIStackViewDistributionFill];
      break;
   case UIStackViewDistributionFillEqually :
      [self layoutSubviewsFillEqually];
      break;
   case UIStackViewDistributionFillProportionally :
      [self layoutSubviewsFillWithDistribution:UIStackViewDistributionFillProportionally];
      break;
   case UIStackViewDistributionEqualSpacing :
      [self layoutSubviewsEquallySpaced:0];
      break;
   case UIStackViewDistributionEqualCentering :
      [self layoutSubviewsEquallyCentered];
      break;
   case UIStackViewDistributionFillRowColumn :
      [self layoutSubviewsFillRowColumn];
      break;
   case UIStackViewDistributionFillKeyValue :
      [self layoutSubviewsFillKeyValue];
      break;
   case UIStackViewDistributionUnbounded :
      [self layoutSubviewsFillWithDistribution:UIStackViewDistributionUnbounded];
      break;
   case UIStackViewDistributionCustom :
      if( ! _customDistributor)
         abort();
      (*_customDistributor)( self);
      break;
   default :
      abort();
   }
   return( YES);
}


- (CGSize) sizeThatFits:(CGSize) size
                context:(id <UILayoutContext>) context
{
   UIView       *view;
   NSUInteger   n;
   CGRect       frame;
   CGRect       viewFrame;

   // assume already layouted!
   // get first and last subview
   n = mulle_pointerarray_get_count( &_subviews);
   if( ! n)
      return( CGSizeZero);

   switch( _distribution)
   {
   case UIStackViewDistributionFill :
   case UIStackViewDistributionFillEqually :
   case UIStackViewDistributionFillProportionally :
   case UIStackViewDistributionEqualSpacing :
   case UIStackViewDistributionEqualCentering :
   case UIStackViewDistributionFillKeyValue :
      view  = mulle_pointerarray_get( &_subviews, 0);
      frame = [view frame];

      if( n >= 2)
      {
         view      = mulle_pointerarray_get( &_subviews, n - 1);
         viewFrame = [view frame];
         frame     = CGRectUnion( frame, viewFrame);
      }
      break;

   default :
      frame = CGRectZero;
      UIViewSubviewsFor( self, view)
      {
         viewFrame = [view frame];
         frame     = CGRectUnion( frame, viewFrame);
      }
   }
   frame = CGRectExtrudeUsingEdgeInsets( frame, [self padding]);

   // need to project back to superview ? not really I think
   //   frame = [self convertRect:frame
   //                      toView:[self superview]];
   return( frame.size);
}


- (void) didAddSubview:(UIView *) view
{
   NSUInteger           legacyBits;
   UIViewAutoresizing   autoresizingMask;

   autoresizingMask = [view autoresizingMask];
   legacyBits       = autoresizingMask & UIViewAutoresizingLegacyBits;
   if( legacyBits)
   {
      autoresizingMask &= ~UIViewAutoresizingLegacyBits;
      [view setAutoresizingMask:autoresizingMask];

      MulleUILog( "%@ %s bits were cleared by %@ (hint: use contentMode bits)",
                     view,
                     UIViewAutoresizingUTF8String( legacyBits),
                     self);
   }

   [super didAddSubview:view];
}
@end
