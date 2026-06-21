<!-- keywords: quirks, debugger, bounds, hit-testing, UINullLayer, controller, z-order -->
# mulle-ui-view quirks

## Geometry and layout

- `frame` and `bounds` are only partly coupled. `test/10-frame/frame.m` shows that a manual `bounds.origin` survives later `setFrame:` calls.
- `pointInside:withEvent:` checks both `contentRect` and `bounds` (`src/UIView+UIEvent.m`), so padding and bounds changes can both affect hits.
- Use `contentRect` for subview layout. `src/UIView.h` explicitly treats raw `UIView` bounds as the wrong drawing-space abstraction.
- `clipsToBounds` defaults to `YES`, and ancestor clipping still wins even if a child disables clipping; `demo/src/main-clip.m` shows that.
- Layout can cull a view to zero size; check `-isCulledByLayout` before chasing a renderer bug.

## Autoresizing

- Content-mode bits and legacy `Flexible*` bits are different engines, not aliases.
- The runtime aborts if both families are mixed without `UIViewAutoresizingMixedMode` (`src/UIAutoresizing.m`).
- Content-mode layout uses current container geometry and `margins`; legacy layout uses `originalFrame` and ignores `margins`.

## Event routing

- Hidden views, `userInteractionEnabled == NO`, and views with `alpha < 0.01` are out of hit testing together with their subtrees (`src/UIView+UIEvent.m`).
- Hit testing walks subviews in reverse order, so z-order bugs and event-delivery bugs often have the same root cause (`src/UIView+UIEvent.m`, `test/30-edit/insert-above.m`).
- `UIInputEvent` caches per-view locations during hit testing. Outside that path, use `-locationInView:` and treat `_locationForView:` as internal.
- `hitSearchSubviews:withInputEventPointer:` may replace the event object; `demo/src/main-click.m` has an obscuring view that mirrors coordinates this way.

## Controllers

- `UIViewController` does not retain its views. The window/view tree owns lifetime; the controller only coordinates.
- Forwarding with `-handleEvent:ofView:` can recurse back through the controller. Use `-handleForwardedEvent:` for sibling delivery.
- `isLayoutingViews` is opt-in. If a subclass enables it, the subclass is expected to implement `-layoutViews`.

## Layers and hierarchy editing

- A plain `UIView` starts with a `UINullLayer`, which is intentionally non-drawing.
- `UIView` animation is narrow: `padding`, `margins`, `frame`, `bounds`, `alpha`. Rotation and richer render state live on the layer.
- The main layer is the background/border layer. Extra layers composite above it, and subviews composite after those layers.
- `removeAllLayers` does not touch the hidden shadow/cache internals mentioned in `src/UIView.h`.
- `addToSubviews:` expects a detached child; remove it from the old superview yourself first.
