#ifdef __has_include
# if __has_include( "UIView.h")
#  import "UIView.h"
# endif
#endif

#ifdef __has_include
# if __has_include( "UIView+Layout.h")
#  import "UIView+Layout.h"
# endif
#endif

//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "import.h"


//
// UIStackViewDistributionUnbounded, is like UIStackViewDistributionFill
// but as views are added the axis contentRect is ignored and views are just
// stacked unto each other.
//
typedef enum
{
   UIStackViewDistributionFill      = 0,
   UIStackViewDistributionFillEqually,
   UIStackViewDistributionFillProportionally,
   UIStackViewDistributionEqualSpacing,
   UIStackViewDistributionEqualCentering,
   UIStackViewDistributionFillRowColumn,
   UIStackViewDistributionFillKeyValue,
   UIStackViewDistributionUnbounded,
   UIStackViewDistributionCustom   // uses callback
} UIStackViewDistribution;


// view alignment 
// 
// center in vertical form is:
// 
//  -------:------ 
//  |      :     | view 1
//  -------:------ 
//       --:--
//       | : |     view 2
//       --:--

typedef enum
{
   UIStackViewAlignmentCenter = 0,     // center is the new default!
   UIStackViewAlignmentLeading,
   UIStackViewAlignmentTop,
   UIStackViewAlignmentTrailing,
   UIStackViewAlignmentBottom
} UIStackViewAlignment;


@class UIStackView;


typedef void   UIStackViewCustomDistributor_t( UIStackView *stackView);


//
// The stackview shares the name with iOS but its very different
// currently the stackView always stacks from top to bottom, left to right.
// 
@interface UIStackView : UIView

// either UILayoutConstraintAxisVerticalIndex or UILayoutConstraintAxisHorizontalIndex
// default is UILayoutConstraintAxisVerticalIndex!
@property UILayoutConstraintAxisIndex    axisIndex;

@property UIStackViewDistribution        distribution;

// the alignment is not used if the subview has a autoresizingMask set
@property UIStackViewAlignment           alignment;

// used for UIStackViewDistributionFillRowColumn only
@property CGFloat                        minimumInteritemSpacing;
@property CGFloat                        minimumLineSpacing;

// used for UIStackViewDistributionFillKeyValue only
// if this is set minimumInteritemSpacing is ignored. The height of the
// spacer view will adjust heights of the others, if larger. otherwise the
// view is autoresized. The width is always fixed by sizeToFits:
//
@property( assign) BOOL                  showsSpacerView;

// used in conjunction with -setDistribution:UIStackViewDistributionCustom
@property( assign) UIStackViewCustomDistributor_t  *customDistributor;

@end
