<!-- keywords: mulle-ui-hit-testing, hit-test, click, event-routing, locationInView, pointInside, UIView, UIInputEvent -->
# mulle-ui-hit-testing

Use this topic when a click lands in the wrong view, event coordinates are off, or hit testing doesn't behave as expected.

## Understand first

```bash
mulle-sde api apropos UIView
mulle-sde code search hitTest
mulle-sde code search locationInView
mulle-sde code search pointInside
mulle-sde code search hitSearchSubviews
```

## Local references (MulleUIView)

- `src/UIView+UIEvent.h`
- `src/UIInputEvent+UIView.h`
- `demo/src/main-click.m`
- `demo/src/main-click-simple.m`

## How hit testing works

1. The window receives an event with a window-space point
2. `hitTest:withEvent:` walks the view tree in reverse subview order (front-to-back)
3. Views are excluded if: hidden, `userInteractionEnabled == NO`, or `alpha < 0.01`
4. `pointInside:withEvent:` checks both `contentRect` and `bounds`
5. The deepest matching view receives the event

## Getting local coordinates

Always use:

```objc
CGPoint   point = [event locationInView:self];
```

Do NOT use `_locationForView:` — that's internal hit-test plumbing.

## Views excluded from hit testing

A view and **all its subtrees** are excluded when:
- `[view isHidden]` is YES
- `[view userInteractionEnabled]` is NO
- `[view alpha]` < 0.01

## Z-order affects hit order

Hit testing walks subviews in reverse order. The frontmost subview (last added or brought to front) gets tested first. Z-order bugs and event-delivery bugs often share a root cause.

## Event mutation during hit search

`hitSearchSubviews:withInputEventPointer:` can **replace** the event object before propagation continues. This is used for obscuring views that redirect events (see `demo/src/main-click.m`).
