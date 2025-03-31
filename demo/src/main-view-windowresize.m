#import "import.h"


#define LOG_EVENTS


@interface MyWindow : UIWindow
{
   NSUInteger   _oldAutoresizing;
   UIView       *_views[ 4];
}

- (void) setupViews;

@end

#define SPACE  3.0


@implementation MyWindow

- (void) setupViews
{
   UIView         *contentView;
   CGRect         cells[ 3];
   CGRect         rows[ 2];
   CGRect         contentRect;
   unsigned int   i;

   contentView = [self contentView];
   contentRect = CGRectInset( [contentView contentRect], SPACE, SPACE);

   CGRectPartitionVertically( contentRect, SPACE, 2, rows);

   CGRectPartitionHorizontally( rows[ 0], SPACE, 3, cells);
   for( i = 0; i < 3; i++)
   {
      _views[ i] = [UIView viewWithFrame:cells[ i]];
      [_views[ i] setBorderWidth:1.0];
      [_views[ i] setBorderColor:CGColorMakeDarkGray()];
//      [_views[ i] setHidden:YES];
      [contentView addSubview:_views[ i]];
   }
   [_views[ 0] setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleHeight];
   [_views[ 0] setBackgroundColor:CGColorMakeDarkGreen()];
   [_views[ 0] setNameUTF8String:"Mr. Green"];
   [_views[ 1] setBorderColor:CGColorMakeBlack()];
   [_views[ 1] setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [_views[ 1] setBackgroundColor:CGColorMakeDarkOrchid()];
   [_views[ 1] setNameUTF8String:"Mr. Orchid"];
//   [_views[ 1] setHidden:NO];
   [_views[ 2] setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleHeight];
   [_views[ 2] setBackgroundColor:CGColorMakeOrange()];
   [_views[ 2] setNameUTF8String:"Mr. Orange"];

   _views[ 3] = [UIView viewWithFrame:rows[ 1]];
   [_views[ 3] setNameUTF8String:"Mrs. Blue"];
   [_views[ 3] setBorderWidth:1.0];
   [_views[ 3] setBorderColor:CGColorMakeLime()];
   [_views[ 3] setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
   [_views[ 3] setBackgroundColor:CGColorMakeLightBlue()];
   [contentView addSubview:_views[ i]];
}

@end



int   main( int argc, char *argv[])
{
   MyWindow        *window;
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   {
      window = [MyWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
      assert( window);

      [window setBackgroundColor:CGColorMakeWhite()];

      // TODO: need to setDisplay in async mode for UIButton reflection 
      // [window setFrameRateHz:30.0];

      [window setupViews];

      [app addWindow:window];
   }
   return( [app runApp]);
}



//
//                           ,╓≤æKª╨╙╙▓█D"╙╙╙*╨¥W▄╓,
//                      ╓▄ª╙└╧▓        █           ⁿ▓▓ª╦w
//                  ╓#╜^*█⌐   `╕       █           ╓▌    `╙%w
//               ╓ΦΓ      █    ╙⌐     ,█,,,Φ      ╓▌         ╙¥▄
//            ,▄▀ █▄       █µ,╓╝,╓≤╗≡≡ª╨╨╨¥≡∞╗w╓,ª█,  ,       ]▄▀V,
//          ,Φ└   ║"▀▄     ,▄▀╨"                 "╙¥▓▓       ▄▀  º▄¥,
//        ,#▌Φ▓▄╓  Φ `█Q▄M╙                           ╙¥▄ ,▄▀ ╙▄⌐`  `Φ
//       ▄▀   `V,"▀▀¼╓╩└                                 ╙¥▓╗ ,       ╙▄
//      Φ       `¥═▄▀                            ╒          ▀▄          ▓
//    .▓         ╓▓]V▄H       ▓                 ,Å            ▀,         ▀
//    █      ,-ª▓╛  `██▀½      "▄  ,╓╓╓╓;╓▄▄▄▄╗▄█,             ╙▄         ▀
//   █  `██▄   ▓. - Φ█═.~     ,≤█▄▀-      `   █└"▀▀▀▀▄╓╓╓╓       ▌    ██▄, █
//  ║⌐  " ▀   ▓╨⌐   }▀`      ,█  `           █      .█▀▄▄███▄     ▌  ` ▀    ▌
//  ▌        ▐M A   '┴      ▌                ▀        ╙█▌████▌    ╙▄        ║⌐
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙▌▄███      █         ▌
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀▀ΦΦΦR≡≥▄╓ ║▄       ╙j▌` ▄▀╙╗ `╫
// █"      ╙▐H-═M ▄███████¥█H "^╙    '█, ,«^``     `     ║▌        ▐M▄▀    "Φ█
// ║        !█▄▄████≤═^`╓█ █▌╓▀╦▄▀█   ╙█⌐               ╓█▌        ▓ `       █
//  ▌      ,▄██╫██ ▄█═╜" █▌▐█╣Hj⌐ █    █▌╙¥w,           ██▄       ╓▌        ▐M
//  ╢"▄▄#▀▀╙╟█Ü███▀`▀█  ║██J█▄▌jH █    ██    ╙▀W▄;    ,██  `╙w,   █▄     ,╓ █
//   █╙     ▐███▌▀█w ▀█ ╠██████j▌║█▌   ▀██▄       `╙▓██▀w,     ╙╗█'`"▀█▀╙"`║`
//   ╙▌     Φ████████▄██ ███████████    ═██▀W▄,   ╓█▀└         ╓▀ "    ╙▄ ╓▀
//    ╙▄     ╙▀███╙█▄▐██▄,╙▀█████▄▀▄▀▄   ,█M╗ ▀▄██▀╙""*ⁿ═─≈-,,▄▌,        ▄▀
//     `▌╙µ,▄Φ▀x███▄██████████▀V███▀╙└ ,▄#▌████▀`"*«,      .█▀▄▀▄,      ▄╛
//       ▀Ö█  ;▓████████▄▄█▀▄╙W "V▄██▀▀│▄███▀└ ▀╦     "*═╥▄▀ ║,  ║▀▄  ,▓
//        ╙W▀ '█████╨▀▀█████████   "▀▀████└      ╙▄   ,▄▀'   `▀▀╣H ▐▀▄▀
//          ╙▄  ▀▀Γ╓▌  ▄▀ⁿ`╙▀███      ██▌         ╓█R▀▄A█        ▀▀▄▀
//            ╙W,Φ╙  ║█        ▄╙╙ª%≡╦██≤≤╗╗≡≡╜▀▀   ╣▌   █╕     ,▄▀
//              `▀▄M█┘        ║▀▌   ╫"    *Φ▄  █       Φ` ▀▌, ▄M╙
//                 "▀╦,       M ╙▌  ▀       `█W▐▌       wæQ▄▀╙
//                     ╙▀W╥,╓╣   ╙█║        ╫M  █    ,╓▄╝╙`
//                          ╙╙▀%▄▄▄▌,≤▄_▄≡,▐▓▓▄▄#ª▀"`

