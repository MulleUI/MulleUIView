//
// Copyright (c) <|YEAR|> Nat!, Mulle kybernetiK
//
#import "UINullLayer.h"

#import "import-private.h"



@implementation UINullLayer

- (void) willChange
{
   // ignore
}

- (instancetype) initWithFrame:(CGRect) frame
{
   _frame       = frame;
   _bounds.size = frame.size;

   return( self);
}


- (instancetype) initWithFrame:(CGRect) frame
                      OSWindow:(id <UIOSWindow>) osWindow
{
   return( [self initWithFrame:frame]);
}


- (void) layoutWithLayoutInfo:(struct UILayoutInfo *) info
{
   assert( info);
}


- (id) copy
{
   UINullLayer   *copy;

   copy = [[[self class] alloc] initWithFrame:self->_frame];
   if( ! copy)
      return( copy);

   copy->_bounds = self->_bounds;
   return( copy);
}


- (void) forgetImplicitAnimations
{
}


- (char *) nameUTF8String
{
   return( NULL);
}


- (void) setNameUTF8String:(char *) s
{
   if( s)
      abort();
}


- (CGSize) sizeThatFits:(CGSize) size
                context:(id <UILayoutContext>) context
{
   return( size);
}


- (void) dumpWithIndent:(NSUInteger) indent
                   FILE:(FILE *) fp
{
   NSUInteger   i;

   for( i = 0; i < indent; i++)
      fputc( ' ', fp);

   fprintf( fp, "%s: frame=[%s] bounds=[%s]",
               [self UTF8String],
               CGRectUTF8String( [self frame]),
               CGRectUTF8String( [self bounds]));
   fprintf( fp, "\n");
}


@end
