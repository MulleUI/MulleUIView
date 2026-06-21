<!-- keywords: debugger, UIView, UIViewController, UILayer, layout, autoresizing, hit-testing -->
# mulle-ui-view

Load this when a bug touches the exported MulleUIView surface: `UIView` geometry/layout, `UIInputEvent` routing, `UIViewController` forwarding, or layer-backed drawing. The main local split is still **views place and route; layers draw**.

## Understand first

```bash
mulle-sde api apropos UIView
mulle-sde code search "contentRect"
mulle-sde code search "UIViewAutoresizingMixedMode"
mulle-sde code search "locationInView:"
mulle-sde code search "handleForwardedEvent:"
mulle-sde code search "layerClass"
```

## Main surfaces

| Symptom | Start with |
| --- | --- |
| Wrong frame, clipping, or coordinate conversion | `UIView`, `UIView+CGGeometry`, `test/10-frame/frame.m`, `test/20-subview/conversion.m` |
| Children jump or stretch after resize | `UIAutoresizing`, `UIView+Layout`, `demo/src/main-autoresize.m`, `demo/src/main-autoresize-legacy.m`, `demo/src/main-contentmode.m` |
| Click lands in the wrong view or wrong local point | `UIView+UIEvent`, `UIInputEvent+UIView`, `demo/src/main-click.m` |
| Peer views recurse or never see forwarded input | `UIViewController`, `demo/src/main-controller.m` |
| Nothing draws, or only border/background state changes | `UILayer`, `UIView+UILayer`, `UINullLayer`, `demo/src/main-layer.m` |
| Wrong z-order after inserts/replacements | `UIView+UIViewEditing`, `test/30-edit/insert-above.m` |

## Local references

- `README.md`
- `asset/dox/TOC.md`
- `src/MulleUIView.h`
- `src/UIView.h`
- `src/UIAutoresizing.h`
- `src/UIView+Layout.h`
- `src/UIView+CGGeometry.h`
- `src/UIView+UIEvent.h`
- `src/UIInputEvent+UIView.h`
- `src/UIView+UILayer.h`
- `src/UIView+UIViewEditing.h`
- `src/UIViewController.h`
- `src/UINullLayer.h`
- `demo/README.md`
- `demo/src/main-autoresize.m`
- `demo/src/main-autoresize-legacy.m`
- `demo/src/main-contentmode.m`
- `demo/src/main-click.m`
- `demo/src/main-controller.m`
- `demo/src/main-layer.m`
- `demo/src/main-clip.m`
- `test/10-frame/frame.m`
- `test/20-subview/conversion.m`
- `test/20-subview/bounds-zoom.m`
- `test/30-edit/insert-above.m`
- `test/40-layout/autoresize3.m`

## Local workflow

- Classify the bug first: geometry/layout, event routing, controller forwarding, layer choice, or hierarchy order.
- For geometry, inspect `frame`, `bounds`, and `contentRect` together. Local tests allow a custom `bounds.origin` to survive later `frame` changes.
- For resize bugs, decide whether the mask is content-mode (`Top`, `Center`, `ScaleToFill...`) or legacy (`Flexible*`). Mixing both aborts unless `UIViewAutoresizingMixedMode` is set.
- For click bugs, trust `locationInView:` and follow `hitSearchSubviews:withInputEventPointer:`; local code can replace the event object mid-search.
- For drawing bugs, confirm the view really has a drawing layer. Plain `UIView` starts on `UINullLayer`.

## Verify/report

- Recheck behavior against `test/10-frame/frame.m`, `test/20-subview/conversion.m`, `test/20-subview/bounds-zoom.m`, and `test/30-edit/insert-above.m`.
- If the failure only shows up visually, name the closest reproducer in `demo/src/` and state whether it is a view-space, autoresize, controller, or layer-space bug.
