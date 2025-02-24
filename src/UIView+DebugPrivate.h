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


