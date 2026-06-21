<!-- keywords: quirks, bounds, hit-testing, UINullLayer, controller, autoresizing -->
# mulle-ui-view quirks

## Geometry and layout

- `frame` and `bounds` are only partly coupled. Changing `frame` reties `bounds.size` to the new size, but a manual `bounds.origin` survives; `test/10-frame/frame.m` documents that contract.
- Use `contentRect` for subview layout. Raw `bounds` may carry scrolling or zoom offsets, and `src/UIView.h` explicitly warns against using `UIView` bounds like drawing bounds.
- `clipsToBounds` defaults to `YES`. Turning it off on a child does not bypass clipping higher up the tree; `demo/src/main-clip.m` shows ancestor clipping still wins.
- If `autoresizingMask` is `0`, `margins` are ignored.
- Layout can cull a view down to zero size; check `-isCulledByLayout` before assuming a layouted child is still visible.

## Autoresizing modes

- Content-mode bits (`Top`, `Center`, `ScaleToFill...`) and legacy `Flexible*` bits are different engines in `src/UIAutoresizing.h`.
- Content-mode layout uses current container geometry and honors `margins`.
- Legacy layout ignores `margins`, uses the stored original frame, and only reacts when the parent shape actually changed.
- If you intentionally mix both styles, mark that intent with `UIViewAutoresizingMixedMode` instead of relying on accidental bit combinations.

## Event routing

- Hidden views, views with `userInteractionEnabled == NO`, and nearly transparent views are removed from hit testing together with their subtrees.
- Passing an event into `-hitTest:withEvent:` updates the event's per-view location cache. Outside that plumbing, use `-locationInView:` and treat `_locationForView:` as internal.
- `demo/src/main-click.m` shows why this matters: the public path is `locationInView:`, even if the private cache happens to match during hit testing.
- `-hitSearchSubviews:withInputEventPointer:` may replace the event object before propagation continues; the obscuring-view example in `demo/src/main-click.m` does exactly that.

## Controllers

- `UIViewController` does not retain its views. The window/view hierarchy owns lifetime; the controller just registers views and coordinates them.
- When controller code replays an event into a sibling view, use `-handleForwardedEvent:` or you will recurse back through the controller callback path.
- `isLayoutingViews` is opt-in. If you turn it on, your subclass is expected to implement `-layoutViews`.

## Layers and animation

- A plain `UIView` starts with a `UINullLayer`. That layer is intentionally non-drawing and exists so view logic can be tested without a renderer.
- `UIView` animation is intentionally narrow: `padding`, `margins`, `frame`, `bounds`, `alpha`. Put rotation and other render-state animation on the layer instead.
- The main layer is the background/border layer. Extra layers are composited above it, and subviews are composited after those layers.
- `-removeAllLayers` only affects the public layer list; hidden shadow/cache internals are separate.

## Hierarchy editing

- `-addToSubviews:` expects a detached child. Remove a view from its old superview yourself first; this API is stricter than UIKit's lenient reparenting.
- When order matters, use the editing methods from `src/UIView+UIViewEditing.h`; `test/30-edit/insert-above.m` is the concrete ordering contract.
