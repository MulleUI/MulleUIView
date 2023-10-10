#import "UIView.h"

#import "import-private.h"

#import "UIView+DebugPrivate.h"


@interface UIView( Forward)

- (void) willChange;

@end


@interface NSObject( Forward)

- (char *) titleUTF8String;

@end


@implementation NSObject ( UIView)

- (BOOL) __isUIView
{
   return( NO);
}

- (BOOL) __isUIWindow
{
   return( NO);
}

@end

//#define RENDER_DEBUG
//#define RENDER_VERBOSE_DEBUG
//#define HAVE_RENDER_CACHE

static BOOL   defaultYESCallback( UIView *view)
{
   return( YES);
}

static void   defaultVoidCallback( UIView *view)
{
}



static UIEvent   *defaultHandleEventCallback( UIView *view, UIEvent *event)
{
   return( event);
}


static UIMouseMotionEvent   *defaultHandleMouseMotionEventCallback( UIView *view,
                                                                    UIMouseMotionEvent *event)
{
   return( event);
}


@implementation UIView

- (BOOL) __isUIView
{
   return( YES);
}


+ (Class) layerClass
{
   return( [UINullLayer class]);
}


+ (instancetype) viewWithFrame:(CGRect) frame
{
   return( [[[self alloc] initWithFrame:frame] autorelease]);
}


+ (instancetype) viewWithLayer:(id <UILayer>) layer
{
   return( [[[self alloc] initWithLayer:layer] autorelease]);
}


- (void) resetForInit
{
   _clipsToBounds                   = YES;  // default
   _userInteractionEnabled          = YES;  // default
   _alpha                           = 1.0;
   _bounds.size.width               = INFINITY; // once we change the bounds size
   _willLayoutLayersCallback        = defaultYESCallback;
   _didLayoutLayersCallback         = defaultVoidCallback;
   _willLayoutSubviewsCallback      = defaultYESCallback;
   _didLayoutSubviewsCallback       = defaultYESCallback;
   _willLayoutTrackingAreasCallback = defaultYESCallback;
   _didLayoutTrackingAreasCallback  = defaultVoidCallback;
   _eventCallback                   = defaultHandleEventCallback;
   _mouseMotionEventCallback        = defaultHandleMouseMotionEventCallback;
   _needsTrackingAreaUpdate         = YES;
   _originalFrame.size.width        = 0.0;
   _lastBounds.size.width           = 0.0;
   // needs to be properly removed before reuse
   assert( ! _window);

//   _needsDisplay           = YES;

   assert( mulle_pointerarray_get_count( &_trackingAreas) == 0);
}


// designated initializer
- (instancetype) initWithLayer:(id <UILayer>) layer
                         frame:(CGRect) frame
{
   struct mulle_allocator   *allocator;

   assert( ! layer || [layer conformsToProtocol:@protocol( UILayer)]);

   if( ! layer)
   {
      [self release];
      return( nil);
   }

   _mainLayer = [layer retain];
   _frame     = UIViewMakeFrameWithRect( frame);
   [self resetForInit];

   // initially a UIView with only its mainLayer is fairly slim, and only
   // needs one allocation for itself

   allocator = MulleObjCInstanceGetAllocator( self);
   mulle_pointerarray_init( &_trackingAreas, 0, allocator);
   mulle_pointerarray_init( &_subviews, 0, allocator);
   mulle_pointerarray_init( &_layers, 0, allocator);

   return( self);
}


- (instancetype) initWithFrame:(CGRect) frame
{
   id <UILayer>   layer;
   Class          cls;
   CGRect         rect;

   frame = UIViewMakeFrameWithRect( frame);
   rect  = CGRectMake( 0.0f, 0.0f, frame.size.width, frame.size.height);
   cls   = [[self class] layerClass];
   layer = [[[cls alloc] initWithFrame:rect] autorelease];
   self  = [self initWithLayer:layer
                         frame:frame];
   return( self);
}

//
// What's the expectation here with regard to frame ?
// Assume layer is already relative to UIView ?
// I don't think so... Assume its in screen/windows space
//
- (instancetype) initWithLayer:(id <UILayer>) layer
{
   CGRect   frame;

   frame = [layer frame];
   frame = UIViewMakeFrameWithRect( frame);
   [layer setFrame:CGRectMake( 0.0f, 0.0f, frame.size.width, frame.size.height)];

   return( [self initWithLayer:layer
                         frame:frame]);
}


- (instancetype) init
{
   return( [self initWithFrame:CGRectZero]);
}


- (void) finalize
{
   assert( ! _window);  // remove from window before explicitly finalizing ?

   [_cacheLayer autorelease];
   _cacheLayer = nil;

   [super finalize];
}


- (void) dealloc
{
   mulle_pointerarray_release_all( &_trackingAreas);
   mulle_pointerarray_done( &_trackingAreas);

   mulle_pointerarray_release_all( &_subviews);
   mulle_pointerarray_done( &_subviews);

   mulle_pointerarray_release_all( &_layers);
   mulle_pointerarray_done( &_layers);

   [_shadowLayer release];
   [_mainLayer release];

   MulleObjCObjectSetDuplicatedUTF8String( self, &_debugNameUTF8String, NULL);

   [super dealloc];
}


- (id) copy 
{
   UIView         *copy;
   id <UILayer>   layer;
   UIView         *subview;

   layer = [[self->_mainLayer copy] autorelease];
   copy  = [[[self class] alloc] initWithLayer:layer];
   {
      copy->_shadowLayer = [_shadowLayer copy];

      mulle_pointerarray_for( &_layers, layer)
      {
         layer = [layer copy];
         [copy mulleAddRetainedLayer:layer];
      }

      mulle_pointerarray_for( &_subviews, subview)
      {
         subview = [subview copy];
         [copy mulleAddRetainedSubview:subview];
      }

      copy->_hidden                 = self->_hidden;
      copy->_userInteractionEnabled = self->_userInteractionEnabled;
      copy->_clipsToBounds          = self->_clipsToBounds;
      copy->_padding                = self->_padding;
      copy->_margins                = self->_margins;
      copy->_alpha                  = self->_alpha;
      copy->_autoresizingMask       = self->_autoresizingMask;

      // useful to copy this
      MulleObjCObjectSetDuplicatedUTF8String( copy,
                                              &copy->_reuseIdentifierUTF8String,
                                              self->_reuseIdentifierUTF8String);
   }
   return( copy);
}


static inline CGRect   getBounds( UIView *self)
{
   CGRect  bounds;

   bounds.origin = self->_bounds.origin;
   bounds.size   = self->_bounds.size.width == INFINITY
                   ? self->_frame.size
                   : self->_bounds.size;
   return( bounds);
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-property-ivar"
//
// for layers bounds are inherited directly, so the layer "sticks"
// (and need to be panned by its bounds)
//
- (CGRect) bounds
{
   return( getBounds( self));
}
#pragma clang diagnostic pop


- (void) setBounds:(CGRect) bounds
{
   [self willChange];

   // keep this for legacy layout
//   if( _lastBounds.size.width == 0.0)
//      _lastBounds = getBounds( self);

   _bounds.origin = bounds.origin;
   if( CGSizeEqualToSize( _frame.size, bounds.size))
      _bounds.size.width = INFINITY;
   else
      _bounds.size = bounds.size;
}

#if 0
- (CGRect) lastBounds
{
   // if not set, return current bounds
   if( self->_lastBounds.size.width == 0.0)
      return( getBounds( self));

   // this shouldn't happen, as we store _lastBounds expanded only
   assert( ! isinf( self->_lastBounds.size.width));
   return( self->_lastBounds);
}
#endif

- (CGRect) contentRect
{
   CGRect  rect;

   rect.origin = CGPointMake( 0.0f, 0.0f);
   rect.size   = getBounds( self).size;
   return( rect);
}


- (void) setAutoresizingMask:(NSUInteger) mask
{
   // weed out illegal values
   CGContentModeAssert( mask);

   _autoresizingMask = mask;
}


- (void) setMargins:(UIEdgeInsets) m
{
   _margins = m;

   if( _autoresizingMask == 0 && (m.top != 0.0 || m.left != 0.0 || m.bottom != 0.0 || m.right != 0.0))
      _autoresizingMask = UIViewAutoresizingCenter;
}


- (void) setMouseMotionEventCallback:(UIMouseMotionEvent *(*)(UIView *, UIMouseMotionEvent *)) callback
{
   if( ! callback)
      callback = defaultHandleMouseMotionEventCallback;
   _mouseMotionEventCallback = callback;
}


- (void) setEventCallback:(UIEvent *(*)(UIView *, UIEvent *)) callback
{
   if( ! callback)
      callback = defaultHandleEventCallback;
   _eventCallback = callback;
}

// return NO, if default layoutSubviews code should not run
- (void) setWillLayoutSubviewsCallback:(BOOL (*)( UIView *)) callback
{
   if( ! callback)
      callback = defaultYESCallback;
   _willLayoutSubviewsCallback = callback;
}

- (void) setDidLayoutSubviewsCallback:(BOOL (*)( UIView *)) callback
{
   if( ! callback)
      callback = defaultYESCallback;
   _didLayoutSubviewsCallback = callback;
}

- (void) setWillLayoutLayersCallback:(BOOL (*)( UIView *)) callback
{
   if( ! callback)
      callback = defaultYESCallback;
   _willLayoutLayersCallback = callback;
}


- (void) setDidLayoutLayersCallback:(void (*)( UIView *)) callback
{
   if( ! callback)
      callback = defaultVoidCallback;
   _didLayoutLayersCallback = callback;
}



//
//
//
- (struct mulle_pointerarray *) _subviews
{
   return( &_subviews);
}


- (void) didAddSubview:(UIView *) view
{
   UIViewLog( "%#@", view);
}


- (void) willRemoveSubview:(UIView *) subview
{
}


- (void) willMoveToSuperview:(UIView *) newSuperview
{
}


- (void) didMoveToSuperview:(UIView *) newSuperview
{
   UIViewLog( "%#@", newSuperview);
}


- (void) willMoveToWindow:(id <UIWindow>) newWindow
{
}


- (void) didMoveToWindow:(id <UIWindow>) newWindow
{
   UIViewLog( "%#@", newWindow);
}


// this will be clobbered by UIWindow, to also add and remove
// UIViews to tracking areas
//
// If you change code here, also change it in UIView+UITrackingArea.m
// -setWindow:
//

- (void) setWindow:(id <UIWindow>) newWindow
{
   UIView   *view;

   if( _window == newWindow)
      return;

   [self willMoveToWindow:newWindow];
   {
      self->_window = newWindow;

      mulle_pointerarray_for( &_subviews, view)
         [view setWindow:newWindow];
   }
   [self didMoveToWindow:newWindow];
}


- (void) mulleAddRetainedSubview:(UIView *) view
{
   struct mulle_pointerarray  *subviews;

   assert( view);
   assert( view != self);
   assert( ! [view superview]);
   assert( [view isKindOfClass:[UIView class]]);

   subviews = [self _subviews];
//   index    = _mulle_pointerarray_find( subviews, view);
//   fprintf( stderr, "index of existing view: %llx\n", (long long) index);

   assert( _mulle_pointerarray_find( subviews, view) == mulle_not_found_e);

   [view willMoveToSuperview:self];
   {
      view->_superview = self;
      _mulle_pointerarray_add( subviews, view);

      [view setWindow:self->_window];
   }
   [view didMoveToSuperview:self];

   [self didAddSubview:view];
}


- (void) addSubview:(UIView *) view
{
   [self mulleAddRetainedSubview:[view retain]];
}


- (void) removeSubview:(UIView *) view
{
   NSUInteger   index;

   // nil will not be found, that's good
   index = mulle_pointerarray_find( &self->_subviews, view);
   if( index == NSNotFound)
      return;

   [view autorelease];
   [self willRemoveSubview:view];

   assert( view->_superview);
   [view willMoveToSuperview:nil];

   // ensure that index is constant and still findable
   view->_superview = nil;

   index = mulle_pointerarray_find( &self->_subviews, view);
   if( index != NSNotFound)
      mulle_pointerarray_remove_in_range( &_subviews,
                                          mulle_range_make( (unsigned int) index, 1));
   [view setWindow:nil];

   [view didMoveToSuperview:nil];
}


- (void) removeFromSuperview
{
   [_superview removeSubview:self];

   // lose original frame information here, as we are placed into
   // different surroundings (or not at all)
   _originalFrame.size.width    = 0.0;
   _lastBounds.size.width       = 0.0;
}


- (void) removeAllSubviews
{
   UIView    *view;

   while( (view = mulle_pointerarray_get_last( &_subviews)))
      [view removeFromSuperview];
}


/*
 *
 */
- (NSUInteger) subviewCount
{
   return( mulle_pointerarray_get_count( &_subviews));
}


- (NSInteger) getSubviews:(UIView **) buf
                    range:(NSRange) range
{
   NSUInteger   n;

   n = mulle_pointerarray_get_count( &_subviews);
   if( ! buf)
      return( n);
   if( range.location >= n)
      return( -1);

   if( range.length == -1)
      range.length = n - range.location;
   if( range.location + range.length > n)
      return( -1);

   mulle_pointerarray_copy_range( &_subviews, buf, range);

   return( n);
}


static int   UIViewCompareByOrigin( void **a, void **b, void *userinfo)
{
   CGRect   aFrame;
   CGRect   bFrame;

   aFrame = [*(UIView **) a frame];
   bFrame = [*(UIView **) b frame];

   if( aFrame.origin.y < bFrame.origin.y)
      return( -1);

   if( aFrame.origin.y != bFrame.origin.y)
      return( 1);

   if( aFrame.origin.x < bFrame.origin.x)
      return( -1);
   return( aFrame.origin.x != bFrame.origin.x);
}


- (void) sortSubviewsByOrigin
{
   mulle_pointerarray_qsort_r_inline( &_subviews, UIViewCompareByOrigin, NULL);
}



- (void) getSubviewsIntersectingRect:(CGRect) rect
                    intoPointerArray:(struct mulle_pointerarray *) array
              invertIntersectionTest:(BOOL) flag
{
   UIView   *view;

   flag = ! flag;
   mulle_pointerarray_for( &_subviews, view)
      if( CGRectIntersectsRect( [view frame], rect) == flag)
         mulle_pointerarray_add( array, view);
}


- (UIView *) subviewAtIndex:(NSUInteger) i
{
   UIView   *view;

   // TODO: // need to throw exception here

   view = mulle_pointerarray_get( &_subviews, (unsigned int) i);
   return( view);
}


- (UIView *) subviewWithTag:(NSInteger) tag
{
   UIView   *view;

   mulle_pointerarray_for( &_subviews, view)
      if( [view tag] == tag)
         break;

   return( view);
}


//
// this is deep, it only searches views contained as subviews
// "local" views like contentView, won't be found
//
- (UIView *) findSubviewWithTag:(NSInteger) tag;
{
   UIView   *view;

   mulle_pointerarray_for( &_subviews, view)
   {
      if( [view tag] == tag)
         break;
      view = [view findSubviewWithTag:tag];
      if( view)
         break;
   }

   return( view);
}


// maybe wrong name ?
- (void) setNeedsCaching  // wipes the _backinglayer and asks for a new one to be drawn
{
#ifdef HAVE_RENDER_CACHE
   // might have to do this atomically later on
   _needsCaching = YES;
   [_cacheLayer autorelease];
   _cacheLayer = nil;
#endif
}


- (void) setReuseIdentifierUTF8String:(char *) s
{
   MulleObjCObjectSetDuplicatedUTF8String( self, &_reuseIdentifierUTF8String, s);
}


- (char *) UTF8String
{
   char        *result;
   char        *s;
   auto char   buf[ 64];
   size_t      len;
   char        *format;
   char        *name;

   s = MulleObjCClassGetNameUTF8String( NSClassFromObject( self));
   sprintf( buf, "%p",  self);

   format = "<%s %s>";
   name   = [self debugNameUTF8String];
   len    = name ? strlen( name) : 0;
   if( len)
   {
      format = "<%s %s \"%s\">";
      len   += 3; // < "">\0"
   }
   len    += strlen( s) + strlen( buf) + 4; // < "">\0"
   result  = mulle_malloc( len);
   sprintf( result, format, s, buf, name);

   return( MulleObjCAutoreleaseAllocation( result, NULL));
}


- (char *) colorizerPrefixUTF8String
{
   char        *s;
   char        *result;
   uintptr_t   hash;
   int         color;

   // haques for UIWindow
   s = NULL;
   if( [self respondsToSelector:@selector( titleUTF8String)])
      s = [self titleUTF8String];

   if( ! s && _mainLayer)
      s = [_mainLayer debugNameUTF8String];

   if( s)
      hash = _mulle_string_hash( s);
   else
      hash  = mulle_pointer_hash( self);

   color  = (hash % (230 - 22)) + 22;
   mulle_asprintf( &result, "\033[38;5;%dm", color);;

   return( MulleObjCAutoreleaseAllocation( result, NULL));
}


- (id) prepareForReuse
{
   return( nil);
}


// TODO: need to add shadowLayer to t
#if 0
- (CGLayer *) cachedLayerWithFrameInfo:(struct CGFrameInfo *) info
{
   if( _needsCaching)
   {
#ifdef HAVE_RENDER_CACHE
      CGLayer   *layer;

      assert( _cacheLayer == nil);
      _needsCaching = NO;
      layer = [self textureImageWithContext:[(UIWindow *) [self window] context]
                                 frameInfo:info
                                    options:0];
      if( layer)
         _cacheLayer = [[CABitmapLayer alloc] initWithImage:image];
#endif
   }
   return( _cacheLayer);
}
#endif


- (void) willRenderWithAbsoluteTime:(mulle_absolutetime_t) time
{
}


- (UIView *) superview
{
   return( _superview);
}


# pragma mark - UILayer + forwarding

// ---
// UIView( UILayer)
// ---
- (id <UILayer>) mainLayer
{
   assert( _mainLayer);
   return( _mainLayer);
}


- (id <UILayer>) layer
{
   return( _mainLayer);
}


- (void) mulleAddRetainedLayer:(id <UILayer>) layer
{
   assert( layer);

   if( ! _mainLayer)
   {
      _mainLayer = layer;
      return;
   }
   assert(_mainLayer != layer);

   assert( _mulle_pointerarray_find( &_layers, layer) == mulle_not_found_e);
   _mulle_pointerarray_add( &_layers, layer);
}


- (void) addLayer:(id <UILayer>) layer
{
   [self mulleAddRetainedLayer:[layer retain]];
}


- (struct mulle_pointerarray *) _layers
{
   return( &_layers);
}


- (NSInteger) getLayers:(id <UILayer> *) buf
                  range:(NSRange) range
{
   NSUInteger   n;

   assert( MulleObjCRangeIsValid( range));

   if( ! buf)
      return( -1);

   if( ! _mainLayer)
      return( 0);

   // add _mainLayer to the counr
   n     = mulle_pointerarray_get_count( &_layers) + 1;
   range = MulleObjCRangeValidateAgainstLength( range, n);
   if( ! MulleObjCRangeIsValid( range))
      return( -1);

   if( range.location == 0)
   {
      *buf++        = _mainLayer;
      range.length -= 1;
   }

   mulle_pointerarray_copy_range( &_layers, buf, range);

   return( n);
}


- (void) removeLayer:(id <UILayer>) layer
{
   NSUInteger   index;

   if( ! layer)
      return;

   if( layer == _mainLayer)
   {
      // or assert that this is bad ?
      [_mainLayer autorelease];
      _mainLayer = nil;
      return;
   }

   // nil will not be found, that's good
   index = mulle_pointerarray_find( &self->_layers, layer);
   if( index == NSNotFound)
      return;

   [layer autorelease];
   mulle_pointerarray_remove_in_range( &_layers,
                                       mulle_range_make( (unsigned int) index, 1));
}


- (void) removeAllLayers
{
   id <UILayer>   layer;

   while( (layer = mulle_pointerarray_get_last( &_layers)))
      [self removeLayer:layer];
   [self removeLayer:_mainLayer];
}


- (BOOL) isMultiLayer
{
   return( mulle_pointerarray_get_count( &_layers) != 0);
}

//- (void) setNeedsDisplay
//{
//   _needsDisplay = YES;
//}


- (void *) forward:(void *) param
{
   assert( _mainLayer); // window should not forward...
   return( mulle_objc_object_call_variablemethodid_inline( _mainLayer,
                                                          (mulle_objc_methodid_t) _cmd,
                                                          param));
}


- (BOOL) respondsToSelector:(SEL) sel
{
   if( [super respondsToSelector:sel])
      return( YES);
   return( [_mainLayer respondsToSelector:sel]);
}



//// conveniences
//- (void) setBackgroundColor:(CGColor) color
//{
//   [_mainLayer setBackgroundColor:color];
//}
//
//- (void) setBorderColor:(CGColor) color
//{
//   return( [_mainLayer setBorderColor:color]);
//}
//
//- (void) setBorderWidth:(CGFloat) value
//{
//   [_mainLayer setBorderWidth:value];
//}
//
//- (void) setCornerRadius:(CGFloat) value
//{
//   return( [_mainLayer setCornerRadius:value]);
//}
//
//
//- (CGColor) backgroundColor
//{
//   return( [_mainLayer backgroundColor]);
//}
//
//- (CGColor) borderColor
//{
//   return( [_mainLayer borderColor]);
//}
//
//- (CGFloat) borderWidth
//{
//   return( [_mainLayer borderWidth]);
//}
//
//- (CGFloat) cornerRadius
//{
//   return( [_mainLayer cornerRadius]);
//}
//

// Done by Yoga
// - (void) setNeedsLayout
// {
//    _needsLayout = YES;
// }

- (char *) debugNameUTF8String
{
   return( _debugNameUTF8String);
}


- (void) setDebugNameUTF8String:(char *) s
{
   MulleObjCObjectSetDuplicatedUTF8String( self, &_debugNameUTF8String, s);
}


@end



@implementation UINullLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   _frame       = frame;
   _bounds.size = frame.size;
   return( self);
}


- (void) dealloc 
{
   MulleObjCObjectSetDuplicatedUTF8String( self, &_debugNameUTF8String, NULL);
   [super dealloc];
}


- (char *) debugNameUTF8String
{
   return( _debugNameUTF8String);
}


- (void) setDebugNameUTF8String:(char *) s
{
   MulleObjCObjectSetDuplicatedUTF8String( self, &_debugNameUTF8String, s);
}


- (CGSize) sizeThatFits:(CGSize) size
                context:(id <UILayoutContext>) context
{
   return( size);
}

@end


