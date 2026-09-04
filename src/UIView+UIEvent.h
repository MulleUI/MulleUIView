//
//  UIView+UIEvent.h
//  MulleUIView
//
//  Copyright (c) 2018 Nat! - Mulle kybernetiK.
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
#import "UIView.h"

@class UIMouseScrollEvent;
@class UIMouseButtonEvent;
@class UIMouseMotionEvent;


// only input events are distributed to UIViews

@interface UIView ( UIEvent) < UIResponder>


// pointInside is not declared as UIInputEvent, for compatibility
// event is unused.
- (BOOL) pointInside:(CGPoint) point
           withEvent:(UIEvent *) event;

// this will set the locationForView of the event. If you don't want this
// don't pass an event. Returns the farthest view, that is not transparent
// and has userInteraction enabled. (not used by event handling)
- (UIView *) hitTest:(CGPoint) point
           withEvent:(UIEvent *) event;

// this checks userInteractionEnabled and tests with pointInside:withEvent:
// inputEvent cache will be set for the view, if the hitTest succeeds
- (BOOL) directHitTest:(CGPoint) point
        withInputEvent:(UIInputEvent *) event;

// this method is actually used for event deliver. Event can be changed to
// nil to block propagation
- (UIView *) hitSearchSubviews:(CGPoint) contentLocation
         withInputEventPointer:(UIInputEvent **) event_p;

//
// this handles the event without considering subviews
//
- (UIView *) subviewAtContentLocation:(CGPoint) point;
- (id <UILayer>) layerAtContentLocation:(CGPoint) point;

// UIResponder...
- (UIMouseMotionEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) event;
- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event;
- (UIEvent *) handleEvent:(UIEvent *) event;

// used by customers of the eventCallback (i.e. Controller) to avoid recursion
// in special cases.
- (UIEvent *) handleForwardedEvent:(UIEvent *) event;

- (void) didBecomeFirstResponder;
- (void) didResignFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;
- (BOOL) isFirstResponder;
- (id <UIResponder>) nextResponder;


@end



