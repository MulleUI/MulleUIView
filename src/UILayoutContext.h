#import "import.h"


struct UILayoutContext
{
   CGRect         contentRect;
   UIEdgeInsets   padding;
};


static inline struct UILayoutContext
   UILayoutContextMake( CGRect contentRect, UIEdgeInsets padding)
{
   return( (struct UILayoutContext)
           {
              .contentRect = contentRect,
              .padding     = padding
            });
}


