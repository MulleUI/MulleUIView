<!-- keywords: quirks, animation, last-write-wins, preLayoutAnimator, postLayoutAnimator, layout, render-pipeline, CAAnimator -->
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

## No rotation or render-state animation on `UIView`

`UIView` animation is intentionally narrow: `padding`, `margins`, `frame`, `bounds`, `alpha`. Put rotation and other render-state animation on the layer with a layer-resident animation instead.
