<!-- keywords: UIView, UIViewController, UILayer, layout, autoresizing -->
# mulle-ui-view

Use this topic for `UIView` geometry, layout, autoresizing, layer-backed drawing, and `UIViewController` coordination. The local split is: **views place and route; layers draw**. For specific event activities, see:

- **mulle-ui-hit-testing** — click routing, `locationInView`, z-order, excluded views

## Understand first

```bash
mulle-sde api apropos UIView
mulle-sde code search UIViewAutoresizingScaleToFill
mulle-sde code search layerClass
mulle-sde code search handleForwardedEvent
```

## Main surfaces

| Scenario | Start with |
| --- | --- |
| Geometry, hierarchy, conversion | `UIView`, `UIView+CGGeometry` |
| Autoresizing and layout | `UIAutoresizing`, `UIView+Layout` |
| Multi-view coordination | `UIViewController` |
| Drawing-backed views | `UILayer`, `UIView+UILayer`, `UINullLayer` |

## Local references

- `src/UIView.h`
- `src/UIAutoresizing.h`
- `src/UIView+Layout.h`
- `src/UIView+CGGeometry.h`
- `src/UIView+UILayer.h`
- `src/UIViewController.h`
- `src/UINullLayer.h`
- `demo/src/main-autoresize.m`
- `demo/src/main-contentmode.m`
- `demo/src/main-click.m`
- `demo/src/main-controller.m`
- `demo/src/main-layer.m`
- `test/10-frame/frame.m`
- `test/20-subview/conversion.m`
- `test/30-edit/insert-above.m`
- `test/40-layout/contentmode.m`

## Key patterns

### Build container views

```objc
parent = [UIView viewWithFrame:CGRectMake( 0, 0, 400, 200)];
[parent setPadding:UIEdgeInsetsMake( 4, 4, 4, 4)];
[parent setAutoresizingMask:UIViewAutoresizingScaleToFill];

frame = UIEdgeInsetsInsetRect( [parent contentRect], UIEdgeInsetsMake( 20, 20, 20, 20));
child = [UIView viewWithFrame:frame];
[parent addSubview:child];
```

### Put drawing on the layer

```objc
+ (Class) layerClass { return( [MyLayer class]); }

- (UIMouseButtonEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   [[self layer] doSomething];
   [self setNeedsDisplay];
   return( nil);
}
```

### Convert coordinates (never subtract frames manually)

```objc
CGPoint   windowPoint = [child convertPoint:localPoint toView:nil];
CGPoint   childPoint  = [child convertPoint:windowPoint fromView:nil];
```

### Autoresizing families (pick one)

- Content-mode: `UIViewAutoresizingTopRight`, `ScaleToFill`, `Center` — uses current geometry + margins
- Legacy: `UIViewAutoresizingFlexibleWidth`, `FlexibleBottomMargin` — uses stored original frame, ignores margins
- Mixing requires `UIViewAutoresizingMixedMode` or the runtime aborts
