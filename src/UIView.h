#import "import.h"

#import "UITrackingArea.h"
#import "UIEdgeInsets.h"

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




//
// In theory UIView can manage other layer types than CALayer. It might be fun
// to write a CALayer that draws ASCII :)
//
@protocol UILayer < NSObject>

@property( observable) CGRect   frame;
@property( observable) CGRect   bounds;

@property( assign) CGAffineTransform   transform;
@property( assign) CGRect              clipRect;
@property( assign) CGFloat             alpha;

- (instancetype) initWithFrame:(CGRect) frame;

- (char *) debugNameUTF8String;
- (void) setDebugNameUTF8String:(char *) s;

- (CGSize) sizeThatFits:(CGSize) size
                context:(id) context;

// used for convenience window creation
- (NSUInteger) windowStyleMaskBits;

@end


struct CGFrameInfo;

// The "raison d^etre" of UIView
// =============================
// UIView is mainly there to handle UIEvents and to set up the transformation
// for its CALayers (position the layers on the framebuffer).
// UIViews are also there to provide a child/parent hierarchy to make it
// easier to create complex userinterfaces.
//
// If events didn't exist, one could get by with just layers. But as soon as
// you have many responsive layers, event distribution becomes compley. Hence
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
// Subviews live in the bounds of the superview. In 99% of all cases the
// bounds are just like the frame, but the origin set to 0.0,0.0.
// As bounds.size is then equal to frame.size there is no scaling involved.
//
// Managing the bounds of a UIView for drawing purposes is the wrong idea,
// use the bounds of the CALayer for that. In fact the bounds of a UIView IMO
// should only be changed, if you are
// scrolling subviews within it (bounds.origin) but then you are better off
// with a UIScrollView.
//
// Changing the bounds.size is usually bad as this changes the size of the UI
// elements. (Which _could_ be good if you are implementing some
// sort of support for poor-sighted individuals... maybe)
//
// All layers (and subviews) live in the bounds of the view. The view
// inherits the transformation and adds its own frame/bounds transformation
// to it.
//
// the main layer is responsible for the "background" and the "border"
//
// Other layers are composited on top of it
// Then the subviews are drawn/composited on those.
//
struct MulleClickDragDifferentiator
{
   mulle_relativetime_t   _mouseMotionSuppressionDelay;  // config value

   mulle_absolutetime_t   _suppressUntilTimestamp;
};

//
// This is restricted to h/v resizing to indicate flexibility
// The UIViewAutoresizingStop preempts recursive autoresize by
// the layouter.
//
enum UIViewAutoresizing
{
   UIViewAutoresizingNone           = 0x00,
   UIViewAutoresizingFlexibleWidth  = 0x10,
   UIViewAutoresizingFlexibleHeight = 0x20,
   UIViewAutoresizingFlexible       = 0x30,
   UIViewAutoresizingStickToTop     = 0x100,
   UIViewAutoresizingStickToBottom  = 0x200,
   UIViewAutoresizingStickToMiddle  = 0x300,   // v center
   UIViewAutoresizingStickToLeft    = 0x400,
   UIViewAutoresizingStickToRight   = 0x800,
   UIViewAutoresizingStickToCenter  = 0xC00,   // h center

   // some special bits
   UIViewAutoresizingClipToBounds   = 0x1000,    // size to fit into bounds if smaller
   UIViewAutoresizingCullAtBounds   = 0x2000,    // set to size 0.0 if exceeds bounds
};

// "backwards" compatibility

typedef NSUInteger   UIViewAutoresizing;


char   *UIViewAutoresizingMaskUTF8String( UIViewAutoresizing bits);
char   *UIViewAutoresizingMaskShortUTF8String( UIViewAutoresizing bits);




@interface UIView : NSObject <UIAnimatableViewProperties>
{
   UIView                                  *_superview;

   struct mulle_pointerarray               *_layers;     // todo why no inline ?
   struct mulle_pointerarray               *_subviews;

   struct UITrackingAreaArray              _trackingAreas;

   id < NSObject>                          _cacheLayer;  // CGLayer

   struct MulleClickDragDifferentiator     _clickOrDrag;

   NSObject <UIAnimatableViewProperties>   *_snapshot;

   // CALayer
   id <UILayer>                            _mainLayer;
   // CAAnimationStorage (forward storage)
   void                                    *_animationStorage;
}

@property( getter=isHidden)                 BOOL   hidden;                  // default: NO
@property( getter=isUserInteractionEnabled) BOOL   userInteractionEnabled;  // default: YES

@property BOOL   clipsToBounds;   // default: YES
//@property BOOL   needsLayout;     // use setNeedsLayout for marking
@property BOOL   needsCaching;

// user info, for finding views (subviewWithTag:)
@property NSInteger   tag;

// On UIView this does nothing
//@property BOOL   needsDisplay;


//
// This is used during layout of subviews to restrict the size of the bounds,
// where subviews can be placed. Use -layoutRect in layout code, which takes
// padding into account
//
@property( observable) UIEdgeInsets   padding;

//
// Margins are used during subview layout. Its the distance of the view to
// other views.
//
@property( observable) UIEdgeInsets   margins;
// this gets inherited down to all layers and subviews

// frame is the position and size relative to the superview
@property( observable) CGRect         frame;

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
// Use layoutRect if you are asking for bounds during layout
//
@property( observable) CGRect         bounds;

@property( observable) CGFloat        alpha;

//
// tyically, contentRect is { CGPointZero, bounds.size }. It's the playground
// for the subviews to be placed in (via subview frame). Padding is added by
// layoutRect
//
- (CGRect) contentRect;

// layoutRect take the contentRect and subtract the padding. Only used
// by UIView during layout
- (CGRect) layoutRect;

// call back for view input events, your handler should return nil if it
// handled or wants to discard the event.
// UserInteractionEnabled must be set to YES to get this callback
@property( assign) UIInputEvent         *(*eventCallback)( UIView *view, UIInputEvent *event);

@property( assign) UIViewAutoresizing   autoresizingMask;
//
// When autoresizing is used the original frame is stored here on the first
// layout and then used as the frame to layout in subsequent layout steps
// this protects us from accumulated fp errors
//
@property( assign) CGRect   originalFrame;

// abused by UIStackView, will be moved away later
@property( assign) CGSize   mulleLayoutSize;

// return NO, if default layoutSubviews code should not run
@property BOOL  (*willLayoutSubviews)( UIView *view);

// called after layoutSubviews default code, not if willLayoutSubviews returns NO
@property void  (*didLayoutSubviews)( UIView *view);

// return NO, if default layoutLayers code should not run
@property BOOL  (*willLayoutLayers)( UIView *view);

// called after layoutLayers default code, not if willLayoutLayers returns NO
@property void  (*didLayoutLayers)( UIView *view);


+ (instancetype) viewWithFrame:(CGRect) frame;

- (instancetype) initWithFrame:(CGRect) frame;

- (void) mulleAddRetainedSubview:(UIView *) layer;

- (void) addSubview:(UIView *) view;
- (void) setSubviews:(struct mulle_pointerarray *) array;

- (void) getSubviewsIntersectingRect:(CGRect) rect
                    intoPointerArray:(struct mulle_pointerarray *) views
              invertIntersectionTest:(BOOL) flag;

// called for each view, before layouting starts
// if a subclass overrides, it should call super
- (void) willRenderWithAbsoluteTime:(mulle_absolutetime_t) renderTime;

- (NSInteger) getSubviews:(UIView **) buf
                    range:(NSRange) range;

// this isn't deep
- (UIView *) subviewWithTag:(NSInteger) tag;

// this is deep,
- (UIView *) findSubviewWithTag:(NSInteger) tag;

- (UIView *) superview;


- (void) setNeedsCaching;  // wipes the _cacheLayer and asks for a new one to be drawn

// view must be part of window view hierarchy, for these function to work
// properly

- (BOOL) mulleIsEffectivelyHidden;  // recursive test the hierarchy up


// ---
// UIView( UITrackingArea)
// ---
- (NSUInteger) numberOfTrackingAreas;
- (struct UITrackingArea *) trackingAreaAtIndex:(NSUInteger) i;

// ---
// UIView( UILayer)
// ---
+ (instancetype) viewWithLayer:(id <UILayer>) layer;

//
// designated initializer, override this for defaults
//
- (instancetype) initWithLayer:(id <UILayer>) layer
                         frame:(CGRect) frame;
- (instancetype) initWithLayer:(id <UILayer>) layer;

// this is the "main" layer. Each view has a bottom most layer that is
// supposed to fill out the UIView with background color and border. It
//
- (id <UILayer>) layer;
- (void) mulleAddRetainedLayer:(id <UILayer>) layer;
- (void) addLayer:(id <UILayer>) layer;
- (NSInteger) getLayers:(id <UILayer> *) buf
                  range:(NSRange) range;

- (BOOL) isMultiLayer;

- (void) willChange;  // does nothing, category/subclass will override

@end


//
// the default will be a UINullLayer which will do absolutely nothing
// not even draw a background
//
@interface UIView( UILayerFuture)

+ (Class) layerClass;

@end


//
// these all get fowarded to the "main" layer
//
@interface UIView( UILayerForwarding)

/*
- (void) setBackgroundColor:(CGColor) color;
- (void) setBorderColor:(CGColor) color;
- (void) setBorderWidth:(CGFloat) value;
- (void) setCornerRadius:(CGFloat) color;
- (CGColor) backgroundColor;
- (CGColor) borderColor;
- (CGFloat) borderWidth;
- (CGFloat) cornerRadius;
*/
- (char *) debugNameUTF8String;
- (void) setDebugNameUTF8String:(char *) s;

// TODO: move to UIWindow

//@property void                      (*drawCallback)( id <UILayer>layer, CGContext *ctxt);
//@property( observable) CGFloat      cornerRadius;
//@property( observable) CGFloat      borderWidth;
//@property( observable) CGFloat      opacity;
//@property( observable) CGColor      borderColor;
//@property( observable) CGColor      backgroundColor;
//@property( observable) CGPoint      pixelCenter;
//@property( observable) BOOL         masksToBounds;

@end


// didn't want those exposed I guess.
@interface UIView( Internals)

- (struct mulle_pointerarray *) _layers;
- (struct mulle_pointerarray *) _subviews;

@end

