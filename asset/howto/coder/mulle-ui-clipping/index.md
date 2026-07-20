<!-- keywords: clipping, clip, clipsToBounds, masksToBounds, scissor, overflow, bounds, layer-clipping, view-clipping -->
# mulle-ui-clipping

Two independent clipping mechanisms exist — one on UIView, one on CALayer.
Both default to YES (clip enabled). You must disable **both** if your layer
draws outside its frame.

## View clipping: `clipsToBounds`

```objc
@property BOOL clipsToBounds;  // UIView, default: YES
```

Controls whether the view's frame is intersected into the `clipRect` passed
to its layers during the render-queue walk (`UIView+RenderQueue.m`).

- `YES` — layers receive a `clipRect` clamped to the view's frame
- `NO`  — layers inherit the parent view's clipRect unchanged

**Disable with:** `[view setClipsToBounds:NO]`

## Layer clipping: `masksToBounds`

```objc
@property BOOL masksToBounds;  // CALayer, default: YES
```

Controls whether `renderInContext:` applies a scissor rectangle to the
graphics context before drawing.  The scissor is the layer's own frame
(set as `clipRect` from the render queue).

- `YES` — drawing is scissored to layer bounds
- `NO`  — drawing is unconstrained (can extend beyond layer frame)

**Disable with:** `[layer setMasksToBounds:NO]`

## How they interact

The two mechanisms are independent and stack:

1. **Render queue** walks the view tree. If a view has `clipsToBounds:YES`,
   it intersects its frame into the `clipRect` that gets passed down to
   child layers.
2. **Layer rendering** receives the `clipRect`. If the layer has
   `masksToBounds:YES`, it applies that rect as a scissor before drawing.

So `clipsToBounds` decides what clipRect the layer GETS.
`masksToBounds` decides whether the layer USES it.

## Which to disable and when

| Situation | Disable | Why |
|-----------|---------|-----|
| Layer draws outside its own frame (deform bulge, thick stroke, glow) | `[layer setMasksToBounds:NO]` | The layer's own scissor would cut off the overflow |
| Child views/layers should overflow the parent | `[parentView setClipsToBounds:NO]` | Otherwise the parent's frame is intersected into children's clipRect |
| Both: a child layer draws outside AND the parent would clip it | Disable both | The child needs `masksToBounds:NO` to draw freely, and the parent needs `clipsToBounds:NO` to not constrain the clipRect |

**Rule of thumb:**
- Drawing overflow in YOUR OWN layer → `masksToBounds:NO` on that layer
- Drawing overflow that escapes the PARENT view → `clipsToBounds:NO` on the parent
- Usually you need both, because the view clips its own layers too

## Do NOT touch `clipRect` directly

`clipRect` on the layer is managed by the render-queue walk. Setting it
manually will be overwritten on the next frame. Use `clipsToBounds` and
`masksToBounds` to control clipping behaviour.

## Quick reference

| Want to…                         | Set                              |
|----------------------------------|----------------------------------|
| Let subviews overflow            | `[parentView setClipsToBounds:NO]` |
| Let layer draw outside its frame | `[layer setMasksToBounds:NO]`    |
| Allow both                       | Set both on view AND layer       |
