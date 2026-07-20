<!-- keywords: verify, animation, CAAnimator, CATransaction, debug-flags, dump, tracing -->
# mulle-ui-animation

Load this when verifying app code that uses `CATransaction`, `CAAnimator`, or layer-resident animations.

## Understand first

```bash
mulle-sde api apropos CAAnimation
mulle-sde api cat CAAnimator
mulle-sde api cat CATransaction
mulle-sde code search "numberOfActiveAnimations"
mulle-sde code search "dumpWithIndent"
```

## Main probes

| Need | Start with |
| --- | --- |
| Inspect active/running/finished animations | `CAAnimator` `numberOfActiveAnimations`, `numberOfRunningAnimations`, `numberOfFinishedAnimations`, `getAnimations:maxCount:animationID:animationObject:` |
| Identify animation targets | Give views/layers a stable `nameUTF8String`, then `dumpWithIndent:` |
| Trace animation ticks | `CAAnimationDebuggingFlags=0x7`, build with `mulle-sde craft --debug` |
| Verify pipeline order | `UIWindow+Render.m`, `UIWindow+Layout.m`, `UIWindow+RenderQueue.m` |
| Confirm which animator | Check `preLayoutAnimator` vs `postLayoutAnimator` counts |

## Local references

- `src/CAAnimator.h`
- `src/CAAnimator.m`
- `src/CATransaction.h`
- `src/CAAnimation.h`
- `src/CAAnimationGroup.h`
- `src/UIWindow+Render.m`
- `src/UIWindow+Layout.m`
- `src/UIWindow+RenderQueue.m`
- `src/CALayer.h`
- `demo/src/main-uiview.m`

## Local workflow

- Enable debugging flags before creating any `CAAnimation`/`CALayer` — they're read at class init.
- Give important views/layers stable names with `setNameUTF8String:` before dumping.
- Start with animator inventory: check how many animations are active, running, and finished on both `preLayoutAnimator` and `postLayoutAnimator`.
- For layer-resident animations, call `dumpWithIndent:` on the layer and look for animation state.
- Verify pipeline order matches the spec: style → preLayout → layout → postLayout → createRenderQueue → animateRenderQueue → render.

## Common failure modes

- Animation added to an animator that isn't connected to a window — window animators only tick when the window runs the pipeline.
- Using `preLayoutAnimator` for appearance-only animation — works but forces unnecessary layout passes. Move to `postLayoutAnimator`.
- Using `postLayoutAnimator` for frame changes — layout never sees the change, so children don't reflow.
- Layer-resident animation on a `UINullLayer` — nothing draws. Check `+layerClass` returns a drawing layer.
- Transaction not committed — `[ta commit]` must be called to produce the group.

## Verify/report

- Include animator inventory counts and a dump excerpt with view/layer names.
- Name the closest reproducer in `demo/src/` and state whether the bug is animator choice, timing, transaction setup, or layer configuration.
