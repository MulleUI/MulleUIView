//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
// we want "import.h" always anyway
#import "import.h"

@class UIEvent;

#ifdef __has_include
# if __has_include( "MulleCursorProtocol.h")
#  import "MulleCursorProtocol.h"
# endif
#endif

struct MulleCursorPosition
{
   NSInteger   row;
   NSInteger   column;
};


//
// TODO: move this away
//
// The MulleKeyboardEventConsumer manages keyboard events, 
// like copy/paste and cursor movement. It's pretty much the same for 
// UITextField or UITextView in an abstract kind of way.
//
PROTOCOLCLASS_INTERFACE( MulleKeyboardEventConsumer, NSObject)

- (struct MulleCursorPosition) maxCursorPosition;

// could also be a property with a respective #define, but its tricky as 
// the implementor might also get it from MulleCursor

// TODO: why is this CGBitmapPoint, because we are dealing
- (void) setCursorPosition:(struct MulleCursorPosition) pos;
- (struct MulleCursorPosition) cursorPosition;
- (void) getCursorPosition:(struct MulleCursorPosition *) pos;

- (void) backspaceCharacter;
- (void) cut;
- (void) copy;
- (void) paste;
- (void) enterOrReturn;

// the protocolclass implements this. Forward your keyDown: event to it if
// your view isn't a "subclass" of UIControl
@optional
- (UIEvent *) consumeKeyDown:(UIEvent *) event;


- (void) cursorUp;
- (void) cursorDown;
- (void) cursorLeft;
- (void) cursorRight;

PROTOCOLCLASS_END();

