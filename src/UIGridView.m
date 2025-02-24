//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//
#import "UIGridView.h"

#import "import-private.h"

#ifdef __has_include
# if __has_include( "UIView+Layout.h")
#  import "UIView+Layout.h"
# endif
#endif

@implementation UIGridView


- (instancetype) initWithLayer:(id <UILayer>) layer
                         frame:(CGRect) frame
{
   self = [super initWithLayer:layer
                         frame:frame];
   if( self)
   {
      _rows    = 3;
      _columns = 3;
      _space   = CGSizeMake( 8.0f, 8.0f);
   }
   return( self);
}


- (BOOL) layoutSubviews
{
   UIView       *view;
   CGRect       rect;
   CGRect       frame;
   BOOL         flag;
   NSUInteger   n;
   NSUInteger   i;

   if( (*_willLayoutSubviewsCallback)( self))
   {
      n = _rows * _columns;

      mulle_alloca_do( rects, CGRect, n)
      {
         rect = [self contentRect];
         CGRectPartitionVerticallyAndHorizontally( rect, _space, _rows, _columns, rects);

         i = 0;
         UIViewSubviewsFor( self, view)
         {
            if( i < n)
            {
               frame = CGRectIntegral( rects[ i]);
               [view setFrame:frame];
               ++i;
               continue;
            }

            [self layoutSubview:view
                         inRect:rect
               autoresizingMask:[view autoresizingMask]];
         }
      }
   }
   flag = (*_didLayoutSubviewsCallback)( self);
   return( flag);
}


- (UIView *) viewForRow:(NSUInteger) row
                 column:(NSUInteger) column
{
   unsigned int  i, n;

   i = row * _columns + column;
   n = mulle_pointerarray_get_count( &_subviews);
   if( i >= n)
      return( nil);
   return( mulle_pointerarray_get( &_subviews, i));
}


@end
