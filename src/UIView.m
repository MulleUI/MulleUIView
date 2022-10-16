#import "UIView.h"

#import "import-private.h"



// TODO: make NS_OPTIONS print
static char  *UIViewAutoresizingUTF8String( NSUInteger bit)
{
   switch( bit)
   {
   case UIViewAutoresizingNone            : return( "UIViewAutoresizingNone");
   case UIViewAutoresizingFlexibleWidth   : return( "UIViewAutoresizingFlexibleWidth");
   case UIViewAutoresizingFlexibleHeight  : return( "UIViewAutoresizingFlexibleHeight");
   case UIViewAutoresizingStickToTop      : return( "UIViewAutoresizingStickToTop");
   case UIViewAutoresizingStickToBottom   : return( "UIViewAutoresizingStickToBottom");
   case UIViewAutoresizingStickToLeft     : return( "UIViewAutoresizingStickToLeft");
   case UIViewAutoresizingStickToRight    : return( "UIViewAutoresizingStickToRight");
   case UIViewAutoresizingClipToBounds    : return( "UIViewAutoresizingClipToBounds");
   case UIViewAutoresizingCullAtBounds    : return( "UIViewAutoresizingCullAtBounds");
   }
   return( "???");
}


static char  UIViewAutoresizingUTF8Character( NSUInteger bit)
{
   switch( bit)
   {
   case UIViewAutoresizingNone            : return( '0');
   case UIViewAutoresizingFlexibleWidth   : return( 'w');
   case UIViewAutoresizingFlexibleHeight  : return( 'h');
   case UIViewAutoresizingStickToTop      : return( 't');
   case UIViewAutoresizingStickToBottom   : return( 'b');
   case UIViewAutoresizingStickToLeft     : return( 'l');
   case UIViewAutoresizingStickToRight    : return( 'r');
   case UIViewAutoresizingClipToBounds    : return( 'c');
   case UIViewAutoresizingCullAtBounds    : return( 'C');
   }
   return( '?');
}


static NSUInteger  UIViewAutoresizingBits[] =
{
   // internal state, can't be set
   UIViewAutoresizingFlexibleWidth,    // animation active, but possibly delayed
   UIViewAutoresizingFlexibleHeight,   // passed delay, now doing something
   UIViewAutoresizingStickToTop,       // future
   UIViewAutoresizingStickToBottom,
   UIViewAutoresizingStickToLeft,
   UIViewAutoresizingStickToRight,     // signal preemption

   // user options
   UIViewAutoresizingClipToBounds,
   UIViewAutoresizingCullAtBounds
};


char   *UIViewAutoresizingMaskShortUTF8String( NSUInteger bits)
{
   struct mulle_buffer   buffer;
   char                  *s;
   NSUInteger            i;
   char                  c;

   mulle_buffer_init( &buffer, NULL);

   for( i = 0; i < sizeof( UIViewAutoresizingBits) / sizeof( NSUInteger); i++)
   {
      if( bits & UIViewAutoresizingBits[ i])
      {
         c = UIViewAutoresizingUTF8Character( UIViewAutoresizingBits[ i]);
         mulle_buffer_add_byte( &buffer, c);
      }
   }

   s = mulle_buffer_extract_string( &buffer);
   mulle_buffer_done( &buffer);

   return( MulleObjCAutoreleaseAllocation( s, NULL));
}


char   *UIViewAutoresizingMaskUTF8String( NSUInteger bits)
{
   struct mulle_buffer   buffer;
   char                  *s;
   NSUInteger            i;

   mulle_buffer_init( &buffer, NULL);

   for( i = 0; i < sizeof( UIViewAutoresizingBits) / sizeof( NSUInteger); i++)
   {
      if( bits & UIViewAutoresizingBits[ i])
      {
         mulle_buffer_add_string_if_not_empty( &buffer, "|");
         mulle_buffer_add_string( &buffer, UIViewAutoresizingUTF8String( UIViewAutoresizingBits[ i]));
      }
   }

   mulle_buffer_add_string_if_empty( &buffer, "UIViewAutoresizingNone");

   s = mulle_buffer_extract_string( &buffer);
   mulle_buffer_done( &buffer);

   return( MulleObjCAutoreleaseAllocation( s, NULL));
}




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
   CGRect                   frame;
   struct mulle_allocator   *allocator;

   assert( ! layer || [layer conformsToProtocol:@protocol( UILayer)]);

   if( ! layer)
   {
      [self release];
      return( nil);
   }

   _mainLayer               = [layer retain];
   _clipsToBounds           = YES;  // default
   _userInteractionEnabled  = YES;  // default
   _alpha                   = 1.0;
   _bounds.size.width       = INFINITY; // once we change the bounds size
                                       // we disconnect from frame.size
#ifdef UIVIEW_FRAME_USES_CGRECTINTEGRAL   
   frame                    = CGRectIntegral( frame);
#endif   
   _frame                   = frame;
   _eventCallback           = defaultHandleEventCallback;
   _needsTrackingAreaUpdate = YES;
//   _needsDisplay           = YES;

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

#ifdef UIVIEW_FRAME_USES_CGRECTINTEGRAL   
   frame = CGRectIntegral( frame);
#endif   
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
#ifdef UIVIEW_FRAME_USES_CGRECTINTEGRAL   
   frame = CGRectIntegral( frame);
#endif   
   [layer setFrame:CGRectMake( 0.0f, 0.0f, frame.size.width, frame.size.height)];

   return( [self initWithLayer:layer
                         frame:frame]);
}


- (void) dealloc
{
   mulle_pointerarray_release_all( &_trackingAreas);
   mulle_pointerarray_done( &_trackingAreas);

   mulle_pointerarray_release_all( &_subviews);
   mulle_pointerarray_done( &_subviews);

   mulle_pointerarray_release_all( &_layers);
   mulle_pointerarray_done( &_layers);

   [_cacheLayer release];
   [_mainLayer release];

   [super dealloc];
}


- (id) copy 
{
   UIView         *copy;
   id <UILayer>   layer;
   UIView         *subview;

   layer = [[_mainLayer copy] autorelease];
   copy  = [[[self class] alloc] initWithLayer:layer];
   {
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



+ (Class) layerClass
{
   return( [UINullLayer class]);
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


- (void) setFrame:(CGRect) frame
{
   [self willChange];

#ifdef UIVIEW_FRAME_USES_CGRECTINTEGRAL   
   _frame = CGRectIntegral( frame);
#else
   _frame = frame;
#endif
   _needsTrackingAreaUpdate = YES;
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
   return( &_subviews);
}


- (void) didAddSubview:(UIView *) view
{
}


- (void) willRemoveSubview:(UIView *) subview
{
}


- (void) willMoveToSuperview:(UIView *) newSuperview
{
}


- (void) didMoveToSuperview:(UIView *) newSuperview
{
}


- (void) willMoveToWindow:(id <UIWindow>) newWindow
{
}


- (void) didMoveToWindow:(id <UIWindow>) newWindow
{
}


- (void) setWindow:(id <UIWindow>) newWindow
{
   UIView   *view;

   if( _window == newWindow)
      return;

   [self willMoveToWindow:newWindow];
   self->_window = newWindow;

   mulle_pointerarray_for( &_subviews, view)
      [view setWindow:newWindow];

   [self didMoveToWindow:newWindow];
}


- (void) mulleAddRetainedSubview:(UIView *) view
{
   struct mulle_pointerarray  *subviews;
   uintptr_t                  index;
   id <UIWindow>              window;

   assert( view);
   assert( view != self);
   assert( ! [view superview]);
   assert( [view isKindOfClass:[UIView class]]);

   subviews = [self _subviews];
   index    = _mulle_pointerarray_find( subviews, view);
//   fprintf( stderr, "index of existing view: %llx\n", (long long) index);

   assert( _mulle_pointerarray_find( subviews, view) == mulle_not_found_e);

   [view willMoveToSuperview:self];

   view->_superview = self;
   _mulle_pointerarray_add( subviews, view);

   [view setWindow:self->_window];
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

   // nil will not be found, that's god
   index = mulle_pointerarray_find( &self->_subviews, view);
   if( index == NSNotFound)
      return;

   [view autorelease];
   [self willRemoveSubview:view];

   assert( view->_superview);
   [view willMoveToSuperview:nil];

   view->_superview = nil;
   mulle_pointerarray_remove_in_range( &_subviews, 
                                       mulle_range_make( (unsigned int) index, 1));
   [view setWindow:nil];

   [view didMoveToSuperview:nil];
}


- (void) removeFromSuperview
{
   [_superview removeSubview:self];
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

   if( ! buf)
      return( -1);

   n = mulle_pointerarray_get_count( &_subviews);
   if( range.location + range.length > n)
      return( -1);

   mulle_pointerarray_copy_range( &_subviews, buf, range);

   return( n);
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

   if( ! buf)
      return( -1);

   if( ! _mainLayer)
      return( 0);

   n  = 1;
   n += mulle_pointerarray_get_count( &_layers);

   if( range.location + range.length > n)
      return( -1);

   mulle_pointerarray_copy_range( &_layers, buf, range);

   buf[ n - 1] = _mainLayer; // why last ?

   return( n);
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



# pragma mark - tracking rectangles

// adding/removing tracking rectangles is done in UIView+UIWindow.m

- (NSUInteger) numberOfTrackingAreas
{
   return( mulle_pointerarray_get_count( &_trackingAreas));
}


- (UITrackingArea *) trackingAreaAtIndex:(NSUInteger) i
{
   UITrackingArea   *item;

// TODO: // need to throw exception here
//   if( i >=  mulle_pointerarray_get_count( &_trackingAreas))
//      abort(); 

   item = mulle_pointerarray_get( &_trackingAreas, i);
   return( item);
}

@end



@implementation UINullLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   _frame       = frame;
   _bounds.size = frame.size;
   return( self);
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
                context:(id) context
{
   return( size);
}

// used for convenience window creation
- (NSUInteger) windowStyleMaskBits
{
   return( 0);
}

@end


