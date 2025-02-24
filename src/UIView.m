#import "UIView.h"

#import "import-private.h"

#import "UIView+DebugPrivate.h"
#import "UIViewController.h"


#define DUMP_LAYERS


@interface UIView( Forward)

- (void) willChange;

@end


@interface NSObject( Forward)

- (char *) titleUTF8String;

@end


@implementation NSObject ( UIView)

- (BOOL) __isUILayer
{
   return( NO);
}

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


static struct
{
   NSUInteger   _debuggingFlags;
} Self;


+ (void) initialize
{
   char   *s;

   // don't rerun for subclass
   if( MulleObjCClassGetID( self) != @selector( UIView))
      return;

   s = getenv( MULLE_C_STRINGIFY( UIView) "DebuggingFlags");
   if( ! s)
      s = getenv( "UIResponderDebuggingFlags");
   if( ! s)
      s = getenv( "UIDebuggingFlags");
   if( s)
      Self._debuggingFlags = strtol( s, NULL, 0);
}


+ (void) deinitialize
{
}


+ (void) setDebuggingFlags:(NSUInteger) flag   MULLE_OBJC_THREADSAFE_METHOD
{
   Self._debuggingFlags = flag;
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


- (void) mulleGainAccess
{
   UIView        *subview;
   id <UILayer>  layer;
   id            area;

   [super mulleGainAccess];

   // we would lose this
   assert( ! self->_snapshot);
   assert( ! self->_animationStorage);

   [_mainLayer mulleGainAccess];
   [_cacheLayer mulleGainAccess];
   [_shadowLayer mulleGainAccess];

   mulle_pointerarray_for( &_layers, layer)
   {
      [layer mulleGainAccess];
   }

   mulle_pointerarray_for( &_trackingAreas, area)
   {
      [area mulleGainAccess];
   }

   UIViewSubviewsFor( self, subview)
   {
      [subview mulleGainAccess];
   }
}


// reverse order for no good reason, except that it looks prettier :)
- (void) mulleRelinquishAccess
{
   UIView        *subview;
   id <UILayer>  layer;
   id            area;

   assert( ! self->_snapshot);
   assert( ! self->_animationStorage);

   UIViewSubviewsFor( self, subview)
   {
      [subview mulleRelinquishAccess];
   }

   mulle_pointerarray_for( &_trackingAreas, area)
   {
      [area mulleRelinquishAccess];
   }

   mulle_pointerarray_for( &_layers, layer)
   {
      [layer mulleRelinquishAccess];
   }

   [_shadowLayer mulleRelinquishAccess];
   [_cacheLayer mulleRelinquishAccess];
   [_mainLayer mulleRelinquishAccess];

   [super mulleRelinquishAccess];
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

   if( ! layer)
   {
      [self release];
      return( nil);
   }

   assert( [layer conformsToProtocol:@protocol( UILayer)]);

   self       = [super initNoLock];
   _mainLayer = [layer retain];
   _frame     = UIViewMakeFrameWithRect( frame);

   [self resetForInit];

#ifdef UIVIEW_DEBUGGING_FLAGS
   _debuggingFlags = UIVIEW_DEBUGGING_FLAGS;
#else
   _debuggingFlags = Self._debuggingFlags;
#endif

   UIViewLayoutLog( "frame %s", CGRectUTF8String( _frame));

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

   frame    = UIViewMakeFrameWithRect( frame);
   rect     = CGRectMake( 0.0f, 0.0f, frame.size.width, frame.size.height);
   cls      = [[self class] layerClass];
   layer    = [cls alloc];
   layer    = [layer initWithFrame:rect];
   layer    = [layer autorelease];
#if 0
   // some layers correct the frame
   if( frame.size.width == 0.0 || isinf( frame.size.width))
      frame.size.width = [layer frame].size.width;
   if( frame.size.height == 0.0 || isinf( frame.size.height))
      frame.size.height = [layer frame].size.height;
#endif
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

   [_hoverTimer mullePerformFinalize];
   [_hoverTimer autorelease];
   _hoverTimer = nil;

   // finalize it all, assume that the context where layers or views can
   // properly releave themselves will already be gone in -dealloc

   [_cacheLayer mullePerformFinalize];
   [_cacheLayer autorelease];
   _cacheLayer = nil;

   mulle_idarray_call_all( &_trackingAreas, @selector( mullePerformFinalize), NULL);
   mulle_idarray_call_all( &_subviews, @selector( mullePerformFinalize), NULL);
   mulle_idarray_call_all( &_layers, @selector( mullePerformFinalize), NULL);

   [_shadowLayer mullePerformFinalize];
   [_mainLayer mullePerformFinalize];

   [super finalize];
}


- (void) dealloc
{
   mulle_idarray_release_all( &_trackingAreas);
   mulle_pointerarray_done( &_trackingAreas);

   mulle_idarray_release_all( &_subviews);
   mulle_pointerarray_done( &_subviews);

   mulle_idarray_release_all( &_layers);
   mulle_pointerarray_done( &_layers);

   [_shadowLayer release];
   [_mainLayer release];

   MulleObjCObjectSetDuplicatedUTF8String( self, &_debugNameUTF8String, NULL);

   [super dealloc];
}


// - (id) mutableCopy
// {
//    abort();
// 
//    UIView                   *copy;
//    struct mulle_allocator   *allocator;
//    //
//    // MEMO: if we init a new instance of the same class and call
//    //       initWithLayer on it, we are likely to get populated with fresh
//    //       layers and subviews by the subclass.
//    //       This is not what we want though, as we want to copy as much state
//    //       as possible.
//    //       Instead lets make a [super copy] first and then
//    //       copy all the stuff we can copy and free/nil/reinit that what
//    //       can not be copied. The subclass then must do the rest.
//    //
//    copy = [super mutableCopy];
//    {
//       allocator          = MulleObjCInstanceGetAllocator( copy);
// 
//       copy->_mainLayer   = [copy->_mainLayer mutableCopy];
//       copy->_shadowLayer = [copy->_shadowLayer mutableCopy];
//       copy->_cacheLayer  = [copy->_cacheLayer retain]; // why not ?
// 
//       mulle_pointerarray_init( &copy->_layers, mulle_pointerarray_get_count( &self->_layers), allocator);
//       mulle_pointerarray_add_array( &copy->_layers, &self->_layers, mulle_range_make_all());
//       mulle_idarray_mutablecopy_all( &copy->_layers);
// 
//       mulle_pointerarray_init( &copy->_subviews, mulle_pointerarray_get_count( &self->_subviews), allocator);
//       mulle_pointerarray_add_array( &copy->_subviews, &self->_subviews, mulle_range_make_all());
//       mulle_idarray_mutablecopy_all( &copy->_subviews);
// 
//       // tracking areas do not have NSCopying!
//       mulle_pointerarray_init( &copy->_trackingAreas, 0, allocator);
// 
//       // a clever compiler might have it easier here due to consecutive offsets
//       copy->_debugNameUTF8String  = NULL;
//       copy->_superview            = nil;
//       copy->_snapshot             = nil;
//       copy->_animationStorage     = NULL;
// 
//       copy->_window               = nil;
//    }
//    return( copy);
// }

//
// UIViews and CALayers of a view hierarchy share a common recursive lock
//
// When this lock changes, this needs to propagate down to subviews and layers
//
- (void) didShareRecursiveLock:(NSRecursiveLock *) lock
{
   UIView                  *view;
   MulleObject <UILayer>   *layer;

   UIViewSubviewsFor( self, view)
   {
      [view shareRecursiveLock:lock];
   }

   [(MulleObject <UILayer> *) _mainLayer shareRecursiveLock:lock];

   mulle_pointerarray_for( &_layers, layer)
   {
      [(MulleObject <UILayer> *) layer shareRecursiveLock:lock];
   }

   // do this first or last ... maybe depending on lock being nil or not ?
   [super didShareRecursiveLock:lock];
}


//
// FRAME AND BOUNDS
//

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

   UIViewLayoutLog( "bounds %s -> %s", CGRectUTF8String( _bounds), CGRectUTF8String( bounds));

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
   CGContentModeAssert( mask & UIViewAutoresizingContentModeBits);

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
   _mouseMotionEventCallback = callback ? callback : defaultHandleMouseMotionEventCallback;
}


- (void) setEventCallback:(UIEvent *(*)(UIView *, UIEvent *)) callback
{
   _eventCallback = callback ? callback : defaultHandleEventCallback;
}


// return NO, if default layoutSubviews code should not run
- (void) setWillLayoutSubviewsCallback:(BOOL (*)( UIView *)) callback
{
   _willLayoutSubviewsCallback = callback ? callback : defaultYESCallback;
}


- (void) setDidLayoutSubviewsCallback:(BOOL (*)( UIView *)) callback
{
   _didLayoutSubviewsCallback = callback ? callback : defaultYESCallback;
}


- (void) setWillLayoutLayersCallback:(BOOL (*)( UIView *)) callback
{
   _willLayoutLayersCallback = callback ? callback : defaultYESCallback;
}


- (void) setDidLayoutLayersCallback:(void (*)( UIView *)) callback
{
   _didLayoutLayersCallback = callback ? callback : defaultVoidCallback;
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
   [_controller view:self
     didMoveToWindow:newWindow];
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

      UIViewSubviewsFor( self, view)
      {
         [view setWindow:newWindow];
      }
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
      [view shareRecursiveLockWithObject:self];
   }
   [view didMoveToSuperview:self];

   [self didAddSubview:view];
}


- (void) addToSubviews:(UIView *) view
{
   [self mulleAddRetainedSubview:[view retain]];
}


//
// .. and sets its next responder to the receiver, which is its new superview.
// we don't have a nextResponder ivar though...
//
- (void) addSubview:(UIView *) view
{
   [self mulleAddRetainedSubview:[view retain]];
}


- (void) removeFromSubviews:(UIView *) view
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
   [view shareRecursiveLockWithObject:nil];

   [view didMoveToSuperview:nil];
}


- (void) removeSubview:(UIView *) view
{
   [self removeFromSubviews:view];
}



- (void) removeFromSuperview
{
   [_superview removeFromSubviews:self];

   // lose original frame information here, as we are placed into
   // different surroundings (or not at all)
   _originalFrame.size.width    = 0.0;
   _lastBounds.size.width       = 0.0;
}


- (void) removeAllSubviews
{
   UIView   *view;

   while( (view = mulle_pointerarray_get_last( &_subviews)))
      [view removeFromSuperview];
}


- (void) removeAllSubviewsOfClass:(Class) cls
{
   struct mulle_pointerarray   tmp;
   UIView                      *view;

   memcpy( &tmp, &_subviews, sizeof( tmp));
   mulle_pointerarray_init( &self->_subviews,
                            mulle_pointerarray_get_count( &self->_subviews),
                            mulle_pointerarray_get_allocator( &self->_subviews));

   mulle_pointerarray_for( &tmp, view)
   {
      if( [view isKindOfClass:cls])
         mulle_pointerarray_add( &_subviews, view);
      else
         [view removeFromSuperview];
   }
}


/*
 *
 */
- (NSUInteger) numberOfSubviews
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

   mulle_idarray_get_in_range( &_subviews, buf, range);

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
   UIViewSubviewsFor( self, view)
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


//
// direct access to make it snappier
//
- (UIView *) subviewWithTag:(NSInteger) tag
{
   UIView   *view;

   UIViewSubviewsFor( self, view)
      if( view->_tag == tag)
         break;

   return( view);
}


//
// this is deep, it only searches views contained as subviews.
// "local" views like maybe a -contentView, if its not also in the usual
// view hierarchy, won't be found
//
- (UIView *) findViewWithTag:(NSInteger) tag;
{
   UIView   *view;

   UIViewSubviewsFor( self, view)
   {
      if( view->_tag == tag)
         break;
   }

   if( ! view)
   {
      UIViewSubviewsFor( self, view)
      {
         view = [view findViewWithTag:tag];
         if( view)
            break;
      }
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
      hash = mulle_pointer_hash( self);

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
- (CGFramebuffer *) cachedLayerWithFrameInfo:(struct CGFrameInfo *) info
{
   if( _needsCaching)
   {
#ifdef HAVE_RENDER_CACHE
      CGFramebuffer   *layer;

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


- (UIWindowDisplayBits) willRenderWithAbsoluteTime:(mulle_absolutetime_t) time
{
   return( 0);
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
   assert( _mainLayer);
   return( _mainLayer);
}


- (void) mulleAddRetainedLayer:(id <UILayer>) layer
{
   assert( layer);

   if( ! _mainLayer)
   {
      _mainLayer = layer;
   }
   else
   {
      assert(_mainLayer != layer);

      assert( _mulle_pointerarray_find( &_layers, layer) == mulle_not_found_e);
      _mulle_pointerarray_add( &_layers, layer);
   }
   [(MulleObject <UILayer> *) layer shareRecursiveLockWithObject:self];
}


- (void) addLayer:(id <UILayer>) layer
{
   [self mulleAddRetainedLayer:[layer retain]];
}


- (struct mulle_pointerarray *) _layers
{
   return( &_layers);
}


- (id <UILayer>) layerWithTag:(NSInteger) tag
{
   id <UILayer>   layer;

   mulle_pointerarray_for( &_layers, layer)
   {
      if( [layer tag] == tag)
         break;
   }

   if( ! layer && [_mainLayer tag] == tag)
      layer = _mainLayer;
   return( layer);
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

   mulle_idarray_get_in_range( &_layers, buf, range);

   return( n);
}


- (void) removeLayer:(id <UILayer>) layer
{
   NSUInteger   index;

   if( layer == _mainLayer)
   {
      _mainLayer = nil;
   }
   else
   {
      // nil will not be found, that's good
      index = mulle_pointerarray_find( &self->_layers, layer);
      if( index == NSNotFound)
         return;

      mulle_pointerarray_remove_in_range( &_layers,
                                          mulle_range_make( (unsigned int) index, 1));
   }

   [layer autorelease];
   [(MulleObject <UILayer> *) layer shareRecursiveLockWithObject:nil];
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
   return( mulle_objc_object_call_variable_inline( _mainLayer,
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


- (void) dumpSubviewsWithIndent:(NSUInteger) indent
                           FILE:(FILE *) fp
{
   UIView   *view;

   UIViewSubviewsFor( self, view)
   {
      [view dumpWithIndent:indent
                      FILE:fp];
   }
}


- (void) dumpLayersWithIndent:(NSUInteger) indent
                         FILE:(FILE *) fp
{
   id <UILayer>   layer;

   UIViewLayersFor( self, layer)
   {
      [layer dumpWithIndent:indent
                       FILE:fp];
   }
}


- (void) dumpTrackingAreasWithIndent:(NSUInteger) indent
                                FILE:(FILE *) fp
{
   id   area;

   UIViewTrackingAreasFor( &_trackingAreas, area)
   {
      [area dumpWithIndent:indent
                      FILE:fp];
   }
}


- (void) dumpViewWithIndent:(NSUInteger) indent
                       FILE:(FILE *) fp
{
   NSUInteger   i;
   char         *s;

   for( i = 0; i < indent; i++)
      fputc( ' ', fp);

   if( [self isHidden])
      fprintf( fp, "%s: hidden\n",
                  [self UTF8String]);
   else
   {
      fprintf( fp, "%s: f=[%s] b=[%s]",
                  [self UTF8String],
                  CGRectUTF8String( [self frame]),
                  CGRectUTF8String( [self bounds]));
      if( [self clipsToBounds])
         fprintf ( fp, " clips");
      if( [self isUserInteractionEnabled])
         fprintf ( fp, " interactive");

      s = UIViewAutoresizingMaskShortUTF8String( [self autoresizingMask]);
      if( *s)
         fprintf ( fp, " %s", s);

      fprintf( fp, "\n");
   }
}


- (void) dumpWithIndent:(NSUInteger) indent
                   FILE:(FILE *) fp
{
   [self dumpViewWithIndent:indent
                       FILE:fp];
   [self dumpTrackingAreasWithIndent:indent + 3
                                FILE:fp];
   [self dumpLayersWithIndent:indent + 3
                         FILE:fp];

//   if( _yoga)
//   {
//      fprintf( fp, "%s\n", [[_yoga debugDescription] UTF8String]);
//   }
   [self dumpSubviewsWithIndent:indent + 3
                           FILE:fp];
}


- (void) dump
{
   [self dumpWithIndent:0
                   FILE:mulleui_log_fp];
   fflush( mulleui_log_fp);
}


#ifdef DEBUG

void  UIViewDumpLayers( UIView *self)
{
   mulle_buffer_do_FILE( buffer, stdout)
   {
      mulle_buffer_sprintf( buffer, "mainLayer : %p\n", self->_mainLayer);
      if( mulle_pointerarray_get_count( &self->_layers))
      {
         mulle_buffer_add_string( buffer, "\nlayers : ");
         mulle_pointerarray_describe_buffer( &self->_layers, buffer);
      }
   }
   fflush( stdout);
}


void  UIViewDumpSubviews( UIView *self)
{
   mulle_buffer_do_FILE( buffer, stdout)
   {
      mulle_pointerarray_describe_buffer( &self->_subviews, buffer);
   }
   fflush( stdout);
}


void  UIViewDumpTrackingAreas( UIView *self)
{
   char   *s;

   mulle_buffer_do_FILE( buffer, stdout)
   {
      // written this way to have mulle_pointerarray_describe linked also for
      // debugging purposes
      s = mulle_pointerarray_describe( &self->_trackingAreas);
      mulle_buffer_add_string( buffer, s);
      mulle_free( s);
   }
   fflush( stdout);
}
#endif

@end



@implementation UINullLayer

- (void) willChange
{
   // ignore
}

- (instancetype) initWithFrame:(CGRect) frame
{
   _frame       = frame;
   _bounds.size = frame.size;

   return( self);
}


- (instancetype) initWithFrame:(CGRect) frame
                      OSWindow:(id <UIOSWindow>) osWindow
{
   return( [self initWithFrame:frame]);
}


- (void) dealloc 
{
   MulleObjCObjectSetDuplicatedUTF8String( self, &_debugNameUTF8String, NULL);
   [super dealloc];
}


- (void) forgetImplicitAnimations
{
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


- (void) dumpWithIndent:(NSUInteger) indent
                   FILE:(FILE *) fp
{
   NSUInteger   i;

   for( i = 0; i < indent; i++)
      fputc( ' ', fp);

   fprintf( fp, "%s: frame=[%s] bounds=[%s]",
               [self UTF8String],
               CGRectUTF8String( [self frame]),
               CGRectUTF8String( [self bounds]));
   fprintf( fp, "\n");
}


@end
