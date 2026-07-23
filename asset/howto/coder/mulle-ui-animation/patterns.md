<!-- keywords: patterns, CATransaction, CAAnimationGroup, preLayoutAnimator, postLayoutAnimator, CAAnimator, animation, frame, opacity, CABasicAnimation, CAPathAnimation, rawFrame, setFrameRateHz, willLayoutCallback -->
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

## `CABasicAnimation` on layer properties

Use `CABasicAnimation` to animate a single property on a layer (color, position, etc.):

```objc
colorProperty = MulleObjCInstanceSearchProperty( layer, @selector(fillColor));
if( colorProperty)
{
   options = CABasicAnimationOptionsMakeEaseInOut(
                mulle_relativetimerange_make( 0.0, 2.0),  // delay, duration
                INFINITY,                                   // repeat count
                YES);                                       // autoreverse

   anim = [[[CABasicAnimation alloc]
              initWithProperty:colorProperty
               startColorValue:CGColorMakeWithRGBA(1.0, 0.0, 0.0, 1.0)
                 endColorValue:CGColorMakeWithRGBA(0.0, 0.0, 1.0, 1.0)
                       options:&options] autorelease];

   [anim setAnimationObject:view];
   [[window postLayoutAnimator] addAnimation:anim];
}
```

`CABasicAnimationOptionsMakeEaseInOut` / `CABasicAnimationOptionsMakeLinear` control the timing curve.

## `CAPathAnimation` on layers

Use `CAPathAnimation` to animate a layer property along a `CGPath`:

```objc
pathOptions = CABasicAnimationOptionsMakeLinear(
                mulle_relativetimerange_make( 0.0, 4.0),
                INFINITY,
                NO);

anim = [[[CAPathAnimation alloc]
           initWithProperty:property
                       path:circlePath
              pathValueType:CAPathAnimationValuePositionAsOrigin
                    options:&pathOptions] autorelease];

[anim setAnimationObject:view];
[[window preLayoutAnimator] addAnimation:anim];
```

The `animationObject` associates the animation with a `UIView` (not a layer). The animator ticks the animation at the correct pipeline step based on which animator you choose.

## Per-frame window callbacks (continuous layout animation)

For time-driven animation that changes layout every frame, use window callbacks directly (`demo/src/main-autoresize.m`, `demo/src/main-autoresize-legacy.m`):

```objc
[window setFrameRateHz:30];
[window setWillLayoutViewsCallback:^( UIWindow *window, struct CGFrameInfo *info) {
   CGFloat  anim = fmod( info->now, 3.0) / 3.0;
   // compute per-frame positions and set frames
   [view setFrame:newFrame];
   [view setNeedsLayout];
}];
[window setDidRenderFrameCallback:^( ... ) {
   [(UIWindow *) window setNeedsLayout];
   return( UIWindowDisplayDidAnimate);
}];
```

`frameInfo->now` provides the current time for computing animation progress. Returning `UIWindowDisplayDidAnimate` from `didRenderFrameCallback` signals a continuous animation loop.

## Sub-pixel animation with `rawFrame`

Use `rawFrame` instead of `frame` when you need smooth sub-pixel movement:

```objc
[view setRawFrame:CGRectMake( x, y, w, h)];
```

`rawFrame` bypasses the `CGRectIntegral` rounding that `frame` applies. Use it for physics, game loops, and any animation where integer-pixel snapping would produce visible jitter. Reading `frame` still returns the rounded value; reading `rawFrame` returns the exact value.
