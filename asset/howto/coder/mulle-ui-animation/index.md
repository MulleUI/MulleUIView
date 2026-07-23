<!-- keywords: animation, CAAnimator, CATransaction, CAAnimationGroup, preLayoutAnimator, postLayoutAnimator, render-pipeline, CALayer -->
# mulle-ui-animation

Use this topic for MulleUI's animation system: the per-frame render pipeline, static vs dynamic animations, the `preLayoutAnimator`/`postLayoutAnimator` split, and authoring animated transitions.

## Understand first

```bash
mulle-sde api apropos CAAnimation
mulle-sde api apropos CATransaction
mulle-sde code search preLayoutAnimator
mulle-sde code search postLayoutAnimator
mulle-sde code search animateWithAbsoluteTime
mulle-sde code search CAAnimator
mulle-sde code search CAAnimationGroup
```

## Core principle

MulleCA writes each animation's interpolated value **directly onto the real object every tick.** While an animation runs, the live property *is* the animated value; when it finishes, the final value stays in place. **The last write to a property within a frame is what appears on screen.**

## Per-frame render pipeline

Each frame, a window runs this sequence (`UIWindow+Render.m`, `UIWindow+Layout.m`, `UIWindow+RenderQueue.m`):

```
1. style                apply the stylesheet (when needed)
2. preLayoutAnimations  tick the preLayoutAnimator
3. layout               reflow the view tree (when needed)
4. postLayoutAnimations tick the postLayoutAnimator (every frame)
5. createRenderQueue    flatten view tree into ordered CALayer list
6. animateRenderQueue   tick layer-resident animations
7. render               draw the layer queue
```

Key takeaways:
- Layout runs between `preLayout` and `postLayout` — `preLayout` feeds layout, `postLayout` wins over layout.
- Both animators tick before `createRenderQueue`, so their values are baked into transforms and drawing.

## Two kinds of animation

| | Static (layer-resident) | Dynamic (view-driven) |
|---|---|---|
| **Stored on** | the layer | the window's pre/post animator |
| **Discovered by** | walking the render queue (visible layers) | the animator's own storage |
| **Ticks at step** | 6 (after `createRenderQueue`) | 2 or 4 (before `createRenderQueue`) |

## Choosing an animator

> **Does the animation change layout?**
> - **Yes → `preLayoutAnimator`.** Frame/bounds changes, or anything layout must observe.
> - **No → `postLayoutAnimator`.** Appearance-only changes, or a value that should take precedence over what layout wrote.

## Main surfaces

| Scenario | Start with |
| --- | --- |
| Frame/bounds animation that should reflow children | `preLayoutAnimator`, `CATransaction`, `CAAnimationGroup` |
| Opacity/color/paint animation (no reflow) | `postLayoutAnimator`, `CATransaction`, `CAAnimationGroup` |
| Looping spinner, pulse, highlight | `CALayer addAnimation:`, layer-resident animation |
| Container resize + child reflow | `preLayoutAnimator` + `[view layout]` inside transaction |
| Mixed effect (layout + appearance) | Two transactions, one per animator |

## Local references

- `src/UIView.h` (animatable properties, rawFrame, animationStorage)
- `src/UIWindow+Render.m`
- `src/UIWindow+Layout.m`
- `src/UIWindow+RenderQueue.m`
- `src/CAAnimator.h`
- `src/CAAnimationGroup.h`
- `src/CATransaction.h`
- `src/CAAnimation.h`
- `src/CALayer.h`
- `demo/src/main-view-pathanimation.m`
- `demo/src/main-autoresize-legacy.m`
