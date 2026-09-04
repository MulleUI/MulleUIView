# MulleUIView

Part of [MulleUI](https://github.com/MulleUI) — UIKit-shaped modular GUI libraries for mulle-objc.

#### 🛋 UIView is a layout and event-processing container

![mulle tiny logo](mulle-tiny-logo-255x256.png)

A UIView combines one or multiple UILayers. Multiple UIViews form a hierarchy.
Whereas a UILayer is independent of any other UILayer, a UIView
can have a parent, siblings and descendants. UILayer is a protocol,
typically `CALayer` will be the concrete class being used as layer.

A UIView provides two services in a program

* layout
* event processing

A UIView does no drawing. All drawing is done by CALayer and its subclasses.
Every UIView must have at least one CALayer. But a CALayer can be invisible.

UIView therefore imposes a structure (layout) on CALayers and facilitates the
routing of events from the event receiver (usually a UIWindow or the
UIApplication) to the code managing the CALayer (a UIView subclass).

MulleUIView provides these pure layouting views (UIViews that don't draw)

* UIGridView
* UIStackView
* UIScrollView



| Release Version                                       | Release Notes  | AI Documentation
|-------------------------------------------------------|----------------|---------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/MulleUI/MulleUIView.svg) [![Build Status](https://github.com/MulleUI/MulleUIView/workflows/CI/badge.svg)](//github.com/MulleUI/MulleUIView/actions) | [RELEASENOTES](RELEASENOTES.md) | [DeepWiki for MulleUIView](https://deepwiki.com/MulleUI/MulleUIView)




## Documentation & Guides

* [API Summary](asset/dox/api/toc)
* [Coder Guide](asset/howto/coder/mulle-ui-animation)
* [Debugger Guide](asset/howto/debugger/mulle-ui-animation)
* [Verifier Guide](asset/howto/verifier/mulle-ui-animation)

## Usage

A `UIView` is the interactive building block. It does no drawing itself, it
imposes a layout structure on its `CALayer`s and routes events. Build a
hierarchy by nesting views:

``` objc
#import <MulleUIView/MulleUIView.h>

int  main( void)
{
   UIView   *content;
   UIView   *redView;
   UIView   *blueView;
   CGRect   contentRect;

   contentRect = CGRectMake( 0.0, 0.0, 200.0, 200.0);

   content  = [UIView viewWithFrame:contentRect];
   [content setBackgroundColor:CGColorMakeWhite()];

   redView  = [UIView viewWithFrame:CGRectInset( contentRect, 20.0, 20.0)];
   [redView setBackgroundColor:CGColorMakeRed()];
   [content addSubview:redView];

   blueView = [UIView viewWithFrame:CGRectMake( 50.0, 50.0, 40.0, 40.0)];
   [blueView setBackgroundColor:CGColorMakeBlue()];
   [redView addSubview:blueView];

   return( 0);
}
```

Every `UIView` must have at least one `CALayer`. The pure layouting views
(`UIGridView`, `UIStackView`, `UIScrollView`) don't draw anything by
themselves.

## Build the demo

The `demo/` folder is a [mulle-sde](//github.com/mulle-sde) project:

``` sh
cd demo
mulle-sde craft
```


### You are here

![Overview](overview.dot.svg)





## Add

Use [mulle-sde](//github.com/mulle-sde) to add MulleUIView to your project:

``` sh
mulle-sde add github:MulleUI/MulleUIView
```

To only add the sources of MulleUIView with dependency
sources use [clib](https://github.com/clibs/clib):


``` sh
clib install --out src/MulleUI MulleUI/MulleUIView
```

Add `-isystem src/MulleUI` to your `CFLAGS` and compile all the sources that were downloaded with your project.


## Install

Use [mulle-sde](//github.com/mulle-sde) to build and install MulleUIView and all dependencies:

``` sh
mulle-sde install --prefix /usr/local \
   https://github.com/MulleUI/MulleUIView/archive/latest.tar.gz
```

### Legacy Installation

Install the requirements:

| Requirements                                 | Description
|----------------------------------------------|-----------------------
| [MulleUIApplication](https://github.com/MulleUI/MulleUIApplication)             | 🛖 MulleUIApplication provides abstract classes like UIApplication and UIEvent
| [mulle-objc-list](https://github.com/mulle-objc/mulle-objc-list)             | 📒 Lists mulle-objc runtime information contained in executables.

Download the latest [tar](https://github.com/MulleUI/MulleUIView/archive/refs/tags/latest.tar.gz) or [zip](https://github.com/MulleUI/MulleUIView/archive/refs/tags/latest.zip) archive and unpack it.

Install **MulleUIView** into `/usr/local` with [cmake](https://cmake.org):

``` sh
PREFIX_DIR="/usr/local"
cmake -B build                               \
      -DMULLE_SDK_PATH="${PREFIX_DIR}"       \
      -DCMAKE_INSTALL_PREFIX="${PREFIX_DIR}" \
      -DCMAKE_PREFIX_PATH="${PREFIX_DIR}"    \
      -DCMAKE_BUILD_TYPE=Release &&
cmake --build build --config Release &&
cmake --install build --config Release
```


## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK  



