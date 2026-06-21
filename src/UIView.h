#import "import.h"

//#import "UIEdgeInsets.h"

#import "UIAutoresizing.h"


//
// There is only a fixed set of properties a UIView can animate. For all
// other animation purposes use CALayer. (Many properties that appear as if
// they are animtable on UIView, are really forward to the mainLayer.
//
#define UI_VIEW_ANIMATABLE_PROPERTIES             \
   @property( observable) UIEdgeInsets   padding; \
   @property( observable) UIEdgeInsets   margins; \
   @property( observable) CGRect         frame;   \
   @property( observable) CGRect         bounds;  \
   @property( observable) CGFloat        alpha


@protocol UIAnimatableViewProperties

UI_VIEW_ANIMATABLE_PROPERTIES;

@end


#define UIVIEW_FRAME_USES_CGRECTINTEGRAL

#ifndef UIViewFrameIntegralFuzz
# define UIViewFrameIntegralFuzz    0.01
#endif


//
// possibly only do this on a per layer (canvas level) basis during
// drawInContext: ?
//
static inline CGRect   UIViewIntegralFrame( CGRect frame)
{
   return( CGRectIntegralFuzzy( frame, UIViewFrameIntegralFuzz));
}


static inline CGRect   UIViewMakeFrameWithRect( CGRect frame)
{
#ifdef UIVIEW_FRAME_USES_CGRECTINTEGRAL
   return( UIViewIntegralFrame( frame));
#else
   return( frame);
#endif
}


@class UIView;

typedef UIEvent              *UIViewEventCallback( UIView *view, UIEvent *event);
typedef UIMouseMotionEvent   *UIViewMouseMotionEventCallback( UIView *view, UIMouseMotionEvent *event);


//
// In theory UIView can manage other layer types than CALayer. It might be fun
// to write a CALayer that draws ASCII :)
//
@protocol UILayer < NSObject, NSCopying>

@property( observable) CGRect           frame;
@property( observable) CGRect           bounds;

@property( assign) CGFloat              rotation;
@property( assign) CGFloat              alpha;
@property( assign) NSInteger            tag;

// used by the render
// TODO: prefix with render_ so API code knows
@property( assign) CGAffineTransform    transform;
@property( assign) CGRect               clipRect;

@property( assign) char                 *nameUTF8String;
@property( assign) FILE                 *drawCallTracer;

- (instancetype) initWithFrame:(CGRect) frame;

- (void) dumpWithIndent:(NSUInteger) indent
                   FILE:(FILE *) fp;

- (CGSize) sizeThatFits:(CGSize) size
                context:(id <UILayoutContext>) context;

// default does nothing, it's assumed that the frame of the layer is stable
// the info contains the padding and contentArea of the view, as well as the
// layoutContext (for font info)
// info must not be NULL
- (void) layoutWithLayoutInfo:(struct UILayoutInfo *) info;

// ugliness?
- (void) forgetImplicitAnimations;


@end


@class UIViewController;
@class NSTimer;


struct CGFrameInfo;


// The "raison d^etre" of UIView
// =============================
// UIView is mainly there to handle UIEvents and to set up the transformation
// for its CALayers (position the layers on the framebuffer).
// UIViews are also there to provide a child/parent hierarchy to make it
// easier to create complex user interfaces.
//
// If events didn't exist, one could get by with just layers. But as soon as
// you have many responsive layers, event distribution becomes complex. Hence
// UIViews.
//
// A UIView does no drawing, it merely layouts. It is completely independent
// from OpenGL or whatever the backend is.
//
// The "standard" UIView hierarchy.
// =================================
// frame.origin          UIView
//      .--------------------------------------.
//      |bounds.origin                         |
//      |               frame.origin           |
//      |                    .-----------.     |
//      |                    |           |     |
//      |                    | Subview 1 |     |
//      |                    |           |     |
//      | frame.origin       '-----------'     |
//      |      .---------------.    frame.size |
//      |      |               |               |
//      |      |   Subview 2   |               |
//      |      |               |               |
//      |      '---------------'               |
//      |                 frame.size           |
//      |                                      |
//      |                           bounds.size|
//      '--------------------------------------'
//                                        frame.size
//
// Subviews live in the bounds of the superview. In 99% of all cases the
// bounds are just like the frame, but the origin set to 0.0,0.0.
// As bounds.size is then equal to frame.size there is no scaling involved.
//
// Managing the bounds of a UIView for drawing purposes is the wrong idea,
// use the bounds of the CALayer for that. In fact the bounds of a UIView IMO
// should only be changed, if you are scrolling subviews within it
// (bounds.origin) but then you are better off with a UIScrollView.
//
// Changing the bounds.size is usually bad as this changes the size of the UI
// elements. (Which _could_ be good if you are implementing some
// sort of support for poor-sighted individuals... maybe)
//
// All layers (and subviews) live in the bounds of the view. The view
// inherits the transformation and adds its own frame/bounds transformation
// to it. Experimental: On initialization a view uses CGRectIntegral on the
// frame to avoid FP precision errors in the drawing code of the CALayers.
// setFrame: isn't overridden though yet.
//
// the main layer is responsible for the "background" and the "border"
//
// Other layers are composited on top of it.
// Then the subviews are drawn/composited on those.
// Trackingareas are not copied by NSCopying.
//
@interface UIView : MulleObject < MulleAutolockingObjectProtocols,
                                  MulleUINamedObject,
                                  NSCopying,
                                  UIAutoresizing,
                                  UIAnimatableViewProperties>
{
   mulle_atomic_pointer_t                  _atomicNameUTF8String;
   mulle_atomic_pointer_t                  _atomicClassUTF8String;
   UIView                                  *_superview;

   NSObject <UIAnimatableViewProperties>   *_snapshot;

   // CAAnimationStorage (forward storage)
   void                                    *_animationStorage;

   struct mulle_pointerarray               _subviews;
   struct mulle_pointerarray               _trackingAreas;

   //
   // These four ivars together are the layers of the view. It would be nice
   // to have a copy-on-write scheme, so that the layers stay unperturbed
   // once they are handed of of to the renderer. But... if the renderer is
   // in a different process anyway, we are just handing over copies anyway...
   //
   struct mulle_pointerarray               _layers;
   // the mainLayer will be in -layers
   id <UILayer>                            _mainLayer;

   // the _shadowLayer will not appear in -layers or -getLayers...
   //
   id <UILayer>                            _shadowLayer; // below mainLayer

   // the _cacheLayer will not appear in -layers or -getLayers...
   //
   id < NSObject>                          _cacheLayer;  // CGFramebuffer

   // used only by hover code in UIView+UITracking (MulleUIWindows)
   NSTimer                                 *_hoverTimer;   // used later
}

#define UI_VIEW_FORWARD_SUPERID   ((mulle_objc_superid_t) 0x1a55cf25)  // 'UIView;forward:'


UIAutoresizingProperties;


// don't change window yourself!
@property( assign) id <UIWindow>           window;     // UIWindow really #1#
@property( assign) UIViewController        *controller; // more or less userData #2#

@property( getter=isHidden) BOOL           hidden;          // default: NO
@property( getter=isMouseHovering) BOOL    mouseHovering;  // default: NO


// UIUserInteractionEnabled
//
// When set to NO, input events are ignored. The default value of this property
// is YES. If a view is marked userInteractionEnabled as NO, or hidden as YES,
// or opacity is close to 0, then the view and its subviews will not take part
// in input events handling.
//
// https://stackoverflow.com/questions/10880868/on-ios-if-a-superviews-userinteractionenabled-is-no-then-all-subviews-are-dis
@property( getter=isUserInteractionEnabled) BOOL   userInteractionEnabled;  // default: YES

@property( assign) NSUInteger       debuggingFlags      MULLE_OBJC_THREADSAFE_PROPERTY;
@property( assign, dynamic) FILE   *drawCallTracer;  // forward to all layers for NVG trace

@property BOOL        clipsToBounds; // default: YES
//@property BOOL   needsLayout;      // use setNeedsLayout for marking
@property BOOL        needsCaching;
@property BOOL        needsTrackingAreaUpdate;

// user info, for finding views (subviewWithTag:)
@property NSInteger   tag;

// On UIView this does nothing
//@property BOOL   needsDisplay;

//
// This is used during layout of subviews to restrict the size of the bounds,
// where subviews can be placed. If autoresizingMask is set to 0
// margins will not be used.
//
@property( observable) UIEdgeInsets    padding;

//
// Margins are used during subview layout. Its the distance of the view to
// the superview or in stack views to other subviews.
// If autoresizingMask is set to 0 margins will not be used.
@property( observable) UIEdgeInsets    margins;
// this gets inherited down to all layers and subviews

// frame is the position and size relative to the superview
@property( observable) CGRect          frame;

// rawFrame bypasses integer-pixel rounding (UIViewMakeFrameWithRect).
// Use this for sub-pixel animation and game physics.
@property( observable) CGRect          rawFrame;

//
// bounds is the used to place the layers and subviews. Their frames
// are relative to the bounds. If there is a size difference between bounds
// and frame then there will be scaling. Usually the bounds.origin is 0,0
// and the bounds.size is tied to the frame.size.
// Changing a UIView bounds origin can be useful for scrolling views. But
// changing the bounds.size is very rarely useful (as UI elements will become
// too small or too large to click). For zoomed drawing use the bounds of the
// layer.
// If the bounds are not set manually, the bounds.size tracks the frame.size.
//
// Use contentRect if you are asking for bounds during layout
//
@property( observable) CGRect          bounds;

@property( observable) CGFloat         alpha;

// abused by UIStackView, will be moved away later
// TODO: how is this different from originalFrame ? Why does originalFrame
//       need an origin ?
@property( assign) UIViewAutoresizing  autoresizingMask;

@property( assign) CGSize              mulleLayoutSize;

@property( dynamic) char               *nameUTF8String      MULLE_OBJC_THREADSAFE_PROPERTY;  // useful for debugging and styling

@property( dynamic) char               *classUTF8String     MULLE_OBJC_THREADSAFE_PROPERTY;  // useful for styling

// ANIMATION SUPPORT
// no support for rotation or pose use the layer for rotation

// anchorPoint is used to determine the position from frame
@property( observable, assign) CGPoint     anchorPoint;

// position is based on frame and anchorPoint (its dynamically calculated)
@property( dynamic) CGPoint                position;


// call back for view events, your handler should return nil, if it
// handled the event or wants the event to be discarded.
@property( assign) UIViewEventCallback              *eventCallback;

// mouseMotion events are limited, you can't change their type on return
@property( assign) UIViewMouseMotionEventCallback   *mouseMotionEventCallback;


// return NO, if default layoutLayers code should not run
@property BOOL  (*willLayoutLayersCallback)( UIView *view);

// called after layoutLayers default code
@property void  (*didLayoutLayersCallback)( UIView *view);


// return NO, if default layoutTrackingAreas code should not run
@property BOOL  (*willLayoutTrackingAreasCallback)( UIView *view);

// called after layoutLayers default code
@property void  (*didLayoutTrackingAreasCallback)( UIView *view);


// return NO, if default layoutSubviews code should not run (if you want
// to run custom subview layout code, do it in this callback.)
@property BOOL  (*willLayoutSubviewsCallback)( UIView *view);

// called after layoutSubviews default code. Will be called if
// willLayoutSubviews returned NO. Return 'YES' to commence recursive layouting
@property BOOL  (*didLayoutSubviewsCallback)( UIView *view);


//
// MEMO: views are threadsafe object, but they are created with -initNoLock
//       this means, that you need to provide them with a lock before putting
//       them into a multithreaded situation. This lock assignment happens,
//       when you add a UIView to a UIWindow. The same goes for the layers.
//       This is an optimization, otherwise you would create too many locks
//       that would then be thrown away anyway.
// MEMO: But really ? The lock would probably be thrown away fairly fast and
//       then reclaimed by the class reuse cache (if used)
//
+ (instancetype) viewWithLayer:(id <UILayer>) layer;
+ (instancetype) viewWithFrame:(CGRect) frame;

// -initWithLayer:frame: is the designated initializer.
// override initWithLayer:frame: for setting defaults as it will not call init
//
- (instancetype) initWithLayer:(id <UILayer>) layer
                         frame:(CGRect) frame;

- (instancetype) initWithLayer:(id <UILayer>) layer;

- (instancetype) initWithFrame:(CGRect) frame;


//
// typically, contentRect is { CGPointZero, bounds.size }. It's the playground
// for the subviews to be placed in (via subview frame). Padding is not added
//
- (CGRect) contentRect;

// do not use (except for internal layout code)
- (CGRect) lastBounds;

- (void) mulleAddRetainedSubview:(UIView *) layer;

// if subview is already a subview somewhere else, you need to remove it
// from its superview (iOS is more lenient, but this catches simple
// setup errors)
- (void) addToSubviews:(UIView *) view;
- (void) removeFromSubviews:(UIView *) view;

- (void) removeAllSubviews;
- (void) removeAllSubviewsOfClass:(Class) class;
- (void) removeFromSuperview;
- (void) sortSubviewsByOrigin;
- (NSUInteger) numberOfSubviews;

- (void) getSubviewsIntersectingRect:(CGRect) rect
                    intoPointerArray:(struct mulle_pointerarray *) views
              invertIntersectionTest:(BOOL) flag;

- (void) didAddSubview:(UIView *) view;
- (void) willRemoveSubview:(UIView *) subview;
- (void) willMoveToSuperview:(UIView *) newSuperview;
- (void) didMoveToSuperview:(UIView *) newSuperview;
- (void) willMoveToWindow:(id <UIWindow>) newSuperview;
- (void) didMoveToWindow:(id <UIWindow>) newSuperview;

// called for each view, before the layout starts
// if a subclass overrides, it should call super. Do not setNeedsDisplay or
// related state, instead return displayBits if needed
- (UIWindowDisplayBits) willLayoutWithAbsoluteTime:(mulle_absolutetime_t) renderTime;

- (NSInteger) getSubviews:(UIView **) buf
                    range:(NSRange) range;

// this isn't deep
- (UIView *) subviewWithTag:(NSInteger) tag;

- (UIView *) subviewAtIndex:(NSUInteger) index;

// this is deep,
- (UIView *) findViewWithTag:(NSInteger) tag;

- (UIView *) superview;

- (void) setNeedsCaching;  // wipes the _cacheLayer and asks for a new one to be drawn

// this is the "main" layer. Each view has a bottom most layer that is
// supposed to fill out the UIView with background color and border. It
//

// default returns nil, indicating no support for reuse. Reuse of simple views
// is not useful. It might be useful for more intricate views..
// - prepareForReuse is a legacy concept. Don't use it. It's error prone and
// not necessary with MulleUI
- (id) prepareForReuse;

- (id <UILayer>) layer;
- (void) mulleAddRetainedLayer:(id <UILayer>) layer;
- (void) addLayer:(id <UILayer>) layer;

// will return mainLayer, but not the hidden shadowLayer
- (NSInteger) getLayers:(id <UILayer> *) buf
                  range:(NSRange) range;

- (id <UILayer>) layerWithTag:(NSInteger) tag;

// will remove mainLayer, but not the hidden shadowLayer
- (void) removeAllLayers;

// does not count the hidden shadowLayer
- (BOOL) isMultiLayer;

- (char *) nameUTF8String;
- (void) setNameUTF8String:(char *) s;

// older API:
- (void) addSubview:(UIView *) view;
- (void) removeFromSubviews:(UIView *) view;

// future subclass/category implementations
@optional
//
// the default will be a UINullLayer which will do absolutely nothing
// not even draw a background
//
+ (Class) layerClass;
- (void) setNeedsDisplay      MULLE_OBJC_THREADSAFE_METHOD;

@end

//
// #2# the controller is not used by UIView, but when a Controller wants
//     to tap into events, he sets the C callbacks and then queries the
//     view for -controller. Now [controller handleEvent:] can be called.
//


@interface UIView( Dump)

- (void) dump;
- (void) dumpWithIndent:(NSUInteger) indent
                   FILE:(FILE *) fp;

@end


//
// these all get forwarded to the "main" layer
// @interface UIView( UILayerForwarding)
// @end
// done in MulleUIOS now !



// didn't want those exposed I guess.
@interface UIView( Internals)

- (struct mulle_pointerarray *) _layers;
- (struct mulle_pointerarray *) _subviews;

@end

/*
 * #1#
 *
 * window used to be dynamically calculated. This was fine until I needed
 * to implement -didMoveToWindow:, which would have made scene composition 
 * fairly slow during.
 * 
 */

#define UIViewSubviewsCount( self) \
   mulle_pointerarray_get_count( self ? &((struct { @defs( UIView); } *) self)->_subviews : 0)

#define UIViewSubviewsFor( self, subview) \
   mulle_pointerarray_for( self ? &((struct { @defs( UIView); } *) self)->_subviews : NULL, \
                           subview)

#define UIViewLayersCount( self)                                                    \
   mulle_pointerarray_get_count( self                                               \
                                 ? &((struct { @defs( UIView); } *) self)->_layers  \
                                 : 0) +                                             \
      (self ? &((struct { @defs( UIView); } *) self)->_mainLayer != nil : 1)

#define UIViewLayersFor( view, layer)                                                                        \
   for( struct mulle_pointerarrayenumerator                                                                  \
           rover__ ## view = mulle_pointerarray_enumerate( &((struct { @defs( UIView); } *) view)->_layers), \
           *rover___  ## view ## __i = (void *) 0;                                                           \
        ! rover___  ## view ## __i;                                                                          \
        rover___ ## view ## __i = (_mulle_pointerarrayenumerator_done( &rover__ ## view),                    \
                                   (void *) 1))                                                              \
      for( layer = (view ? ((struct { @defs( UIView); } *) view)->_mainLayer : nil);                         \
           layer;                                                                                            \
           _mulle_pointerarrayenumerator_next( &rover__ ## view, (void **) &layer))


#define UIViewTrackingAreasCount( self)                                                    \
   mulle_pointerarray_get_count( self                                                      \
                                 ? &((struct { @defs( UIView); } *) self)->_trackingAreas  \
                                 : 0)

#define UIViewTrackingAreasFor( view, area)                                                      \
   mulle_pointerarray_for( self ? &((struct { @defs( UIView); } *) self)->_trackingAreas : NULL, \
                           area)
