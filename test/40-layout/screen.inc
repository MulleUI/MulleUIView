#ifndef SCREEN_W
# define SCREEN_W  20
#endif

#ifndef SCREEN_H
# define SCREEN_H  10
#endif


struct screen
{
   char  pixels[ SCREEN_H][ SCREEN_W];
};


static void  screen_init( struct screen *p)
{
   memset( p, ' ', sizeof( struct screen));
}


static void  screen_done( struct screen *p)
{
}



static void  screen_draw_rect( struct screen *p, CGRect rect, char c)
{
   CGPoint   tl, br;
   CGFloat   x;
   CGFloat   y;
   CGRect    clipped;

   clipped = CGRectIntersection( CGRectMake( 0.0, 0.0, SCREEN_W, SCREEN_H), rect);
   clipped = CGRectIntegral( clipped);

   tl.x = CGRectGetMinX( clipped);
   tl.y = CGRectGetMinY( clipped);
   br.x = CGRectGetMaxX( clipped);
   br.y = CGRectGetMaxY( clipped);

   for( y = tl.y; y < br.y; y += 1.0f)
      for( x = tl.x; x < br.x; x += 1.0f)
      {
         p->pixels[ (int) y][ ( int) x] = c;
      }
}


static void  screen_render( struct screen *p, FILE *fp)
{
   NSUInteger  y;

   for( y = 0; y < SCREEN_H; y += 1)
      printf( "%.*s\n", SCREEN_W, p->pixels[ y]);
}


static void  _screen_draw_view( struct screen *p, UIView *view, CGPoint offset, char c)
{
   CGRect   frame;
   CGRect   rect;
   UIView   *subview;

   frame = [view frame];
   rect  = CGRectOffset( frame, offset.x, offset.y);
   screen_draw_rect( p, rect, c);

   UIViewSubviewsFor( view, subview)
   {
      _screen_draw_view( p, subview, rect.origin, ++c);
   }
}

static void  screen_draw_view( struct screen *p, UIView *view)
{
   _screen_draw_view( p, view, CGPointZero, '0');
}


static void   UIViewASCIIRender( UIView *view, FILE *fp)
{
   struct screen  screen;

   screen_init( &screen);
   screen_draw_view( &screen, view);
   screen_render( &screen, fp);
   screen_done( &screen);
}

