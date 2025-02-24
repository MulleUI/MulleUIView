#ifdef __has_include
# if __has_include( "UIView.h")
#  import "UIView.h"
# endif
#endif


#import "import.h"


struct UIScrollViewAppearance
{
   CGFloat   scrollerWidth;
   CGFloat   scrollerOffsetStart;
   CGFloat   scrollerOffsetEnd;
   CGFloat   scrollerOffsetEndAlone;
};


/*
 * The scrollable content (views) of a UIScrollview is actually contained
 * and managed by it's UIScrollContentView. That way the UIScrollview can
 * have non-scrollable views like the MulleScrollIndicatorViews on top.
 * So add subviews to -contentView not to the UIScrollView itself.
 *
 *
 *     UIScrollView
 *    .---------------------------------------.
 *    |.---------------------------------.---.|
 *    || UIScrollContentView             | M ||
 *    ||  .---.                          | u ||
 *    ||  |   |     .---.                | l ||
 *    ||  '---'     |   |                | l ||
 *    ||            '---'                | e ||
 *    ||                                 | S ||
 *    ||                                 | c ||
 *    ||                                 | r ||
 *    ||                                 | o ||
 *    ||                                 | l ||
 *    ||                                 | l ||
 *    ||                                 | . ||
 *    |.--------------------------------.| . ||
 *    || MulleScrollIndicatorView       || . ||
 *    |'--------------------------------''---'|
 *    '---------------------------------------'
 *
 */
@class UIScrollContentView;
@class UIScrollView;
@class MulleScrollIndicatorView;
@protocol UIScrollContent;

@protocol UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *) scrollView;
- (void) scrollViewDidZoom:(UIScrollView *) scrollView;

@optional
- (void) scrollViewWillBeginDragging:(UIScrollView *) scrollView;
- (void) scrollViewWillEndDragging:(UIScrollView *) scrollView
                      withVelocity:(CGPoint) velocity
               targetContentOffset:(CGPoint *) targetContentOffset;
- (void) scrollViewDidEndDragging:(UIScrollView *) scrollView
                   willDecelerate:(BOOL)decelerate;

- (void) scrollViewWillBeginDecelerating:(UIScrollView *) scrollView;
- (void) scrollViewDidEndDecelerating:(UIScrollView *) scrollView;

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *) scrollView;

- (void) scrollViewWillBeginZooming:(UIScrollView *) scrollView
                           withView:(UIView *) view;
- (void) scrollViewDidEndZooming:(UIScrollView *) scrollView
                        withView:(UIView *) view
                         atScale:(CGFloat) scale;

- (BOOL) scrollViewShouldScrollToTop:(UIScrollView *) scrollView;
- (void) scrollViewDidScrollToTop:(UIScrollView *) scrollView;

- (UIView *) viewForZoomingInScrollView:(UIScrollView *) scrollView;

@end


PROTOCOLCLASS_INTERFACE0( UIScrollContent)

@property( assign, dynamic) CGPoint   contentOffset;
@property( assign) CGSize             contentSize;
@property( assign, setter=setClampConservatively:) BOOL   clampsConservatively;

- (CGRect) frame;
- (CGRect) bounds;

@optional
- (CGPoint) contentOffset;  // same as bounds.origin
- (void) setContentOffset:(CGPoint) offset; // set bounds.origin here

- (void) scrollContentOffsetBy:(CGPoint) diff;
- (CGPoint) clampedContentOffset:(CGPoint) offset;
- (CGRect) clampedBounds:(CGRect) bounds;

- (void) centerOnPoint:(CGPoint) point;

PROTOCOLCLASS_END()


// Now part of MulleUIBase
// #include "MullePointHistory.h"

//      headerView/footerView scroll left/right with contentView
//   +-----------------------------------+
//   |           headerView              |
//   |         |             |           |
//   | leftView| contentView | rightView | leftView / rightView scoll up/down with contentView
//   |         |             |           |
//   |           footerView              |
//   +-----------------------------------+
//

//
// If you remove a UIScrollView from its window hierarchy, be sure to
// setMomentum:CGPointZero timestamp:0 to avoid crashes
//
@interface UIScrollView : UIView < UIWindowRenderDelegate>
{
	UIView <UIScrollContent>    *_contentView;
	MulleScrollIndicatorView    *_horIndicatorView;
	MulleScrollIndicatorView    *_verIndicatorView;

// Event handling state
   CGPoint                     _momentum;
   CGPoint                     _locationInWindow;
   mulle_absolutetime_t        _scrollStartTime;
   mulle_absolutetime_t        _momentumTimestamp;
   struct MullePointHistory    _locationInWindowHistory;
   CGPoint                     _bubbleDragOffset;
}

@property( assign) id <UIScrollViewDelegate>       delegate;
@property( assign, getter=isDragging) BOOL         dragging;
@property( assign, getter=isZoomEnabled) BOOL      zoomEnabled;
@property( assign) BOOL                            showsHorizontalScrollIndicator;
@property( assign) BOOL                            showsVerticalScrollIndicator;
@property( assign) UIEdgeInsets                    contentInsets;
@property( assign) struct UIScrollViewAppearance   appearance;

+ (Class) scrollIndicatorViewClass;
+ (Class) scrollContentViewClass;

// creates contentView and indicatorViews
- (void) setupSubviewsInRect:(CGRect) rect;

// passed to contentView

- (CGPoint) contentOffset;
- (void) setContentOffset:(CGPoint) offset;
- (CGSize) contentSize;
- (void) setContentSize:(CGSize) size;

- (void) scrollContentOffsetBy:(CGPoint) diff;

// move this into category
- (void) scrollRectToVisible:(CGRect) rect
                    animated:(BOOL) animated;

// add subviews to contentView not to UIScrollView
- (UIView <UIScrollContent> *) contentView;
- (UIView *) horizontalScrollIndicatorView;
- (UIView *) verticalScrollIndicatorView;

- (CGPoint) zoomFactor;

// returns YES if there is momentum
- (BOOL) setMomentum:(CGPoint) momentum
           timestamp:(mulle_absolutetime_t) timestamp;

@end


/*
 * UIScrollContentView geometry
 *
 * The UIScrollContentView uses the bounds rect to pick out a rectangle for
 * display in its frame. It clips the rest. As the bounds.size is equal to
 * the frame.size (unless you hack it), there is no scrolling involved.
 * Only panning. This pretty much the same idea as CGGraphicsLayer, where the canvas
 * is the content. But then again a UIView does no drawing!
 *
 *
 * content.origin (0.0,0.0)
 *      .----------------------------------.
 *      |                                  |
 *      | bounds.origin (contentOffset)    |   frame.origin
 *      |       .------------------.       |        .------------------.
 *      | .---. |                  |       |        |                  |
 *      | |   | |                  |       |        |                  |
 *      | '---' |      .---.       |       |        |      .---.       |
 *      |       |      |   |       |--------------->|      |   |       |
 *      |       |      '---'       |       |        |      '---'       |
 *      |       |                  |       |        |                  |
 *      |       '------------------'       |        '------------------'
 *      |                    bounds.size   |                       frame.size
 *      |                                  |
 *      '----------------------------------'- (void) centerOnPoint:(CGPoint) point

 *                                    content.size (contentSize)
 */


@interface UIScrollContentView : UIView < UIScrollContent>

@property( assign, dynamic) CGPoint   contentOffset;
@property( assign) CGSize             contentSize;
@property( assign, setter=setClampConservatively:) BOOL   clampsConservatively;

@end 

