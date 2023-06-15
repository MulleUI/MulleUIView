# MulleUIView

#### ![](mulle-tiny-logo-255x256.png)


# 📐 MulleUIView

![](mulle-tiny-logo-255x256.png)

#### 📐 MulleUIView for layout and events

A UIView combines one or multiple UILayers. Multiple UIViews form a hierarchy.
Whereas a UILayer is independent of any other UILayer, a UIView
can have a parent, siblings and desecendants. UILayer is a protocol,
typically `CALayer` will be the concrete class being used as layer.

A UIView provides two services in a program

* layout
* event processing

A UIView does no drawing. All drawing is done by CALayer and its subclasses.
Every UIView must have at least one CALayer. But a CALayer can be invisible.


UIView therefore imposes a structure (layout) on CALayers and facilitates the
routing of events from the event receiver (usually a UIWindow or the
UIApplication) to the code managing the CALayer (a UIView subclass ?).




| Release Version                                       | Release Notes
|-------------------------------------------------------|--------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag//MulleUIView.svg?branch=release) [![Build Status](https://github.com//MulleUIView/workflows/CI/badge.svg?branch=release)](//github.com//MulleUIView/actions)| [RELEASENOTES](RELEASENOTES.md) |







## Add

Use [mulle-sde](//github.com/mulle-sde) to add MulleUIView to your project:

``` sh
mulle-sde add github:/
```

To only add the sources of MulleUIView with dependency
sources use [clib](https://github.com/clibs/clib):


``` sh
clib install --out src/ /
```

Add `-isystem src/` to your `CFLAGS` and compile all the sources that were downloaded with your project.


## Install

### Install with mulle-sde

Use [mulle-sde](//github.com/mulle-sde) to build and install MulleUIView and all dependencies:

``` sh
mulle-sde install --prefix /usr/local \
   https://github.com///archive/latest.tar.gz
```

### Manual Installation

Install the requirements:

| Requirements                                 | Description
|----------------------------------------------|-----------------------
| [MulleUIApplication](https://github.com/MulleUI/MulleUIApplication)             | 𝄢 MulleUIApplication provides abstract classes like UIApplication and UIEvent
| [mulle-objc-list](https://github.com/mulle-objc/mulle-objc-list)             | 📒 Lists mulle-objc runtime information contained in executables.

Install **MulleUIView** into `/usr/local` with [cmake](https://cmake.org):

``` sh
cmake -B build \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_PREFIX_PATH=/usr/local \
      -DCMAKE_BUILD_TYPE=Release &&
cmake --build build --config Release &&
cmake --install build --config Release
```

## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK


