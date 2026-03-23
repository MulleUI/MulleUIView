//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#import "UIViewController.h"

#import "import-private.h"

#import "UIView+UIViewEditing.h"
#import "UIView+Layout.h"



static BOOL   willLayoutSubviewsCallback( UIView *view);
static BOOL   didLayoutSubviewsCallback( UIView *view);


@interface NSObject( UIResponder)

- (UIEvent *) handleEvent:(UIEvent *) event;

@end


@implementation UIViewController

+ (instancetype) objectWithView:(UIView *) view
{
   UIViewController *obj;

   obj = [self alloc];
   obj = [obj initWithView:view];
   obj = [obj autorelease];
   return(obj);
}


- (instancetype) initWithView:(UIView *) view
{
   [super init];

   _mulle_pointerarray_init( &_views, 4, MulleObjCInstanceGetAllocator( self));
   if( view)
      [self addToViews:view];
   return( self);
}


- (instancetype) init
{
   return( [self initWithView:nil]);
}


- (void) finalize
{
   UIView   *view;

   mulle_pointerarray_for( &_views, view)
   {
      [view setEventCallback:NULL];
      [view setController:nil];
   }
   [_mainView setEventCallback:NULL];
   [_mainView setController:nil];

   [super finalize]; // call anywhere you like
}


- (void) dealloc
{
   mulle_pointerarray_done( &_views);

   [super dealloc];  // call at end
}


# pragma mark - UIView + forwarding

// ---
// UIView( UIView)
// ---
- (UIView *) mainView
{
   assert( _mainView);
   return( _mainView);
}


- (UIView *) view
{
   assert( _mainView);
   return( _mainView);
}


static UIEvent  *eventCallback( UIView *view, UIEvent *event)
{
   UIViewController  *self;

   self = [view controller];
   assert( [self isKindOfClass:[UIViewController class]]);

   return( [self handleEvent:event
                      ofView:view]);
}


- (UIEvent *) handleEvent:(UIEvent *) event
                   ofView:(UIView *) view
{
   MULLE_C_UNUSED( view);
   // We  want to have UIResponder functionality so we use it
   // By default, this does nothing, so view will handle the event itself
   // eventually
   return( [super handleEvent:event]);

}


- (void) addToViews:(UIView *) view
{
   if( ! view)
      MulleObjCThrowInvalidArgumentExceptionUTF8String( "can't add nil as view");

   if( ! _mainView)
   {
      _mainView = view;
      [self shareRecursiveLockWithObject:view];
   }
   else
   {
      assert(_mainView != view);

      assert( _mulle_pointerarray_find( &_views, view) == mulle_not_found_e);
      _mulle_pointerarray_add( &_views, view);
   }

   [view setEventCallback:eventCallback];
   [view setController:self];

   if( _isLayoutingViews)
   {
      [view setWillLayoutSubviewsCallback:willLayoutSubviewsCallback];
      [view setDidLayoutSubviewsCallback:didLayoutSubviewsCallback];
   }
}


- (void) addView:(UIView *) view
{
   [self addToViews:view];
}


- (struct mulle_pointerarray *) _views
{
   return( &_views);
}


- (UIView *) viewWithTag:(NSInteger) tag
{
   UIView   *view;

   mulle_pointerarray_for( &_views, view)
   {
      if( [view tag] == tag)
         break;
   }

   if( ! view && [_mainView tag] == tag)
      view = _mainView;
   return( view);
}


- (NSInteger) getViews:(UIView * *) buf
                 range:(NSRange) range
{
   NSUInteger   n;

   assert( MulleObjCRangeIsValid( range));

   if( ! buf)
      return( -1);

   if( ! _mainView)
      return( 0);

   // add _mainView to the counr
   n     = mulle_pointerarray_get_count( &_views) + 1;
   range = MulleObjCRangeValidateAgainstLength( range, n);
   if( ! MulleObjCRangeIsValid( range))
      return( -1);

   if( range.location == 0)
   {
      *buf++        = _mainView;
      range.length -= 1;
   }

   mulle_idarray_get_in_range( &_views, buf, range);

   return( n);
}


- (void) removeFromViews:(UIView *) view
{
   NSUInteger   index;

   if( view == _mainView)
   {
      _mainView = nil;
      [self shareRecursiveLockWithObject:nil];
   }
   else
   {
      // nil will not be found, that's good
      index = mulle_pointerarray_find( &self->_views, view);
      if( index == NSNotFound)
         return;

      mulle_pointerarray_remove_in_range( &_views,
                                          mulle_range_make( (unsigned int) index, 1));
   }
}


- (void) removeView:(UIView *) view
{
   [self removeFromViews:view];
}


- (void) removeAllViews
{
   UIView *   view;

   while( (view = mulle_pointerarray_get_last( &_views)))
      [self removeFromViews:view];
   [self removeFromViews:_mainView];
}


- (BOOL) isMultiView
{
   return( mulle_pointerarray_get_count( &_views) != 0);
}

//- (void) setNeedsDisplay
//{
//   _needsDisplay = YES;
//}


- (void *) forward:(void *) param
{
   assert( _mainView); // window should not forward...
   return( mulle_objc_object_call_variable_inline( _mainView,
                                                   (mulle_objc_methodid_t) _cmd,
                                                   param));
}


- (BOOL) respondsToSelector:(SEL) sel
{
   if( [super respondsToSelector:sel])
      return( YES);
   return( [_mainView respondsToSelector:sel]);
}


- (void)       view:(UIView *) view
    didMoveToWindow:(id <UIWindow>) window
{
   [self resignFirstResponder];

   if( ! window)
   {
      [self removeView:view];
      return;
   }

//   // conceivably could remove myself from window and add to
//   // other window, assume other views will follow suite..
//
//   if( [window respondsToSelector:@selector( removeFromViewControllers:)])
//   {
//      [_window removeFromViewControllers:self];
//      [window addToViewControllers:self];
//   }
}


// subclass needs to do it
//- (void) layoutViews
//{
//}

// the default implementation does nothing
- (BOOL) layoutView:(UIView *) view
      layoutInfo:(struct UILayoutInfo *) context
   autoresizingMask:(UIViewAutoresizing) autoresizingMask
{
   MULLE_C_UNUSED( view);
   MULLE_C_UNUSED( context);
   MULLE_C_UNUSED( autoresizingMask);
   return( NO);
}


static BOOL   willLayoutSubviewsCallback( UIView *view)
{
   [[view controller] layoutViews];
   return( NO);
}


static BOOL   didLayoutSubviewsCallback( UIView *view)
{
   // view should not skip doing recursive layouting
   return( YES);
}


- (void) setIsLayoutingViews:(BOOL) flag
{
   UIViewControllerViewFor( self, view)
   {
      [view setWillLayoutSubviewsCallback:flag ? willLayoutSubviewsCallback : 0];
      [view setDidLayoutSubviewsCallback:flag ? didLayoutSubviewsCallback : 0];
   }
   _isLayoutingViews = flag;
}

@end
