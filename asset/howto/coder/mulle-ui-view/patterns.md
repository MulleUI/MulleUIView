<!-- keywords: patterns, UIView, UILayer, UIViewController, autoresizing, conversion -->
# mulle-ui-view patterns

## Build container views around `contentRect`

- Create the view, set padding/mask, then place children relative to `[parent contentRect]`.
- Use `viewWithFrame:` when the view already has a stable frame; use `[UIView instance]` when a callback or controller will assign the frame later.

```objective-c
UIView   *parent;
UIView   *child;
CGRect   frame;

parent = [UIView viewWithFrame:CGRectMake( 0, 0, 400, 200)];
[parent setPadding:UIEdgeInsetsMake( 4.0, 4.0, 4.0, 4.0)];
[parent setAutoresizingMask:UIViewAutoresizingScaleToFill];

frame = UIEdgeInsetsInsetRect( [parent contentRect],
                               UIEdgeInsetsMake( 20.0, 20.0, 20.0, 20.0));
child = [UIView viewWithFrame:frame];
[parent addSubview:child];
```

## Choose one autoresizing family

- `demo/src/main-autoresize.m` and `demo/src/main-contentmode.m` use content-mode bits such as `UIViewAutoresizingTopRight`, `UIViewAutoresizingCenter`, and `UIViewAutoresizingScaleToFill`.
- `demo/src/main-autoresize-legacy.m` uses legacy `UIViewAutoresizingFlexible*` bits for resize-from-original-frame behavior.
- After manual frame changes, ask the parent or window for layout again.

```objective-c
[child setAutoresizingMask:UIViewAutoresizingTopRight];
[parent addSubview:child];
[parent setNeedsLayout];
```

```objective-c
[child setAutoresizingMask:UIViewAutoresizingFlexibleWidth
                           | UIViewAutoresizingFlexibleBottomMargin];
[parent addSubview:child];
[parent setNeedsLayout];
```

## Put drawing on a custom layer, not on the view

- `UIView` owns layout and events; the layer owns drawing state.
- For reusable drawing behavior, override `+layerClass` as in `demo/src/main-click.m`.
- For simple styling, mutate `[view layer]` directly as in `demo/src/main-layer.m`.

```objective-c
@interface UIPointsView : UIView
@end

@implementation UIPointsView

+ (Class) layerClass
{
   return( [PointsLayer class]);
}

- (UIMouseButtonEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   CGPoint        point;
   PointsLayer    *layer;

   point = [event locationInView:self];
   layer = MULLE_OBJC_CLASS_CAST( PointsLayer, [self layer]);
   [layer addCircleAtPoint:point
                     color:CGColorMakeRandomHueOpaque()];
   [self setNeedsDisplay];
   return( nil);
}

@end
```

## Convert coordinates instead of subtracting frames

- Bounds offsets and bounds scaling are part of normal usage here; use the conversion API from `src/UIView+CGGeometry.h`.
- `test/20-subview/conversion.m` and `test/20-subview/bounds-zoom.m` are the local contract for `toView:nil`, `fromView:nil`, and zoomed bounds.

```objective-c
CGPoint   windowPoint;
CGPoint   childPoint;

windowPoint = [child convertPoint:CGPointMake( 3, 4)
                           toView:nil];
childPoint  = [child convertPoint:windowPoint
                         fromView:nil];
```

## Let controllers coordinate peer views

- `UIViewController` is the local place for cross-view behavior.
- Register views with the controller, then forward events with `handleForwardedEvent:` when another managed view should react.
- Comparison: the role is UIKit-like, but the controller does **not** own the view tree here.

```objective-c
- (UIEvent *) handleEvent:(UIEvent *) event
                   ofView:(UIView *) view
{
   if( view == _aButton)
      return( [_bButton handleForwardedEvent:event]);
   return( [_aButton handleForwardedEvent:event]);
}
```

## Forward layer properties and methods in `@optional`

UIView already declares forwarding for the base `CGGraphicsLayer` API.
When your UIView subclass uses a custom layer subclass, declare the additional
layer properties and methods explicitly with `forward` in an `@optional`
section of the subclass `@interface`. Do **not** use a separate "Forward"
category.

```objective-c
@class MyLayer;

@interface MyView : UIView

@optional

// forward properties from MyLayer to the layer (via forward:)
@property( forward, assign) CGColorRef fillColor;
@property( forward, assign) CGFloat    borderWidth;

// forward methods from MyLayer to the layer
- (void) addCircleAtPoint:(CGPoint) point
                    color:(CGColorRef) color;

@end
```

The `forward` property attribute prevents MulleObjC from creating dynamic
property accessors (ivars + getter/setter) and instead declares that
accesses are forwarded via `forward:` to the main layer.

Rules:

- Only forward properties and methods that your **custom** layer subclass adds.
  The base `CGGraphicsLayer API is already forwarded by `UIView` itself.
- Place all forwarded declarations in an `@optional` block so the compiler
  does not require an explicit implementation.
- Combine `forward` with the declared @property attributes (`assign`, `copy`, etc.)
  of the layers @property.

## Use the editing API when z-order matters

- For reordering, prefer `insertSubview:aboveSubview:`, `belowSubview:`, `bringSubviewToFront:`, and `sendSubviewToBack:`.
- `test/30-edit/insert-above.m` shows the expected order after insertion.

```objective-c
UIView   *overlay;

overlay = [UIView instance];
[container insertSubview:overlay
            aboveSubview:[container subviewWithTag:1]];
```
