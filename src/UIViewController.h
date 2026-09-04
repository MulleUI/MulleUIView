//
//  UIViewController.h
//  MulleUIView
//
//  Copyright (c) 2024 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

#import "import.h"

#import "UIAutoresizing.h"


@class UIView;

struct UILayoutInfo;

//
// The UIViewController does not retain its views, they are part of the window
// view structure. The view controller can intercept and handle all
// UIInputEvents on the behalf of its views.
//
// An example for an UIViewController with multiple views is a UITextField
// with two UIButtons or a UIStepper to increment/decrement the value. You
// get the information from the stepper button and can update the UITextField
// with the new value (you can also do it differently, but the main point
// here is you could if you wanted to).
//
// "Application" code will more often then not reside in a UIViewController
// and not in a UIView.
//
@interface UIViewController : MulleObject < MulleAutolockingObjectProtocols,
                                            UIResponder>
{
   struct mulle_pointerarray   _views;
   UIView                      *_mainView;
}


@property( assign) id <UIWindow>  window;

// if you set this to YES, then your subclass must implement
// -layoutViews
@property( assign, setter=setIsLayoutingViews:) BOOL   isLayoutingViews;

// you don't need/have a view just yet ?, just use +object
+ (instancetype) objectWithView:(UIView *) view;
- (instancetype) initWithView:(UIView *) view;

- (UIView *) mainView;
- (UIView *) view;


- (struct mulle_pointerarray *) _views;
- (UIView *) viewWithTag:(NSInteger) tag;
- (NSInteger) getViews:(UIView * *) buf
                  range:(NSRange) range;


- (void) addToViews:(UIView *) view;
- (void) removeFromViews:(UIView *) view;

- (void) addView:(UIView *) view;
- (void) removeView:(UIView *) view;
- (void) removeAllViews;

- (BOOL) isMultiView;

// Event handling
- (UIEvent *) handleEvent:(UIEvent *) event
                   ofView:(UIView *) view;

// Layout handling, default is NO, did not layout view
- (BOOL) layoutView:(UIView *) view
         layoutInfo:(struct UILayoutInfo *) context
   autoresizingMask:(UIViewAutoresizing) autoresizingMask;

- (void)   view:(UIView *) view
didMoveToWindow:(id <UIWindow>) window;

@end


#define UIViewControllerViewCount( self)                                                      \
   mulle_pointerarray_get_count( self                                                         \
                                 ? &((struct { @defs( UIViewController); } *) self)->_views   \
                                 : 0) +                                                       \
      (self ? &((struct { @defs( UIViewController); } *) self)->_mainView != nil : 1)


#define UIViewControllerViewFor( self, view)                                                                           \
   for( struct mulle_pointerarrayenumerator                                                                            \
           rover__ ## view = mulle_pointerarray_enumerate( &((struct { @defs( UIViewController); } *) self)->_views),  \
           *rover___  ## view ## __i = (void *) 0;                                                                     \
        ! rover___  ## view ## __i;                                                                                    \
        rover___ ## view ## __i = (_mulle_pointerarrayenumerator_done( &rover__ ## view),                              \
                                   (void *) 1))                                                                        \
      for( UIView *view = (self ? ((struct { @defs( UIViewController); } *) self)->_mainView : nil);                   \
           view;                                                                                                       \
           _mulle_pointerarrayenumerator_next( &rover__ ## view, (void **) &view))


@interface UIViewController( Subclass)


- (void) layoutViews;

@end
