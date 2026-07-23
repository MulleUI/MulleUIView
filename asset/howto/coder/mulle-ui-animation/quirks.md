<!-- keywords: quirks, animation, last-write-wins, preLayoutAnimator, postLayoutAnimator, layout, render-pipeline, CAAnimator, rawFrame, animationObject, CABasicAnimation, CAPathAnimation, UI_VIEW_ANIMATABLE_PROPERTIES, setFrameRateHz -->
# mulle-ui-animation quirks

## The last write wins

Because MulleCA writes interpolated values directly onto the real object, **the last write in the frame wins.** This means:

- A `postLayout` animation overrides whatever `layout` wrote for the same property.
- A `preLayout` animation is visible to `layout`, so `layout` can react to and potentially override it.

## `postLayout` runs every frame; `preLayout` only when layout is needed

`postLayoutAnimator` ticks every frame regardless. `preLayoutAnimator` ticks when layout is running — the window ensures a layout pass whenever a preLayout animation is active. This means appearance-only animations in `post` never force a wasteful reflow.

## Layer-resident animations tick after `createRenderQueue`

Static animations on layers tick at step 6, after the render queue is built. This means they animate baked transform values and do not interact with layout at all. They are purely visual.

## A `CATransaction` captures the *current* values

When you commit a transaction, the group captures the difference between the value at `[ta begin]` and the value at `[ta commit]`. If you modify the property further after `[ta begin]` but before `[ta commit]`, the animation interpolates from the first change, not the initial state.

## Multi-layer views need one group per animator

A single `CAAnimationGroup` can target several layers. If your view has multiple layers and you need different timing for different layers, use separate transactions — the shared clock keeps them in sync.

## Only a fixed set of properties is animatable on `UIView`

Defined by the `UI_VIEW_ANIMATABLE_PROPERTIES` macro in `src/UIView.h:13`:

```objc
@property( observable) UIEdgeInsets   padding;
@property( observable) UIEdgeInsets   margins;
@property( observable) CGRect         frame;
@property( observable) CGRect         bounds;
@property( observable) CGFloat        alpha
```

For all other animation (rotation, color, transform, path), animate the **layer** directly using `CABasicAnimation`, `CAPathAnimation`, or layer-resident animations.

## `rawFrame` vs `frame` for sub-pixel animation

`frame` applies `UIViewIntegralFrame` (rounds to `UIViewFrameIntegralFuzz == 0.01`). `rawFrame` (src/UIView.h:267) bypasses this rounding entirely. Use `rawFrame` for sub-pixel animation and game physics. Reading `frame` always returns the integral-rounded value.

## `animationObject` associates an animation with a view

`CABasicAnimation` and `CAPathAnimation` use `[anim setAnimationObject:view]` to associate the animation with a `UIView`. The animator (pre/post) ticks it at the correct pipeline step. Do not set a layer as the animation object — the animator expects views.

## Window callbacks for per-frame animation

`setWillLayoutViewsCallback:` and `setDidRenderFrameCallback:` on `UIWindow` provide a lower-level per-frame hook (`demo/src/main-autoresize.m`). The callback receives `struct CGFrameInfo` with `now` (absolute time). Use `setFrameRateHz:` to control the frame rate. Return `UIWindowDisplayDidAnimate` from `didRenderFrameCallback` to keep the animation loop alive.

## `_snapshot` and `_animationStorage` are internal

`UIView` has internal ivars `_snapshot` (holds `UIAnimatableViewProperties` state before animation) and `_animationStorage` (CAAnimationStorage). Both must be `nil` during `mulleGainAccess`/`mulleRelinquishAccess` — the implementation asserts this. Never touch them directly.

## `forgetImplicitAnimations` on layers

Layers implement `forgetImplicitAnimations` to discard pending implicit animations (`UINullLayer.m:53`). This is called during the render pipeline to clear any auto-animations before the next frame writes new values.

## `willLayoutWithAbsoluteTime:` view callback

Each view receives `willLayoutWithAbsoluteTime:` (src/UIView.m:1126) before the layout pass. Override to capture pre-layout state or return `UIWindowDisplayBits` flags. The default returns 0.

## No rotation or render-state animation on `UIView`

`UIView` animation is intentionally narrow: `padding`, `margins`, `frame`, `bounds`, `alpha`. Put rotation and other render-state animation on the layer with a layer-resident animation instead.
