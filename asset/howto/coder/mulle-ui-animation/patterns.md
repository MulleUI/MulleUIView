<!-- keywords: patterns, CATransaction, CAAnimationGroup, preLayoutAnimator, postLayoutAnimator, CAAnimator, animation, frame, opacity -->
# mulle-ui-animation patterns

## Layout-changing animation → `preLayoutAnimator`

```objc
ta = [CATransaction instance];
[ta begin];
{
   [ta setAnimationCurve:UIViewAnimationCurveEaseInOut];
   [ta setAnimationDuration:0.6];
   [view setFrame:CGRectMake( 150, 150, 300, 300)];
}
group = [ta commit];
[[window preLayoutAnimator] addAnimation:group];
```

The frame change is visible to layout, so children reflow.

## Appearance-only animation → `postLayoutAnimator`

```objc
ta = [CATransaction instance];
[ta begin];
{
   [ta setAnimationCurve:UIViewAnimationCurveEaseIn];
   [ta setAnimationDuration:0.2];
   [layer setOpacity:0.6];
}
group = [ta commit];
[[window postLayoutAnimator] addAnimation:group];
```

No layout pass is forced. The animated opacity wins over whatever layout might have written.

## Static / layer-resident animation (spinner, pulse, glow)

```objc
// layer is a CALayer subclass that owns its own animation
[layer addAnimation:animation];
// ticks at step 6 independently of the pre/post split
```

These live on the layer and tick by walking the render queue. Use for persistent, self-contained effects.

## Container resize with child reflow

```objc
ta = [CATransaction instance];
[ta begin];
{
   [ta setAnimationDuration:0.4];
   [container setFrame:newFrame];
   [container layout];   // capture end-state child frames into the group
}
group = [ta commit];
[[window preLayoutAnimator] addAnimation:group];
```

Calling `[container layout]` inside the transaction captures the laid-out child frames into the same group, so children animate smoothly to their new positions.

## Mixed effect (two transactions, one clock)

```objc
// frame change → pre (layout observes it)
ta1 = [CATransaction instance];
[ta1 begin];
{
   [ta1 setAnimationDuration:0.5];
   [view setFrame:CGRectMake( 0, 0, 200, 200)];
}
group1 = [ta1 commit];
[[window preLayoutAnimator] addAnimation:group1];

// background color → post (layout also writes color, animation wins)
ta2 = [CATransaction instance];
[ta2 begin];
{
   [ta2 setAnimationDuration:0.5];
   [view setBackgroundColor:highlightColor];
}
group2 = [ta2 commit];
[[window postLayoutAnimator] addAnimation:group2];
```

Both groups stay in lockstep automatically — animation progress is a function of the shared `absoluteTime`/`animationRate` clock.
