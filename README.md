# 📐 MulleUIView

#### 📐 MulleUIView for layout and events

A UIView combines one or multiple CALayers. Multiple UIView form a hierarchy.
Whereas a CALayer is independent of any other CALayer, a UIView
can have a parent, siblings and desecendants.

A UIView provides two services in a program

* layout
* event processing

A UIView does no drawing. All drawing is done by CALayer and its subclasses.
Every UIView miust have at least one CALayer. But a CALayer can be invisible.



![](mulle-tiny-logo-255x256.png)

See live on stream how it progresses: [https://www.twitch.tv/mulle_kybernetik_tv/](). Every Wednesday at 14:00-18:00 CEST.


![](demos/candycrash.png)


### You are here

There is no actual "drawing" code in MulleUIView. Use "MulleGraphics" for
drawing. See "MulleUIControl" for widgets.


```
  .-----------------------------------------.
  | MulleUIFoundation                       |
  '-----------------------------------------'
  .-----------------------------------------.
  | MulleUIControl                          |
  '-----------------------------------------'
  .-----------------. .=====================.
  | MulleUIImage    | | MulleUIView         |
  '-----------------' '==============.======.
  .--------------------------------. | glfw |
  | MulleGraphics                  | | X11  |
  '--------------------------------' '------'
  .-----------------. .------------.
  | MulleCG         | | MulleCA    |
  '-----------------' '------------'
  .--------------------------------.
  | MulleLayout                    |
  '--------------------------------'
```

MulleUIView is only based on [MulleObjCLockFoundation](//github.com/MulleFoundation/MulleObjCFoundation). Foundation datatypes like `NSString` are not available.
