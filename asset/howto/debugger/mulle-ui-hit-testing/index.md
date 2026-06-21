<!-- keywords: debugger, mulle-ui-hit-testing, click, wrong-view, coordinates, bounds -->
# mulle-ui-hit-testing

Use this when clicks land in the wrong view or event coordinates don't match expectations.

## Local references (MulleUIView)

- `src/UIView+UIEvent.h`
- `src/UIInputEvent+UIView.h`
- `demo/src/main-click.m`
- `demo/src/main-click-simple.m`
- `test/20-subview/conversion.m`
- `test/20-subview/bounds-zoom.m`

## Debugging workflow

1. **Click goes to wrong view?**
   - Check z-order — hit testing walks subviews in reverse (frontmost first)
   - Check `isHidden`, `userInteractionEnabled`, `alpha` — these exclude entire subtrees
   - Check `clipsToBounds` on ancestors — clicks outside clipped bounds fail

2. **Coordinates off by a constant offset?** Check `bounds.origin`. A custom bounds origin survives `setFrame:` changes and shifts all coordinate conversion.

3. **Coordinates off by a scale factor?** Check `bounds.size` vs `frame.size`. When they differ, conversion scales — see `test/20-subview/bounds-zoom.m`.

4. **Event arrives but `locationInView:` is wrong?** Don't rely on `_locationForView:` — use `[event locationInView:self]`. The internal cache is only valid inside the hit-test walk.

5. **Event seems to be replaced?** `hitSearchSubviews:withInputEventPointer:` can replace the event object. Check if an obscuring view is doing coordinate remapping (`demo/src/main-click.m`).

## Quick diagnostic

```objc
printf( "hit: %s at %s\n",
        [[self shortDescription] UTF8String],
        CGPointUTF8String( [event locationInView:self]));
```
