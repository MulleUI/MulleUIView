<!-- keywords: patterns, debugger, UIView, UIViewController, UILayer, UIInputEvent, autoresizing -->
# mulle-ui-view patterns

## Start geometry bugs from `frame`, `bounds`, then `contentRect`

- `test/10-frame/frame.m` is the shortest contract for local view geometry.
- A later `setFrame:` updates `bounds.size`, but a manually changed `bounds.origin` stays in place.
- `contentRect` is the subview playground; use it when layout looks wrong, not raw `bounds`.

```objective-c
printf( "f=%s\n", CGRectUTF8String( [view frame]));
printf( "b=%s\n", CGRectUTF8String( [view bounds]));
printf( "c=%s\n", CGRectUTF8String( [view contentRect]));
```

## Use the conversion tests for bounds-origin and zoom bugs

- `test/20-subview/conversion.m` covers non-zero bounds origins and `toView:nil` / `fromView:nil`.
- `test/20-subview/bounds-zoom.m` covers the scaled case where `bounds.size != frame.size`.
- If a click or draw position looks off by a constant offset, check `bounds.origin`; if it scales, check the `frame`/`bounds.size` ratio.

```objective-c
point = [subview convertPoint:CGPointMake( 3, 4) toView:nil];
point = [subview convertPoint:point fromView:nil];
```

## Split autoresize failures by engine before reading more code

- `demo/src/main-autoresize.m` and `demo/src/main-contentmode.m` show the modern content-mode path. It re-evaluates placement on each layout pass and uses `margins`.
- `demo/src/main-autoresize-legacy.m` shows the legacy `Flexible*` path. It uses `originalFrame`, ignores `margins`, and only reacts to parent shape changes.
- `test/40-layout/autoresize3.m` is the local mixed-mode example. Use it when a bug only appears after both initial placement and later resize.

## Trace hit testing through `locationInView:`

- `demo/src/main-click.m` is the main event-routing reproducer: nested views, tricky bounds, and custom event mutation.
- Public code should query `[event locationInView:self]`. `_locationForView:` is only reliable inside the hit-test plumbing.
- When an enclosing view rewrites an event, `hitSearchSubviews:withInputEventPointer:` recalculates parent-space location from window coordinates before continuing.

```objective-c
point = [event locationInView:self];
view  = [self hitSearchSubviews:point
        withInputEventPointer:&event];
```

## Reproduce controller loops with forwarded events

- `demo/src/main-controller.m` is the local pattern for peer-view coordination.
- Debug event recursion by checking whether controller code re-enters `-handleEvent:ofView:` instead of calling `-handleForwardedEvent:`.
- Also confirm the controller actually registered the views with `addView:`; the demo wires that into property setters.

## Separate layer bugs from view bugs early

- `demo/src/main-layer.m` is the quick check for main-layer state such as background, border, and corner radius.
- `demo/src/main-click.m` shows the reusable drawing path: override `+layerClass`, mutate the custom layer, then call `setNeedsDisplay`.
- A plain `UIView` defaulting to `UINullLayer` means layout and event code can look correct while nothing visible draws.

## Use the editing API when z-order is part of the bug

- `test/30-edit/insert-above.m` is the concrete ordering contract.
- Prefer `insertSubview:aboveSubview:`, `belowSubview:`, `bringSubviewToFront:`, and `sendSubviewToBack:` over hand-editing `_subviews`.
