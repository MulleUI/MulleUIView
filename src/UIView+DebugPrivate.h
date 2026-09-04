//
//  UIView+DebugPrivate.h
//  MulleUIView
//
//  Copyright (c) 2023 Nat! - Mulle kybernetiK.
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
enum
{
   UIViewDebug                        = 0x00000001,
   UIViewDebugEvent                   = 0x00000002,
   UIViewDebugLayout                  = 0x00000004,
   UIViewDebugDisplayBits             = 0x00000040,
   UIViewDebugVerbose                 = 0x00001000,
   UIViewDebugEventVerbose            = 0x00002000,
   UIViewDebugMouseTrackingEvent      = 0x01000000,
   UIViewDebugMouseMotionEvent        = 0x02000000

   // memo don't use more than 0x0400000 to not get in conflict with UIWindow
};



@interface NSObject ( UIView)

- (BOOL) __isUIView     MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) __isUIWindow   MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) __isUILayer    MULLE_OBJC_THREADSAFE_METHOD;

@end



#if ! defined( UI_VIEW_LOG_DISABLED)

#define UIViewLog( format, ...)                                             \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debuggingFlags & UIViewDebug)                                 \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)

#define UIViewLogVerbose( format, ...)                                      \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debuggingFlags & UIViewDebugVerbose)                          \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)


#define UIViewLayoutLog( format, ...)                                       \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debuggingFlags & UIViewDebugLayout)                           \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)


#define UIViewEventLog( event, format, ...)                                 \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debuggingFlags & UIViewDebugEvent)                            \
      if( ! event || ([event eventType] & ~(UIEventTypeMotion|UIEventTypeTracking)))     \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                          (char *) format, ## __VA_ARGS__); \
}                                                                           \
while( 0)


#define UIViewEventLogVerbose( event, format, ...)                          \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debuggingFlags & UIViewDebugEventVerbose)                     \
      if( ! event || ([event eventType] & ~(UIEventTypeMotion|UIEventTypeTracking)))     \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                          (char *) format, ## __VA_ARGS__); \
}                                                                           \
while( 0)


#define UIViewDisplayBitsLog( format, ...)                                  \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debuggingFlags & UIViewDebugDisplayBits)                      \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)


#define UIViewMouseTrackingEventLog( event, format, ...)                    \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debuggingFlags & UIViewDebugMouseTrackingEvent)               \
      if( ! event || [event eventType] == UIEventTypeTracking)              \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                          (char *) format, ## __VA_ARGS__); \
}                                                                           \
while( 0)

#define UIViewMouseMotionEventLog( event, format, ...)                      \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debuggingFlags & UIViewDebugMouseMotionEvent)                 \
      if( ! event || [event eventType] == UIEventTypeMotion)                \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                          (char *) format, ## __VA_ARGS__); \
}                                                                           \
while( 0)


#else

#define UIViewLayoutLog( format, ...)                      do {} while( 0)
#define UIViewLog( format, ...)                            do {} while( 0)
#define UIViewLogVerbose( format, ...)                     do {} while( 0)
#define UIViewEventLog( event, format, ...)                do {} while( 0)
#define UIViewEventLogVerbose( event, format, ...)         do {} while( 0)
#define UIViewDisplayBitsLog( event, format, ...)          do {} while( 0)
#define UIViewMouseMotionEventLog( event, format, ...)     do {} while( 0)
#define UIViewMouseTrackingEventLog( event, format, ...)   do {} while( 0)

#endif


