#import <MulleUIView/MulleUIView.h>

@interface UIView( TestCategoryA)
@property (dynamic, assign) int categoryAValue;
- (void) initCategory;
- (void) deallocCategory;
@end

@interface UIView( TestCategoryB)
@property (dynamic, assign) int categoryBValue;
- (void) initCategory;
- (void) deallocCategory;
@end

// Implementation for the first category
@implementation UIView( TestCategoryA)

@dynamic categoryAValue;

// Instance method that will be called during UIView initialization
- (void) initCategory
{
   mulle_printf( "UIView(TestCategoryA): initCategory called\n");
   // Initialize with a default value if you want
   [self setCategoryAValue:21];
}

// Instance method that will be called during UIView deallocation
- (void) deallocCategory
{
   mulle_printf( "UIView(TestCategoryA): deallocCategory called\n");
}
@end

// Implementation for the second category with dependency on the first
@implementation UIView( TestCategoryB)
MULLE_OBJC_DEPENDS_ON_CATEGORY( UIView, TestCategoryA);

@dynamic categoryBValue;

- (void) initCategory
{
   mulle_printf( "UIView(TestCategoryB): initCategory called\n");
   // Initialize with a default value if you want
   [self setCategoryBValue:42];
}

- (void) deallocCategory
{
   mulle_printf( "UIView(TestCategoryB): deallocCategory called\n");
}
@end

int main(void)
{
   mulle_printf( "=== Testing UIView Category Initialization ===\n");
   mulle_printf( "Creating a UIView to verify its automatic category initialization...\n");

   // UIView should automatically call -initCategory on all categories
   // during instance initialization
   UIView *view = [UIView new];
   mulle_printf( "UIView created\n");

   // Check if our properties have default values from initCategory
   mulle_printf( "\nDefault property values from initCategory:\n");
   mulle_printf( "Category A value: %d\n", [view categoryAValue]);
   mulle_printf( "Category B value: %d\n", [view categoryBValue]);

   // Update properties
   mulle_printf( "\nUpdating property values...\n");
   [view setCategoryAValue:84];
   [view setCategoryBValue:200];

   mulle_printf( "After modification:\n");
   mulle_printf( "Category A value: %d\n", [view categoryAValue]);
   mulle_printf( "Category B value: %d\n", [view categoryBValue]);

   mulle_printf( "\nDeallocating UIView...\n");
   // When UIView is deallocated, it should call -deallocCategory
   // on all categories automatically
   [view release];
   mulle_printf( "UIView deallocated\n");

   mulle_printf( "\n=== Test Complete ===\n");

   return 0;
}