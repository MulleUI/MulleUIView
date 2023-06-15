## Info

An UIView is responsible for event processing and layouting. Once layouting
is done, the UIView and it's layout related variables (like `frame`) as well
as the subviews are in a consistent state. An event that changes values in
the UIView may therefore see inconsistent state until the next layout is
run. This is partly desirable and partly undesirable.

### A desirable lazy change

You change the `-autoresizingMask` of the UIView from `right` to `left`. In
the next layout the view is likely to have different `frame` contents as the
view is moved from the right to the left. An immediate re-layout would be
very costly.


### Undesirable lazy change

You have a


Bottomline. If you need to access layout values and need consistent values,
you will need to relayout the view. Which actually means relayouting the
superview... It's costly.