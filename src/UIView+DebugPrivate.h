enum
{
   UIViewDebug                 = 0x000001,
   UIViewDebugEvent            = 0x000002,
   UIViewDebugVerbose          = 0x001000,
   UIViewDebugEventVerbose     = 0x002000,
   UIViewDebugMouseMotionEvent = 0x001000000
};


@interface NSObject ( UIView)

- (BOOL) __isUIView;

@end



#if ! defined( UI_WINDOW_DEBUG_DISABLED)

#define UIViewLog( format, ...)                                             \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debugEnabled & UIViewDebug)                                   \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)

#define UIViewLogVerbose( format, ...)                                      \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debugEnabled & UIViewDebugVerbose)                            \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)


#define UIViewEventLog( event, format, ...)                                 \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debugEnabled & UIViewDebugEvent)                              \
      if( [event eventType] != UIEventTypeMotion)                           \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                          (char *) format, ## __VA_ARGS__); \
}                                                                           \
while( 0)


#define UIViewEventLogVerbose( event, format, ...)                          \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debugEnabled & UIViewDebugEventVerbose)                       \
      if( [event eventType] != UIEventTypeMotion)                           \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                          (char *) format, ## __VA_ARGS__); \
}                                                                           \
while( 0)

#define UIViewMouseMotionEventLog( event, format, ...)                      \
do                                                                          \
{                                                                           \
   assert( [self __isUIView]);                                              \
   if( self->_debugEnabled & UIViewDebugMouseMotionEvent)                   \
      if( [event eventType] == UIEventTypeMotion)                           \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                          (char *) format, ## __VA_ARGS__); \
}                                                                           \
while( 0)

#else

#define UIViewLog( format, ...)                         do {} while( 0)
#define UIViewLogVerbose( format, ...)                  do {} while( 0)
#define UIViewEventLog( event, format, ...)             do {} while( 0)
#define UIViewEventLogVerbose( event, format, ...)      do {} while( 0)
#define UIViewMouseMotionEventLog( event, format, ...)  do {} while( 0)

#endif


