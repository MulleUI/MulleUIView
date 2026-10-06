# MulleUIView Library Documentation for AI
<!-- Keywords: view, hierarchy, layout, events, layer -->

## 1. Introduction & Purpose

**MulleUIView** is a foundational UI framework component that provides hierarchical view management, layout functionality, and event routing. It separates presentation (handled by `CALayer` or other `UILayer` protocol adopters) from structure and interaction. A `UIView` does not draw directly; instead, it positions and organizes layers, manages a parent-child hierarchy of subviews, and routes user input events from the application or window to the appropriate handler code. This library is part of the MulleUI framework and depends on **MulleUIApplication** for event and application abstractions.

**Version:** `MULLE_UI_VIEW_VERSION` is `((0UL << 20) | (0 << 8) | 3)` defined in `MulleUIView.h`.

**Related Layout Views:** The UIView ecosystem includes specialized layout-only subclasses like **UIGridView**, **UIStackView**, and **UIScrollView** that provide advanced layout strategies without drawing.

## 2. Key Concepts & Design Philosophy

### Separation of Concerns
`UIView` strictly separates layout and event handling from drawing. All rendering is delegated to objects conforming to the `UILayer` protocol (typically `CALayer`). This allows the same view hierarchy to work with different rendering backends.

### Hierarchical Structure
Views form a tree structure with parent (`superview`) and children (`subviews`). Each view maintains its own coordinate space defined by `frame` (position relative to superview) and `bounds` (internal coordinate space for subviews and layers).

### Coordinate Spaces
- **Frame**: Position and size relative to the superview's `bounds`.
- **Bounds**: The internal coordinate space where subviews and layers are positioned. Normally `bounds.origin` is `(0,0)` and `bounds.size` equals `frame.size`, but changing `bounds.origin` can scroll content, and changing `bounds.size` can scale content.
- **Content Rect**: The area available for subviews after accounting for padding, calculated as `{ CGPointZero, bounds.size }` by default.

### Layout System
The layout system supports two modes:
1. **Content Mode (Modern)**: Uses `autoresizingMask` with content mode values like `UIViewAutoresizingScaleToFill`, `UIViewAutoresizingCenter`, `UIViewAutoresizingTop`, etc. This approach uses `margins` and `padding` to control placement and respects the initial frame as a sizing hint.
2. **Flexible Mode (Legacy)**: Uses `UIViewAutoresizingFlexible*` flags (e.g., `UIViewAutoresizingFlexibleWidth`, `UIViewAutoresizingFlexibleTopMargin`) to describe how a view should resize when its superview changes size. This ignores `margins` but respects `padding`.

### Event Distribution
Input events (mouse, keyboard, touch) are routed through the view hierarchy using hit testing. The `hitTest:withEvent:` method walks the view tree to find the deepest view that contains the event location and is eligible to receive events (visible, user interaction enabled, not transparent).

### Thread Safety
Views are created with `-initNoLock` for efficiency. They become thread-safe when added to a `UIWindow`, which assigns them a lock. All layers added to a view inherit the same lock.

### Animation Support
`UIView` supports observable properties (`frame`, `bounds`, `alpha`, `padding`, `margins`) that can be animated. Animation state is stored in an internal `_animationStorage` structure.

## 3. Core API & Data Structures

### 3.1. `UIView.h`

#### `@interface UIView`
The primary class representing a view in the hierarchy.

**Purpose:** Manages layers, subviews, layout, and event routing.

**Key Properties:**
- `@property(assign) id<UIWindow> window`: The window containing this view (set automatically).
- `@property(assign) UIViewController *controller`: Optional controller for event handling logic.
- `@property(getter=isHidden) BOOL hidden`: Visibility flag (default: NO).
- `@property(getter=isUserInteractionEnabled) BOOL userInteractionEnabled`: Whether view accepts input events (default: YES).
- `@property(observable) CGRect frame`: Position and size in superview coordinates (uses integer-pixel rounding via `UIViewMakeFrameWithRect`).
- `@property(observable) CGRect rawFrame`: Position and size without integer-pixel rounding. Use for sub-pixel animation and game physics.
- `@property(observable) CGRect bounds`: Internal coordinate space for subviews/layers.
- `@property(observable) CGFloat alpha`: Opacity (0.0 to 1.0).
- `@property(observable) UIEdgeInsets padding`: Insets from bounds to contentRect.
- `@property(observable) UIEdgeInsets margins`: Distance from superview edges or sibling views.
- `@property(assign) UIViewAutoresizing autoresizingMask`: Defines layout behavior.
- `@property(assign) NSInteger tag`: User-defined identifier for finding views.
- `@property(assign) CGPoint anchorPoint`: Point within bounds used for positioning (default: {0.5, 0.5}).
- `@property BOOL clipsToBounds`: Whether subviews are clipped to bounds (default: YES).
- `@property BOOL needsCaching`: Flags that the view should be cached as a framebuffer.
- `@property(assign) UIViewEventCallback *eventCallback`: C function pointer for custom event handling.
- `@property(assign) UIViewMouseMotionEventCallback *mouseMotionEventCallback`: C function pointer for mouse motion events.
- `@property(dynamic) char *nameUTF8String`: Debugging/styling identifier.
- `@property(dynamic) char *classUTF8String`: CSS-like class identifier for styling.

**Optional Subclass Methods (declared `@optional` in main interface):**
- `+ (Class) layerClass`: Override to return a custom `UILayer` class (default is `UINullLayer`).
- `- (void) setNeedsDisplay`: Default is a no-op on `UIView`.

**Lifecycle Functions:**
- `+ (instancetype) viewWithFrame:(CGRect)frame`: Factory method to create a view.
- `+ (instancetype) viewWithLayer:(id<UILayer>)layer`: Factory method with a custom layer.
- `- (instancetype) initWithLayer:(id<UILayer>)layer frame:(CGRect)frame`: Designated initializer.
- `- (instancetype) initWithFrame:(CGRect)frame`: Convenience initializer (creates a `UINullLayer`).

**Hierarchy Management:**
- `- (void) addSubview:(UIView *)view`: Adds a subview (alias for `addToSubviews:`).
- `- (void) addToSubviews:(UIView *)view`: Adds a subview at the end.
- `- (void) removeFromSubviews:(UIView *)view`: Removes a specific subview.
- `- (void) removeFromSuperview`: Removes self from superview.
- `- (void) removeAllSubviews`: Removes all subviews.
- `- (void) removeAllSubviewsOfClass:(Class) class`: Removes all subviews of a given class.
- `- (void) sortSubviewsByOrigin`: Sorts subviews by their origin position.
- `- (void) getSubviewsIntersectingRect:(CGRect)rect intoPointerArray:(struct mulle_pointerarray *)views invertIntersectionTest:(BOOL)flag`: Finds subviews intersecting a rect.
- `- (UIView *) superview`: Returns the parent view.
- `- (UIView *) subviewAtIndex:(NSUInteger)index`: Gets subview by index.
- `- (UIView *) subviewWithTag:(NSInteger)tag`: Finds immediate child with tag.
- `- (UIView *) findViewWithTag:(NSInteger)tag`: Deep search for descendant with tag.
- `- (NSInteger) getSubviews:(UIView **)buf range:(NSRange)range`: Copies subviews to buffer.
- `- (NSUInteger) numberOfSubviews`: Returns subview count.

**Layer Management:**
- `- (id<UILayer>) layer`: Returns the main layer.
- `- (void) addLayer:(id<UILayer>)layer`: Adds an additional layer.
- `- (void) removeAllLayers`: Removes all layers except main layer.
- `- (id<UILayer>) layerWithTag:(NSInteger)tag`: Finds layer by tag.
- `- (NSInteger) getLayers:(id<UILayer> *)buf range:(NSRange)range`: Copies layers to buffer.
- `- (BOOL) isMultiLayer`: Returns YES if more than one layer exists.

**Coordinate Conversion:**
- `- (CGRect) contentRect`: Returns the area for subviews (bounds minus padding).
- `- (CGPoint) locationForContentLocation:(CGPoint)contentLocation`: Converts from content space to view space.
- `- (CGPoint) contentLocationForLocation:(CGPoint)location`: Converts from view space to content space.

**Lifecycle Callbacks:**
- `- (void) didAddSubview:(UIView *)view`: Called after adding a subview.
- `- (void) willRemoveSubview:(UIView *)subview`: Called before removing a subview.
- `- (void) willMoveToSuperview:(UIView *)newSuperview`: Called before moving to new superview.
- `- (void) didMoveToSuperview:(UIView *)newSuperview`: Called after moving to new superview.
- `- (void) willMoveToWindow:(id<UIWindow>)newWindow`: Called before moving to new window.
- `- (void) didMoveToWindow:(id<UIWindow>)newWindow`: Called after moving to new window.

**Debugging:**
- `- (void) dump`: Prints view hierarchy to stdout.
- `- (void) dumpWithIndent:(NSUInteger)indent FILE:(FILE *)fp`: Prints view hierarchy with indentation.

**Macros:**
- `UIViewSubviewsCount(self)`: Fast inline access to subview count.
- `UIViewSubviewsFor(self, subview)`: Fast enumeration over subviews.
- `UIViewLayersFor(view, layer)`: Fast enumeration over layers.

#### `@protocol UILayer`
Defines the interface for drawable layers managed by `UIView`.

**Purpose:** Abstracts the rendering backend from the view hierarchy.

**Key Properties:**
- `@property(observable) CGRect frame`: Layer position/size in view bounds.
- `@property(observable) CGRect bounds`: Layer's internal coordinate space.
- `@property(assign) CGFloat rotation`: Rotation angle in radians.
- `@property(assign) CGFloat alpha`: Opacity.
- `@property(assign) NSInteger tag`: User-defined identifier.
- `@property(assign) CGAffineTransform transform`: Transformation matrix for rendering.
- `@property(assign) CGRect clipRect`: Clipping rectangle.
- `@property(assign) char *nameUTF8String`: Debug name.

**Core Operations:**
- `- (instancetype) initWithFrame:(CGRect)frame`: Initialize with frame.
- `- (CGSize) sizeThatFits:(CGSize)size context:(id<UILayoutContext>)context`: Calculate preferred size.
- `- (void) layoutWithLayoutInfo:(struct UILayoutInfo *)info`: Position/size the layer during layout.
- `- (void) forgetImplicitAnimations`: Discard pending animations.

### 3.2. `UIViewController.h`

#### `@interface UIViewController`
Manages a group of views and handles their events and layout.

**Purpose:** Encapsulates application logic for a set of related views without retaining them (views are retained by the window).

**Key Properties:**
- `@property(assign) id<UIWindow> window`: The window containing the views.
- `@property(assign) BOOL isLayoutingViews`: If YES, `-layoutViews` is called during layout.

**Lifecycle Functions:**
- `+ (instancetype) objectWithView:(UIView *)view`: Factory method.
- `- (instancetype) initWithView:(UIView *)view`: Designated initializer.
- `- (UIView *) view`: Returns main view (alias for `mainView`).
- `- (UIView *) mainView`: Returns the primary view.

**View Management:**
- `- (void) addView:(UIView *)view`: Adds a view to the controller's views.
- `- (void) removeView:(UIView *)view`: Removes a view from the controller.
- `- (void) removeAllViews`: Removes all views.
- `- (UIView *) viewWithTag:(NSInteger)tag`: Finds a view by tag.
- `- (NSInteger) getViews:(UIView **)buf range:(NSRange)range`: Copies views to buffer.
- `- (BOOL) isMultiView`: Returns YES if controller manages multiple views.

**Event Handling:**
- `- (UIEvent *) handleEvent:(UIEvent *)event ofView:(UIView *)view`: Override to handle events for views.

**Layout Handling:**
- `- (BOOL) layoutView:(UIView *)view layoutInfo:(struct UILayoutInfo *)context autoresizingMask:(UIViewAutoresizing)autoresizingMask`: Override to provide custom layout for a view. Return YES if layout was handled.
- `- (void) layoutViews`: Override to layout all views (called if `isLayoutingViews` is YES).

**Lifecycle Callbacks:**
- `- (void) view:(UIView *)view didMoveToWindow:(id<UIWindow>)window`: Called when a view moves to a window.

### 3.3. `UIView+Layout.h`

#### Layout Methods
**Purpose:** Provides layout functionality for views and subviews.

**Core Operations:**
- `- (void) layout`: Main entry point. Calls `layoutLayers`, then `layoutSubviews`, then recursively layouts subviews.
- `- (void) layoutLayers`: Positions all layers within the view's bounds using `UILayoutInfo`.
- `- (BOOL) layoutSubviews`: Positions subviews within the content rect. Returns YES to continue recursive layout.
- `- (void) performLayoutOnSubviews`: Calls `-layout` on all subviews.

**Sizing:**
- `- (CGSize) sizeThatFits:(CGSize)size context:(id<UILayoutContext>)context`: Calculates preferred size given constraints.
- `- (CGSize) sizeThatFits:(CGSize)size`: Convenience method (context is nil).
- `- (void) sizeToFit`: Resizes view to fit its content.

**Layout Helpers:**
- `- (void) layoutWithLayoutInfo:(struct UILayoutInfo *)context autoresizingMask:(UIViewAutoresizing)autoresizingMask`: Positions the view using layout info and autoresizing rules.
- `- (void) setLayoutedFrame:(CGRect)frame autoresizingMask:(UIViewAutoresizing)autoresizingMask`: Sets frame and stores original frame for legacy resizing.
- `- (void) layoutSubview:(UIView *)subview inRect:(CGRect)contentRect autoresizingMask:(UIViewAutoresizing)autoresizingMask`: Legacy method for manual subview layout.
- `- (UILayoutStrategy) layoutStrategy`: Returns `UILayoutStrategyDefault`, `UILayoutStrategyContinue`, or `UILayoutStrategyStop`.
- `- (BOOL) isCulledByLayout`: Returns YES if view was set to zero size by layout (out of bounds).

**Layer Layout:**
- `- (void) layoutLayer:(id<UILayer>)layer layoutInfo:(struct UILayoutInfo *)info`: Generic layer layout.
- `- (void) layoutMainLayer:(id<UILayer>)layer layoutInfo:(struct UILayoutInfo *)info`: Layouts main layer (background/border).
- `- (void) layoutAuxillaryLayer:(id<UILayer>)layer layoutInfo:(struct UILayoutInfo *)info`: Layouts additional layers.

**Global Functions:**
- `void UIViewAutoresize(UIView *self, struct UILayoutInfo *info, UIViewAutoresizing autoresizingMask)`: Performs autoresizing.
- `void UIViewLayoutWithViewLayoutInfo(UIView *self, struct UILayoutInfo *context)`: Layouts view with context.
- `void UIViewLayoutSubviewInRect(UIView *self, UIView *view, CGRect contentRect)`: Layouts single subview.

**Helper Inline:**
- `struct UILayoutInfo UILayoutInfoMakeWithView(UIView *view)`: Creates layout info from view's content rect, padding, and layout context.

**Future API (`@interface UIView( LayoutFuture) < MulleObjCFuture>`):**
- `- (id <UILayoutContext>) layoutContext`: Returns layout context.
- `- (void) beginLayout:(void *)info` / `- (void) endLayout`: Paired begin/end for CGFrameInfo.
- `- (void) setNeedsLayout`: Marks view as needing layout (handled by UIWindow).
- `- (BOOL) needsLayout`: Checks if layout is needed.
- `- (void) layoutShadowLayer:(id <UILayer>)layer layoutInfo:(struct UILayoutInfo *)info`: Layouts shadow layer (future).

### 3.4. `UIView+UIEvent.h`

#### Event Handling Methods
**Purpose:** Provides event routing and hit testing.

**Hit Testing:**
- `- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event`: Returns YES if point is inside view bounds.
- `- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event`: Finds deepest subview containing point.
- `- (BOOL) directHitTest:(CGPoint)point withInputEvent:(UIInputEvent *)event`: Tests if view can accept event at point.
- `- (UIView *) hitSearchSubviews:(CGPoint)contentLocation withInputEventPointer:(UIInputEvent **)event_p`: Searches subviews for hit.

**Event Handling (UIResponder Protocol):**
- `- (UIEvent *) handleEvent:(UIEvent *)event`: Main event handler. Returns nil if event was consumed.
- `- (UIInputEvent *) handleInputEvent:(UIInputEvent *)event`: Handles input events (mouse, keyboard).
- `- (UIMouseMotionEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *)event`: Handles mouse motion separately.
- `- (UIEvent *) handleForwardedEvent:(UIEvent *)event`: Handles events forwarded by controller.

**Responder Chain:**
- `- (BOOL) becomeFirstResponder`: Attempts to become first responder.
- `- (BOOL) resignFirstResponder`: Resigns first responder status.
- `- (BOOL) isFirstResponder`: Checks first responder status.
- `- (id<UIResponder>) nextResponder`: Returns next responder in chain (usually superview).
- `- (void) didBecomeFirstResponder`: Callback when becoming first responder.
- `- (void) didResignFirstResponder`: Callback when resigning first responder.

**Subview/Layer Queries:**
- `- (UIView *) subviewAtContentLocation:(CGPoint)point`: Finds subview at point.
- `- (id<UILayer>) layerAtContentLocation:(CGPoint)point`: Finds layer at point.

### 3.5. `UIView+UIViewEditing.h`

#### Subview Reordering and Editing Methods
**Purpose:** Provides methods for manipulating the subview Z-order, inserting views at specific positions, and querying hierarchical relationships.

**Core Operations:**
- `- (BOOL) isDescendantOfView:(UIView *)view`: Returns YES if self is a descendant of the given view.
- `- (void) sendSubviewToBack:(UIView *)view`: Moves subview to the lowest Z-order.
- `- (void) bringSubviewToFront:(UIView *)view`: Moves subview to the highest Z-order.
- `- (void) insertSubview:(UIView *)view atIndex:(NSInteger)index`: Inserts at specific position.
- `- (void) insertSubview:(UIView *)view aboveSubview:(UIView *)other`: Inserts above sibling.
- `- (void) insertSubview:(UIView *)view belowSubview:(UIView *)other`: Inserts below sibling.
- `- (void) exchangeSubviewAtIndex:(NSInteger)index1 withSubviewAtIndex:(NSInteger)index2`: Swaps two subviews.
- `- (void) replaceSubview:(UIView *)view withView:(UIView *)other`: Replaces a subview with another.

### 3.6. `UIView+CGGeometry.h`

#### Coordinate Conversion Methods
**Purpose:** Converts coordinates between view spaces.

**Point Conversion:**
- `- (CGPoint) convertPoint:(CGPoint)pos toView:(UIView *)toView`: Converts point from self to another view. Pass nil for window coordinates.
- `- (CGPoint) convertPoint:(CGPoint)pos fromView:(UIView *)fromView`: Converts point from another view to self. Pass nil for window coordinates.

**Rect Conversion:**
- `- (CGRect) convertRect:(CGRect)rect toView:(UIView *)toView`: Converts rect to another view's space.
- `- (CGRect) convertRect:(CGRect)rect fromView:(UIView *)fromView`: Converts rect from another view's space.

**Visible Area:**
- `- (CGRect) visibleRect`: Returns visible portion in view's coordinate space (accounts for clipping and hidden ancestors).
- `- (CGRect) visibleWindowRect`: Returns visible portion in window coordinate space.

**Content Conversion:**
- `- (CGPoint) contentLocationForLocation:(CGPoint)location`: Converts from view space to content space (accounting for bounds transform).
- `- (CGPoint) locationForContentLocation:(CGPoint)contentLocation`: Converts from content space to view space.

### 3.7. `UIView+UILayer.h`

#### Layer Coordinate Conversion
**Purpose:** Converts coordinates between view and layer spaces.

**Core Operations:**
- `- (CGPoint) convertPoint:(CGPoint)pos toLayer:(id<UILayer>)layer`: Converts point to layer's coordinate space.
- `- (CGPoint) convertPoint:(CGPoint)pos fromLayer:(id<UILayer>)layer`: Converts point from layer's coordinate space.
- `- (CGRect) convertRect:(CGRect)rect toLayer:(id<UILayer>)layer`: Converts rect to layer's coordinate space.
- `- (CGRect) convertRect:(CGRect)rect fromLayer:(id<UILayer>)layer`: Converts rect from layer's coordinate space.
- `- (id<UILayer>) layerHitTest:(CGPoint)point`: Returns layer at point (returns mainLayer if no hit).

### 3.8. `UIAutoresizing.h`

#### `typedef NS_OPTIONS(NSUInteger, UIViewAutoresizing)`
Defines autoresizing behavior for views.

**Purpose:** Controls how a view is positioned and sized during layout.

**Content Mode Values (Modern Layout):**
- `UIViewAutoresizingCenter`: Center in superview.
- `UIViewAutoresizingTop`, `UIViewAutoresizingBottom`, `UIViewAutoresizingLeft`, `UIViewAutoresizingRight`: Align to edge.
- `UIViewAutoresizingTopLeft`, `UIViewAutoresizingTopRight`, `UIViewAutoresizingBottomLeft`, `UIViewAutoresizingBottomRight`: Align to corner.
- `UIViewAutoresizingScaleToFill`: Fill entire content rect.
- `UIViewAutoresizingScaleToFillHorizontal`: Fill width, keep aspect for height.
- `UIViewAutoresizingScaleToFillVertical`: Fill height, keep aspect for width.
- `UIViewAutoresizingScaleAspectFit`: Scale to fit within bounds while maintaining aspect ratio.
- `UIViewAutoresizingScaleAspectFill`: Scale to fill bounds while maintaining aspect ratio.

**Legacy Flexible Values:**
- `UIViewAutoresizingFlexibleWidth`: Width resizes with superview.
- `UIViewAutoresizingFlexibleHeight`: Height resizes with superview.
- `UIViewAutoresizingFlexibleTopMargin`: Top margin flexes.
- `UIViewAutoresizingFlexibleBottomMargin`: Bottom margin flexes.
- `UIViewAutoresizingFlexibleLeftMargin`: Left margin flexes.
- `UIViewAutoresizingFlexibleRightMargin`: Right margin flexes.

**Modifier Flags:**
- `UIViewAutoresizingClipToBounds`: Clip to bounds if smaller.
- `UIViewAutoresizingCullAtBounds`: Set size to zero if exceeds bounds.
- `UIViewAutoresizingIntegralFrame`: Make frame values integers.
- `UIViewAutoresizingMixedMode`: Intentional mix of legacy and content mode.

**Helper Functions:**
- `char *UIViewAutoresizingUTF8String(UIViewAutoresizing bits)`: Returns string representation.
- `char *UIViewAutoresizingMaskShortUTF8String(UIViewAutoresizing bits)`: Returns short string.
- `BOOL UIViewAutoresizingIsScaling(UIViewAutoresizing bits)`: Checks if scaling flags are set.
- `BOOL UIViewAutoresizingIsFlexible(UIViewAutoresizing bits)`: Checks if flexible flags are set.
- `CGContentMode UIViewAutoresizingGetContentMode(UIViewAutoresizing bits)`: Extracts content mode.

**Global Function:**
- `CGRect UIAutoresizingLegacyResize(CGRect originalFrame, CGRect lastBounds, CGRect bounds, UIViewAutoresizing autoresizingMask)`: Performs legacy flexible resizing calculation.

#### `@mixin UIAutoresizing`
Mixin for objects that support autoresizing.

**Purpose:** Defines the required interface for autoresizing behavior. Adopted by `UIView` via mixin. Other classes can adopt by declaring `UIAutoresizingProperties;` in their `@interface` block.

**Included Properties (via `UIAutoresizingProperties` macro):**
- `@property(assign) CGRect originalFrame`: Original frame before any resizing.
- `@property(assign) CGRect lastBounds`: Last known bounds of superview.

**Methods:**
- `@required - (CGRect) frame`: Returns the current frame.
- `@optional - (UIEdgeInsets) margins`: Returns optional margins (default: zero).
- `@optional - (CGRect) autoresizeWithLayoutInfo:(struct UILayoutInfo *)context autoresizingMask:(UIViewAutoresizing)autoresizingMask`: Performs autoresizing calculation.

### 3.9. `UINullLayer.h`

#### `@interface UINullLayer`
A no-op layer implementation for testing and placeholder use.

**Purpose:** Provides a minimal `UILayer` implementation that does nothing. Used by default when creating a `UIView` without specifying a layer.

**Properties:**
All required `UILayer` protocol properties are implemented but do nothing.

### 3.10. `UIInputEvent+UIView.h`

#### Category on `UIInputEvent`
**Purpose:** Associates input events with views during hit testing.

**Core Operations:**
- `- (CGPoint) locationInView:(UIView *)view`: Returns event location in view's coordinate space (ephemeral, cached).
- `- (CGPoint) _locationForView:(UIView *)view`: Internal method to get cached location.
- `- (void) _setLocation:(CGPoint)point forView:(UIView *)view`: Internal method to cache location.
- `- (UIView *) _view`: Returns the view associated with this event.

## 4. Performance Characteristics

### Hierarchy Operations
- **Add/Remove Subview**: O(1) amortized (backed by `mulle_pointerarray`).
- **Subview Enumeration**: O(n) where n is the number of subviews.
- **Find View by Tag**: O(n) shallow search, O(m) deep search where m is total descendants.

### Layout
- **Layout**: O(n) where n is the total number of views in the hierarchy (each view is visited once).
- **Hit Testing**: O(log n) on average (tree traversal with early termination), worst case O(n).

### Coordinate Conversion
- **Convert Point/Rect**: O(h) where h is the height difference between views in the hierarchy.

### Thread Safety
- **Not Thread-Safe by Default**: Views are created with `-initNoLock` and must not be accessed from multiple threads until added to a `UIWindow`.
- **Thread-Safe After Window Add**: Once added to a window, a view acquires a lock and can be safely accessed from multiple threads (properties marked `MULLE_OBJC_THREADSAFE_PROPERTY`).

### Memory
- Views are lightweight: Fixed overhead plus proportional to the number of subviews and layers.
- Layers are not retained by views, they are managed directly in pointer arrays for efficiency.

## 5. AI Usage Recommendations & Patterns

### Best Practices

1. **Always Use Designated Initializer:** Use `-initWithLayer:frame:` or convenience methods. Override this method in subclasses, not `-init`.

2. **Respect the View Hierarchy:** Always remove a view from its current superview before adding it to a new superview. Use `-removeFromSuperview` first, or the framework will assert.

3. **Use Callbacks for Customization:** Set C function pointers (`eventCallback`, `willLayoutSubviewsCallback`, etc.) for performance-critical customization rather than subclassing.

4. **Leverage Tags:** Use the `tag` property to identify views in a hierarchy. This is faster and cleaner than iterating or storing references.

5. **Prefer Content Mode Over Legacy Flexible:** Use `UIViewAutoresizingScaleToFill`, `UIViewAutoresizingCenter`, etc., for modern layout. Use flexible flags only for compatibility or when you need manual frame-based layout.

6. **Set Padding and Margins for Automatic Layout:** When using content mode autoresizing, set `padding` on the superview and `margins` on the subview for proper spacing.

7. **Use `-contentRect` in Layout Code:** Always use `-contentRect` instead of `-bounds` when positioning subviews. This accounts for padding.

8. **Call `-layout` After Frame Changes:** Manually call `-layout` after changing a view's frame to update subview positions.

9. **Override Layer Class for Custom Drawing:** Override `+layerClass` in subclasses to return your custom layer class (e.g., `CATextLayer`, `CABitmapLayer`).

10. **Use `-setNeedsLayout` for Async Updates:** If you want the window to layout during the next render cycle, use `-setNeedsLayout` instead of calling `-layout` directly.

### Common Pitfalls

1. **Direct Access to Internal Fields:** Never access `_subviews`, `_layers`, or other `_` prefixed fields directly. Use public methods and macros like `UIViewSubviewsFor`.

2. **Forgetting to Call Super in Lifecycle Methods:** Always call `[super didMoveToWindow:window]` and similar methods if you override them.

3. **Mixing Layout Modes:** Do not mix flexible flags with content mode flags unless you set `UIViewAutoresizingMixedMode`. The framework will warn or assert.

4. **Modifying Frame During Layout:** Avoid setting `frame` directly in `-layoutSubviews`. Use `-setLayoutedFrame:autoresizingMask:` or let the autoresizing logic handle it.

5. **Assuming `bounds.origin` is Always Zero:** Don't assume `bounds.origin` is `(0, 0)`. Use `-contentRect` or query `bounds` explicitly.

6. **Ignoring Thread Safety:** Do not access views from multiple threads before they are added to a window.

7. **Confusing `layer` with `layers`:** `-layer` returns the main layer. Additional layers are accessed via `-getLayers:range:` or enumeration macros.

8. **Not Checking `userInteractionEnabled`:** Views with `userInteractionEnabled == NO` or `hidden == YES` do not receive events, even if they visually overlap the event location.

### Idiomatic Usage

- **Use `-viewWithFrame:` for Simple Views:** Quickly create views with a frame.
- **Use `-addSubview:` for Hierarchy:** Standard method for adding children.
- **Use `UIViewSubviewsFor` for Fast Enumeration:** Avoid `-getSubviews:range:` unless you need random access.
- **Use `-hitTest:withEvent:` for Custom Event Routing:** Override to implement custom event interception.
- **Use `-layoutSubviews` for Custom Layout:** Override to manually position subviews. Return NO to suppress recursive layout.
- **Use `-sizeThatFits:` for Intrinsic Sizing:** Return the natural size of your view given a constraint.

## 6. Integration Examples

### Example 1: Creating and Adding Subviews

```c
#import <MulleUIView/MulleUIView.h>

int   main( void)
{
   UIView   *window;
   UIView   *contentView;
   UIView   *button;

   // Create root view
   window       = [UIView viewWithFrame:CGRectMake( 0, 0, 800, 600)];
   contentView  = [UIView viewWithFrame:CGRectMake( 0, 0, 800, 600)];
   [contentView setPadding:UIEdgeInsetsMake( 10, 10, 10, 10)];

   [window addSubview:contentView];

   // Create a button-like subview
   button = [UIView viewWithFrame:CGRectMake( 0, 0, 100, 40)];
   [button setTag:100];
   [button setNameUTF8String:"submitButton"];
   [button setAutoresizingMask:UIViewAutoresizingCenter];
   [contentView addSubview:button];

   // Layout the hierarchy
   [window layout];

   return( 0);
}
```

### Example 2: Using Autoresizing with Content Mode

```c
#import <MulleUIView/MulleUIView.h>

int   main( void)
{
   UIView   *container;
   UIView   *header;
   UIView   *content;
   UIView   *footer;

   // Create container
   container = [UIView viewWithFrame:CGRectMake( 0, 0, 400, 600)];
   [container setPadding:UIEdgeInsetsMake( 5, 5, 5, 5)];

   // Header: fixed height, fills width, sticks to top
   header = [UIView viewWithFrame:CGRectMake( 0, 0, 100, 50)];
   [header setMargins:UIEdgeInsetsMake( 0, 0, 5, 0)];
   [header setAutoresizingMask:UIViewAutoresizingTop 
                                | UIViewAutoresizingScaleToFillHorizontal];
   [container addSubview:header];

   // Content: fills remaining space
   content = [UIView viewWithFrame:CGRectMake( 0, 0, 100, 100)];
   [content setMargins:UIEdgeInsetsMake( 0, 0, 5, 0)];
   [content setAutoresizingMask:UIViewAutoresizingScaleToFill];
   [container addSubview:content];

   // Footer: fixed height, fills width, sticks to bottom
   footer = [UIView viewWithFrame:CGRectMake( 0, 0, 100, 50)];
   [footer setAutoresizingMask:UIViewAutoresizingBottom 
                                | UIViewAutoresizingScaleToFillHorizontal];
   [container addSubview:footer];

   [container layout];

   return( 0);
}
```

### Example 3: Using Legacy Flexible Autoresizing

```c
#import <MulleUIView/MulleUIView.h>

int   main( void)
{
   UIView   *window;
   UIView   *toolbar;
   UIView   *sidebar;

   window  = [UIView viewWithFrame:CGRectMake( 0, 0, 800, 600)];

   // Toolbar: fixed height at top, stretches horizontally
   toolbar = [UIView viewWithFrame:CGRectMake( 0, 0, 800, 50)];
   [toolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth 
                                 | UIViewAutoresizingFlexibleBottomMargin];
   [window addSubview:toolbar];

   // Sidebar: fixed width on left, stretches vertically
   sidebar = [UIView viewWithFrame:CGRectMake( 0, 50, 200, 550)];
   [sidebar setAutoresizingMask:UIViewAutoresizingFlexibleHeight 
                                 | UIViewAutoresizingFlexibleRightMargin];
   [window addSubview:sidebar];

   [window layout];

   // Resize window
   [window setFrame:CGRectMake( 0, 0, 1024, 768)];
   [window layout];

   return( 0);
}
```

### Example 4: Event Handling with Callbacks

```c
#import <MulleUIView/MulleUIView.h>

static UIEvent   *_buttonEventCallback( UIView *view, UIEvent *event)
{
   if( [event eventType] == UIEventTypeMouseDown)
   {
      printf( "Button '%s' clicked!\n", [view nameUTF8String]);
      return( nil);  // Event consumed
   }
   return( event);   // Event not handled
}

int   main( void)
{
   UIView   *window;
   UIView   *button;

   window = [UIView viewWithFrame:CGRectMake( 0, 0, 400, 300)];
   button = [UIView viewWithFrame:CGRectMake( 150, 125, 100, 50)];

   [button setNameUTF8String:"submitButton"];
   [button setEventCallback:_buttonEventCallback];
   [button setUserInteractionEnabled:YES];

   [window addSubview:button];

   // Simulate click event (in real app, event comes from UIApplication)
   // UIEvent *event = [UIMouseButtonEvent eventWithLocation:CGPointMake(200, 150) ...];
   // [window handleEvent:event];

   return( 0);
}
```

### Example 5: Custom Layout with layoutSubviews

```c
#import <MulleUIView/MulleUIView.h>

@interface CustomView : UIView
@end

@implementation CustomView

- (BOOL) layoutSubviews
{
   CGRect      contentRect;
   CGFloat     y;
   NSUInteger  i, n;
   UIView      *buf[ 32];

   contentRect = [self contentRect];
   y           = CGRectGetMinY( contentRect);
   n           = [self getSubviews:buf range:MulleMakeFullRange()];

   // Stack subviews vertically
   for( i = 0; i < n; i++)
   {
      CGRect   frame;

      frame       = [buf[ i] frame];
      frame.origin.x = CGRectGetMinX( contentRect);
      frame.origin.y = y;
      frame.size.width = CGRectGetWidth( contentRect);

      [buf[ i] setFrame:frame];

      y += CGRectGetHeight( frame);
   }

   return( YES);  // Continue recursive layout
}

@end

int   main( void)
{
   CustomView   *stack;
   UIView       *child;

   stack = [CustomView viewWithFrame:CGRectMake( 0, 0, 200, 300)];

   child = [UIView viewWithFrame:CGRectMake( 0, 0, 0, 50)];
   [stack addSubview:child];

   child = [UIView viewWithFrame:CGRectMake( 0, 0, 0, 75)];
   [stack addSubview:child];

   child = [UIView viewWithFrame:CGRectMake( 0, 0, 0, 100)];
   [stack addSubview:child];

   [stack layout];

   return( 0);
}
```

### Example 6: Hit Testing and Finding Views

```c
#import <MulleUIView/MulleUIView.h>

int   main( void)
{
   UIView    *window;
   UIView    *panel;
   UIView    *button;
   UIView    *hitView;
   CGPoint   point;

   window = [UIView viewWithFrame:CGRectMake( 0, 0, 800, 600)];
   panel  = [UIView viewWithFrame:CGRectMake( 100, 100, 200, 300)];
   button = [UIView viewWithFrame:CGRectMake( 50, 50, 100, 40)];

   [button setTag:42];
   [button setNameUTF8String:"clickMe"];

   [panel addSubview:button];
   [window addSubview:panel];

   // Hit test at window coordinates
   point   = CGPointMake( 175, 175);  // Should hit button
   hitView = [window hitTest:point withEvent:nil];

   if( hitView == button)
      printf( "Hit test successful: found button\n");

   // Find by tag
   hitView = [window findViewWithTag:42];
   if( hitView == button)
      printf( "Found button by tag\n");

   return( 0);
}
```

### Example 7: Coordinate Conversion Between Views

```c
#import <MulleUIView/MulleUIView.h>

int   main( void)
{
   UIView    *window;
   UIView    *container;
   UIView    *subview;
   CGPoint   pointInWindow;
   CGPoint   pointInSubview;

   window    = [UIView viewWithFrame:CGRectMake( 0, 0, 800, 600)];
   container = [UIView viewWithFrame:CGRectMake( 100, 100, 400, 400)];
   subview   = [UIView viewWithFrame:CGRectMake( 50, 50, 200, 200)];

   [container addSubview:subview];
   [window addSubview:container];

   // Convert point from window to subview
   pointInWindow  = CGPointMake( 200, 200);
   pointInSubview = [subview convertPoint:pointInWindow fromView:nil];

   printf( "Window point %s -> Subview point %s\n",
           CGPointUTF8String( pointInWindow),
           CGPointUTF8String( pointInSubview));

   return( 0);
}
```

## 7. Dependencies

MulleUIView directly depends on:

- **MulleUIApplication**: Provides abstract classes like `UIApplication`, `UIWindow`, `UIEvent`, `UIInputEvent`, `UIMouseMotionEvent`, `UIResponder` protocol, `UILayoutContext` protocol, and `UILayoutInfo` structure.
- **mulle-objc-list**: Tool for listing mulle-objc runtime information (build-time dependency, not a runtime library dependency).

Indirectly, MulleUIView depends on the mulle-objc runtime and foundation libraries provided by MulleUIApplication's dependencies.
