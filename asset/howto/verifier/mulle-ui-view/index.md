<!-- keywords: dump, layout, hit-testing, tracing, draw-call, event-routing -->
# mulle-ui-view

Load this when verifying app code that uses `UIView`, `UIViewController`, or custom `UILayer`s. The repo-specific verifier support is small but concrete: hierarchy dumps, per-view debug flags, and layer draw-call tracing.

## Understand first

```bash
mulle-sde api apropos UIView
mulle-sde api cat UIView
mulle-sde api cat UIViewController
mulle-sde code search "DebuggingFlags"
mulle-sde code search "dumpWithIndent"
mulle-sde code search "locationInView:"
mulle-sde code search "drawCallTracer"
```

## Main probes

| Need | Start with |
| --- | --- |
| See the actual view/layer tree | `dump`, `nameUTF8String`, `demo/src/main-contentmode.m`, `demo/src/main-click.m` |
| Trace layout or hit-testing decisions | `UIViewDebuggingFlags`, `src/UIView+DebugPrivate.h`, `src/UIView+UIEvent.m` |
| Diagnose wrong event coordinates | `UIInputEvent+UIView`, `demo/src/main-click.m`, `test/20-subview/conversion.m` |
| Diagnose controller forwarding loops | `UIViewController`, `demo/src/main-controller.m` |
| Check whether a view can draw at all | `+layerClass`, `UINullLayer`, `drawCallTracer`, `demo/src/main-layer.m` |

## Local references

- `src/UIView.h`
- `src/UIView.m`
- `src/UIView+DebugPrivate.h`
- `src/UIView+UIEvent.h`
- `src/UIView+UIEvent.m`
- `src/UIInputEvent+UIView.h`
- `src/UIInputEvent+UIView.m`
- `src/UIViewController.h`
- `src/UINullLayer.h`
- `demo/src/main-click.m`
- `demo/src/main-controller.m`
- `demo/src/main-contentmode.m`
- `demo/src/main-layer.m`
- `test/10-frame/frame.m`
- `test/20-subview/conversion.m`

## Local workflow

- Give important views stable names with `setNameUTF8String:` before dumping. The demos and layout tests do this so the dump output is readable.
- Start with `[window dump]` or `[view dump]`. The dump walks tracking areas, layers, then subviews, so it is the quickest local snapshot of hierarchy, z-order, and layer choice.
- Enable library logging before startup with `UIViewDebuggingFlags`. `+[UIView initialize]` also accepts the fallbacks `UIResponderDebuggingFlags` and `UIDebuggingFlags`. Useful bits from `src/UIView+DebugPrivate.h` are `0x1` general, `0x2` event, `0x4` layout, `0x40` display bits, `0x1000` verbose, `0x2000` verbose events, `0x01000000` tracking, and `0x02000000` mouse motion.
- Set `drawCallTracer` on a view when you need layer draw tracing. `UIView` forwards the `FILE *` to its main layer and extra layers.
- Build your app with `mulle-sde craft --debug` when you need the debug-only helpers in `src/UIView.m`; `UIViewDumpLayers`, `UIViewDumpSubviews`, and `UIViewDumpTrackingAreas` only exist under `#ifdef DEBUG`.

## Common failure modes

- A plain `UIView` starts with `UINullLayer`, so layout and events can be correct while nothing visible draws. Check `+layerClass` first.
- Use `[event locationInView:self]` for diagnostics. `_locationForView:` is only valid inside the hit-test plumbing; `demo/src/main-click.m` shows it intentionally as an internal check, not public usage.
- Views with `hidden == YES`, `userInteractionEnabled == NO`, or `alpha < 0.01` drop out of hit testing together with their subtrees.
- `pointInside:withEvent:` checks both `contentRect` and `bounds`, so padding, bounds origin, and clipping can all explain misses.
- In controller-mediated input, forward peer events with `handleForwardedEvent:`. Sending them back through `handleEvent:ofView:` recurses; `demo/src/main-controller.m` shows the safe path.
- If resize behavior aborts or makes no sense, check for mixed modern and legacy autoresizing bits. Local code treats that as an error unless `UIViewAutoresizingMixedMode` is present.

## Verify/report

- Include the debug flag mask you used, plus a short `dump` excerpt with view names.
- Name the closest reproducer in `demo/src/` or `test/` and state whether the bug is hierarchy/z-order, geometry/conversion, controller forwarding, or missing drawing-layer setup.
