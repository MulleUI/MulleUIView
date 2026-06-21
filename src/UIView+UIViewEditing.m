#import "UIView+UIViewEditing.h"


#pragma clang diagnostic ignored "-Wparentheses"


@interface UIView( Private)

- (struct mulle_pointerarray *) _subviews;

@end


@implementation UIView( UIViewEditing)

static inline NSUInteger   UIViewGetIndexOfSubview( UIView *self, UIView *other)
{
   NSUInteger   i;

   i = NSNotFound;
   if( self && other)
      i = mulle_pointerarray_find( &self->_subviews, other);
   return( i);
}


void  _mulle_pointerarray_swap( struct mulle_pointerarray *array1,
                                struct mulle_pointerarray *array2)
{
   struct mulle_pointerarray   tmp;

   tmp     = *array1;
   *array1 = *array2;
   *array2 = tmp;
}


#if 0
void  mulle_pointerarray_remove( struct mulle_pointerarray *array,
                                 void *item)
{
   uintptr_t   i;

   i = mulle_pointerarray_find( array, item);
   if( i == mulle_not_found_e)
      return;
   mulle_pointerarray_remove_in_range( array, mulle_range_make( i, 1));
}
#endif

//
// if you have 'A B C' then an insert at 1 of D will get you
// 'A D B C'
//
// Debatable! It might be nicer to have the subviews atomically switched out ?
//
void  mulle_pointerarray_insert_at_index( struct mulle_pointerarray *array,
                                          void *item,
                                          unsigned int i)
{
   struct mulle_pointerarray   tmp;
   void                        **curr;
   void                        **insertion;
   void                        **sentinel;
   unsigned int                count;

   assert( array);

   count = mulle_pointerarray_get_count( array);
   if( i == count)
   {
      _mulle_pointerarray_add( array, item);
      return;
   }

   curr      = array->_storage;
   insertion = &curr[ i];
   sentinel  = &curr[ count];
   if( insertion > sentinel)
      insertion = sentinel;

   _mulle_pointerarray_init( &tmp,
                             count + 1,
                             _mulle_pointerarray_get_allocator( array));
   // copy old over including item of insertion
   while( curr < insertion)
      _mulle_pointerarray_add( &tmp, *curr++);

   // insert ours
   _mulle_pointerarray_add( &tmp, item);

   // copy rest
   while( curr < sentinel)
      _mulle_pointerarray_add( &tmp, *curr++);

   _mulle_pointerarray_swap( array, &tmp);
   _mulle_pointerarray_done( &tmp);
}


void  mulle_pointerarray_move( struct mulle_pointerarray *array,
                               unsigned int from,
                               unsigned int to)
{
   void           **curr;
   void           **sentinel;
   unsigned int   count;
   void           *item;

   assert( array);


   count = _mulle_pointerarray_get_count( array);
   //
   // so if someone passed in count to move to "past" current end, we say ok
   // but its really, the wrong index
   if( count && to == count)
      to = count - 1;

   //  avoid trivial non moving code, that could trip us up
   if( from == to)
      return;

   curr      = array->_storage;
   sentinel  = &curr[ count];

   if( &curr[ from] >= sentinel || &curr[ to] >= sentinel)
      abort();
   if( &curr[ from] < curr || &curr[ to] < curr)
      abort();

   item = curr[ from];

   if( from < to)
   {
      //
      // a b c d  move  b to d
      //   *   o
      // save b
      // a X <[c d] = a c d d
      // -> a c d b
      //
      memmove( &curr[ from],
               &curr[ from + 1],
               sizeof( void *) * (sentinel - &curr[ from + 1]));
   }
   else
   {
      //
      // a b c d  move  c to a
      // o   *
      // save c
      // [a b]> X d = a a b d
      // -> c a b d
      //
      memmove( &curr[ 1],
               &curr[ 0],
               sizeof( void *) * (&curr[ from + 1] - curr));
   }

   curr[ to] = item;
}



- (void) insertSubview:(UIView *) view
               atIndex:(NSInteger) index
{
   assert( view);
   assert( ! [view superview]);
   assert( view != self);
   assert( [view isKindOfClass:[UIView class]]);

   [view willMoveToSuperview:self];

   view->_superview = self;
   mulle_pointerarray_insert_at_index( [self _subviews],
                                       [view retain],
                                       (unsigned int) index);

   [view setWindow:self->_window];
   [view didMoveToSuperview:self];

   [self didAddSubview:view];
}


- (void) insertSubview:(UIView *) view
          aboveSubview:(UIView *) other
{
   NSInteger   index;

   index = UIViewGetIndexOfSubview( self, other);
   if( index == NSNotFound)
      index = -1;
   [self insertSubview:view
               atIndex:index + 1];
}


- (void) insertSubview:(UIView *) view
          belowSubview:(UIView *) other
{
   NSInteger   index;

   index = UIViewGetIndexOfSubview( self, other);
   [self insertSubview:view
               atIndex:index];
}


- (void) exchangeSubviewAtIndex:(NSInteger) index1
             withSubviewAtIndex:(NSInteger) index2
{
   void           **curr;
   void           *item;
   unsigned int   count;

   count = mulle_pointerarray_get_count( &_subviews);
   if( index1 >= count || index2 >= count)
      abort();

   curr          = _subviews._storage;
   item          = curr[ index1];
   curr[ index2] = curr[ index1];
   curr[ index2] = item;
}


- (void) replaceSubview:(UIView *) view
               withView:(UIView *) other
{
   NSInteger   index;

   index = UIViewGetIndexOfSubview( self, view);
   if( index == NSNotFound)
      abort();

   [view removeFromSuperview];
   if( other)
      [self insertSubview:other
                  atIndex:index];
}


/*
 * visually back is first in the array
 */
- (void) sendSubviewToBack:(UIView *) view
{
   NSUInteger   index;

   index = UIViewGetIndexOfSubview( self, view);
   assert( index != NSNotFound);
   if( index == NSNotFound)
      return;

   mulle_pointerarray_move( &_subviews, index, 0);
}


- (void) bringSubviewToFront:(UIView *) view
{
   NSUInteger     index;
   unsigned int   count;

   index = UIViewGetIndexOfSubview( self, view);
   assert( index != NSNotFound);
   if( index == NSNotFound)
      return;

   count = mulle_pointerarray_get_count( &_subviews);
   mulle_pointerarray_move( &_subviews, index, count - 1);
}


/*
 *
 */

- (BOOL) _isSubviewOrDescendantview:(UIView *) view
{
   UIView   *candidate;

   UIViewSubviewsFor( self, candidate)
   {
      if( view == candidate)
         return( YES);
   }

   UIViewSubviewsFor( self, candidate)
   {
      if( [candidate _isSubviewOrDescendantview:view])
         return( YES);
   }
   return( NO);
}


- (BOOL) isDescendantOfView:(UIView *) view
{
   if( self == view)
      return( YES);
   return( [self _isSubviewOrDescendantview:view]);
}

@end

