//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "UIView.h")
#  import "UIView.h"
# endif
#endif

#import "import.h"


// the UIGridView is similiar to the UIStackView, but organizes its subviews
// in a rigid grid. If there are more subviews than fit the grid, they are
// run with the default layout code.
// TODO: move this to MulleGrid for more flexibility
//
@interface UIGridView : UIView

@property( assign) NSUInteger  rows;      // default 3
@property( assign) NSUInteger  columns;   // default 3
@property( assign) CGSize      space;     // default 8,8

- (UIView *) viewForRow:(NSUInteger) row
                 column:(NSUInteger) column;

@end
