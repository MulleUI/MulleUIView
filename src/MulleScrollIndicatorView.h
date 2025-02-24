#ifdef __has_include
# if __has_include( "UIView.h")
#  import "UIView.h"
# endif
#endif

#import "import.h"


//
// contentLength is what we are representing, the bubbleOffset with
// bubbleLength are "inside" the contentLength, not inside the frame or
// bounds. The projection onto our bounds/frame is done inside
// MulleScrollIndicatorLayer.
//
// UIScrollIndicatorView:
// 0         contentOffset.x    + bounds...width        contentSize.width
// |--------------+-------------+-------------------------------|
//               /             /
// +------------------------------------------+
// |            |  bubble   |                 |
// +------------------------------------------+
// frame...x                        frame...x + frame....width
// :MulleScrollIndicatorLayer
//
#define MulleScrollIndicatorLayerIvars


// put these into your UIControl adopting class property block

#define MulleScrollIndicatorLayerProperties  \
@property( assign) CGFloat   bubbleOffset;   \
@property( assign) CGFloat   bubbleLength;   \
@property( assign) CGFloat   contentLength


PROTOCOLCLASS_INTERFACE0( MulleScrollIndicatorLayer)

MulleScrollIndicatorLayerProperties;

// MEMO: bounds is [self bounds]
- (BOOL) isInsideBubbleAtPoint:(CGPoint) point
                        bounds:(CGRect) bounds
                      offsetAt:(CGPoint *) p_distance;

- (CGFloat) bubbleValueAtPoint:(CGPoint) point
                        bounds:(CGRect) bounds
                isInsideBubble:(BOOL *) isInsideBubble;

- (CGRect) bubbleFrameWithBounds:(CGRect) bounds;

PROTOCOLCLASS_END()


@interface MulleScrollIndicatorView : UIView
@end


@interface MulleScrollIndicatorView( MulleScrollIndicatorLayerForwarding) <MulleScrollIndicatorLayer>
@end

