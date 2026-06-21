<!-- keywords: mulle-ui-hit-testing, quirks, bounds, contentRect, alpha, z-order -->
# Quirks

- `pointInside:withEvent:` checks both `contentRect` and `bounds`, so padding changes can affect hit areas.
- Hit testing mutates the event's per-view location cache. A point that looks correct may only be so because it was already walked through `hitTest:`.
- `hitSearchSubviews:withInputEventPointer:` may replace the event object mid-search (`demo/src/main-click.m` does this with an obscuring view).
- Subviews are tested in reverse order — z-order bugs are often event-delivery bugs in disguise.
- `clipsToBounds` defaults to YES; clicks outside a clipped child's visible area still fail hit testing even if the child's frame extends beyond.
