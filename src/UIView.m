#import "UIView.h"

#import "import-private.h"


@implementation NSObject ( UIView)

- (BOOL) __isUIView
{
   return( NO);
}

@end

//#define RENDER_DEBUG
//#define RENDER_VERBOSE_DEBUG
//#define HAVE_RENDER_CACHE

static UIEvent   *defaultHandleEventCallback( UIView *view, UIEvent *event)
{
   return( event);
}


@implementation UIView

- (BOOL) __isUIView
{
   return( YES);
}



+ (instancetype) viewWithFrame:(CGRect) frame
{
   return( [[[self alloc] initWithFrame:frame] autorelease]);
}


+ (instancetype) viewWithLayer:(id <UILayer>) layer
{
   return( [[[self alloc] initWithLayer:layer] autorelease]);
}


// designated initializer
- (instancetype) initWithLayer:(id <UILayer>) layer
                         frame:(CGRect) frame
{
   CGRect   frame;

   assert( ! layer || [layer conformsToProtocol:@protocol( UILayer)]);

   if( ! layer)
   {
      [self release];
      return( nil);
   }

   _mainLayer              = [layer retain];
   _clipsToBounds          = YES;  // default
   _userInteractionEnabled = YES;  // default
   _alpha                  = 1.0;
   _bounds.size.width      = INFINITY; // once we change the bounds size
                                       // we disconnect from frame.size
   _frame                  = frame;
   _eventCallback          = defaultHandleEventCallback;

//   _needsDisplay           = YES;

   return( self);
}


- (instancetype) initWithFrame:(CGRect) frame
{
   id <UILayer>   layer;
   Class          cls;
   CGRect         rect;

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
   [layer setFrame:CGRectMake( 0.0f, 0.0f, frame.size.width, frame.size.height)];

   return( [self initWithLayer:layer
                         frame:frame]);
}


- (void) dealloc
{
   UITrackingAreaArrayDone( &_trackingAreas);

   mulle_pointerarray_release_all( _subviews);
   mulle_pointerarray_destroy( _subviews);

   mulle_pointerarray_release_all( _layers);
   mulle_pointerarray_destroy( _layers);

   [_cacheLayer release];
   [_mainLayer release];

   [super dealloc];
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


//
// for layers bounds are inherited directly, so the layer "sticks"
// (and need to be panned by its bounds)
//
- (CGRect) bounds
{
   return( getBounds( self));
}


// will be overridden later
- (void) willChange
{
}


- (void) setBounds:(CGRect) bounds
{
   [self willChange];

   _bounds.origin = bounds.origin;
   if( CGSizeEqualToSize( _frame.size, bounds.size))
      _bounds.size.width = INFINITY;
   else
      _bounds.size = bounds.size;
}


- (CGRect) contentRect
{
   CGRect  rect;

   rect.origin = CGPointMake( 0.0f, 0.0f);
   rect.size   = getBounds( self).size;
   return( rect);
}


- (CGRect) layoutRect
{
   CGRect   bounds;

   bounds = [self contentRect];
   bounds = UIEdgeInsetsInsetRect( bounds, _padding);
   return( bounds);
}

- (void) setEventCallback:(UIEvent *(*)(UIView *, UIEvent *)) callback
{
   if( ! callback)
      callback = defaultHandleEventCallback;
   _eventCallback = callback;
}

//
//
//
- (struct mulle_pointerarray *) _subviews
{
   struct mulle_allocator   *allocator;

   if( ! _subviews)
   {
      allocator = MulleObjCInstanceGetAllocator( self);
      _subviews = mulle_pointerarray_alloc( allocator);
      _mulle_pointerarray_init( _subviews, 4, allocator);
   }
   return( _subviews);
}


- (void) mulleAddRetainedSubview:(UIView *) view
{
   struct mulle_pointerarray  *subviews;
   uintptr_t                  index;

   assert( view);
   assert( view != self);
   assert( ! [view superview]);
   assert( [view isKindOfClass:[UIView class]]);

   subviews = [self _subviews];
   index    = _mulle_pointerarray_find( subviews, view);
//   fprintf( stderr, "index of existing view: %llx\n", (long long) index);

   assert( _mulle_pointerarray_find( subviews, view) == mulle_not_found_e);
   _mulle_pointerarray_add( subviews, view);

   view->_superview = self;
}


- (void) addSubview:(UIView *) view
{
   [self mulleAddRetainedSubview:[view retain]];
}


- (NSUInteger) subviewCount
{
   return( _subviews ? mulle_pointerarray_get_count( _subviews) : 0);
}


- (NSInteger) getSubviews:(UIView **) buf
                    range:(NSRange) range
{
   NSUInteger   n;

   if( ! buf)
      return( -1);

   n = mulle_pointerarray_get_count( _subviews);
   if( range.location + range.length > n)
      return( -1);

   mulle_pointerarray_copy_range( _subviews, buf, range);

   return( n);
}

//
// TODO: use some other data structure, not pointerarray ?
//
- (void) setSubviews:(struct mulle_pointerarray *) array
{
   struct mulle_allocator   *allocator;

   if( array == self->_subviews)
      return;

   if( ! array)
   {
      mulle_pointerarray_release_all( _subviews);
      mulle_pointerarray_destroy( _subviews);
      _subviews = NULL;
      return;
   }

   allocator = MulleObjCInstanceGetAllocator( self);
   assert( _mulle_pointerarray_get_allocator( array) == allocator);

   /* retain/release */
   mulle_pointerarray_retain_all( array);

   if( ! _subviews)
      _subviews = mulle_pointerarray_alloc( allocator);
   else
   {
      mulle_pointerarray_release_all( _subviews);
      _mulle_pointerarray_done( _subviews);   // but don't free
   }

   // transfer objects
   memcpy( _subviews, array, sizeof( struct mulle_pointerarray));
   // make sure these aren't reused by array anymore
   _mulle_pointerarray_init( array, 0, allocator);
}


- (void) getSubviewsIntersectingRect:(CGRect) rect
                      intoPointerArray:(struct mulle_pointerarray *) array
              invertIntersectionTest:(BOOL) flag
{
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;

   flag = ! flag;
   rover = mulle_pointerarray_enumerate( _subviews);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
      if( CGRectIntersectsRect( [view frame], rect) == flag)
         mulle_pointerarray_add( array, view);
   mulle_pointerarrayenumerator_done( &rover);
}


- (UIView *) subviewWithTag:(NSInteger) tag
{
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;

   rover = mulle_pointerarray_enumerate( _subviews);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
      if( [view tag] == tag)
         break;
   mulle_pointerarrayenumerator_done( &rover);

   return( view);
}

//
// this is deep, it only searches views contained as subviews
// "local" views like contentView, won't be found
//
- (UIView *) findSubviewWithTag:(NSInteger) tag;
{
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;

   rover = mulle_pointerarray_enumerate( _subviews);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
   {
      if( [view tag] == tag)
         break;
      view = [view findSubviewWithTag:tag];
      if( view)
         break;
   }
   mulle_pointerarrayenumerator_done( &rover);

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
   name   = [_mainLayer debugNameUTF8String];
   len    = name ? strlen( name) : 0;
   if( len)
   {
      format = "<%s %s \"%s\">";
      len   += 3; // < "">\0"
   }
   len    += strlen( s) + strlen( buf) + 4; // < "">\0"
   result  = mulle_malloc( len);
   sprintf( result, format, s, buf, name);
   MulleObjCAutoreleaseAllocation( result, NULL);

   return( result);
}


- (char *) colorizedUTF8StringHeader
{
   char        *s;
   char        *result;
   uintptr_t   hash;
   int         color;

   // haques for UIWindow
   s = nil;
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
   MulleObjCAutoreleaseAllocation( result, NULL);

   return( result);
}


#if 0
- (CGLayer *) cachedLayerWithFrameInfo:(struct CGFrameInfo *) info
{
   if( _needsCaching)
   {
#ifdef HAVE_RENDER_CACHE
      CGLayer   *layer;

      assert( _cacheLayer == nil);
      _needsCaching = NO;
      layer = [self textureImageWithContext:[[self window] context]
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

   if( ! _layers)
      _layers = mulle_pointerarray_create( NULL);

   assert( _mulle_pointerarray_find( _layers, layer) == mulle_not_found_e);
   _mulle_pointerarray_add( _layers, layer);
}


- (void) addLayer:(id <UILayer>) layer
{
   [self mulleAddRetainedLayer:[layer retain]];
}


- (struct mulle_pointerarray *) _layers
{
   struct mulle_allocator   *allocator;

   if( ! _layers)
   {
      allocator = MulleObjCInstanceGetAllocator( self);
      _layers = mulle_pointerarray_alloc( allocator);
      _mulle_pointerarray_init( _layers, 4, allocator);
   }
   return( _layers);
}


- (NSInteger) getLayers:(id <UILayer> *) buf
                  range:(NSRange) range
{
   NSUInteger   n;

   if( ! buf)
      return( -1);

   if( ! _mainLayer)
      return( 0);

   n  = 1;
   n += mulle_pointerarray_get_count( _layers);

   if( range.location + range.length > n)
      return( -1);

   mulle_pointerarray_copy_range( _layers, buf, range);

   buf[ n - 1] = _mainLayer; // why last ?

   return( n);
}


- (BOOL) isMultiLayer
{
   return( _layers != NULL);
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



# pragma mark - tracking rectangles

// adding/removing tracking rectangles is done in UIView+UIWindow.m

- (NSUInteger) numberOfTrackingAreas
{
   return( UITrackingAreaArrayGetCount( &_trackingAreas));
}


- (struct UITrackingArea *) trackingAreaAtIndex:(NSUInteger) i
{
   struct UITrackingArea   *item;

   item = UITrackingAreaArrayGetItemAtIndex( &_trackingAreas, i);
   return( item);
}


- (BOOL) mulleIsEffectivelyHidden  // recursive test the hierarchy up
{
   UIView   *p;

   p = self;
   for(;;)
   {
      if( p->_hidden)
         return( YES);
      p = p->_superview;
      if( ! p)
         return( NO);
   }
}

@end
