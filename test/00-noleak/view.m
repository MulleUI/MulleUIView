#import <MulleUIView/MulleUIView.h>

static char   *view_name = "myView";

int   main( void)
{
   UIView   *view;
   char     *s;
   char     *name;

   view = [UIView viewWithFrame:CGRectMake( 32, 32, 64, 64)];
   if( ! view)
   {
      fprintf( stderr, "viewWithFrame: failed\n");
      exit( 1);
   }
   [view setNameUTF8String:view_name];

   s    = [view UTF8String];
   name = strchr( s, '"');
   if( ! name)
   {
      mulle_fprintf( stderr, "no name found: %s\n", s);
      return( 1);
   }

   if( strncmp( name + 1, view_name, strlen( view_name)))
   {
      mulle_fprintf( stderr, "%.*s and %s differ\n", 
                           (int) strlen( view_name), 
                           name + 1, 
                           view_name);
      return( 2);
   }
   return( 0);
}

