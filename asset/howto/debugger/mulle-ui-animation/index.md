<!-- keywords: debugger, animation, CAAnimator, CATransaction, animation-debugging, frame-timing, wrong-animation, preLayout, postLayout -->
# mulle-ui-animation

Use this when an animation doesn't play, plays with wrong values, fights with layout, or appears at the wrong time.

## Local references

- `src/CAAnimator.h`
- `src/CATransaction.h`
- `src/CAAnimation.h`
- `src/UIWindow+Render.m`
- `src/UIWindow+Layout.m`
- `src/UIWindow+RenderQueue.m`
- `demo/src/main-uiview.m`

## Debugging workflow

1. **Animation doesn't play at all?**
   - Check that the group was added to an animator with `addAnimation:`.
   - Confirm the animator is connected to a window — only window animators tick.
   - For layer-resident animations, confirm the layer is in the render queue (visible and attached to a window).

2. **Animation plays but the value is wrong?**
   - Check which animator you used. If layout also writes the property, a `preLayout` animation may be overridden by layout. Move to `postLayoutAnimator` to make the animation the last write.
   - Verify the transaction captured the correct before/after values — modifying the property before `[ta begin]` changes the start state.

3. **Animation fights with layout?**
   - For frame/bounds changes: ensure you're using `preLayoutAnimator` so layout sees the new frame and reflows children.
   - For appearance properties layout also writes: use `postLayoutAnimator` so the animated value takes precedence.

4. **Animation timing is off?**
   - Multiple groups animate in lockstep because all ticking uses the same `absoluteTime`/`animationRate` clock. If one group finishes earlier, check its duration.
   - Layer-resident animations use their own timing but still share the frame clock.

5. **Static layer animation doesn't appear?**
   - Confirm the layer is a drawing layer (not `UINullLayer`) — plain `UIView` starts with `UINullLayer`.
   - Confirm the animation was added with `[layer addAnimation:]` and the layer is in the visible tree.

## Quick diagnostic

```bash
export CAAnimationDebuggingFlags=0x7     # general, interpolation, state-transition
export CALayerDebuggingFlags=0x1041      # general, display-bits, verbose
```

Set these before the first `CAAnimation`/`CALayer` creation (read at class init).

```objc
printf( "pre  active: %u\n",  [[window preLayoutAnimator]  numberOfActiveAnimations]);
printf( "post active: %u\n",  [[window postLayoutAnimator] numberOfActiveAnimations]);
printf( "pre  run:    %u\n",  [[window preLayoutAnimator]  numberOfRunningAnimations]);
printf( "post run:    %u\n",  [[window postLayoutAnimator] numberOfRunningAnimations]);
```

For inventory, use `getAnimations:maxCount:animationID:animationObject:` on the animator.
