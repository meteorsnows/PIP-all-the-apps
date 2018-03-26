
#import "PipView.h"

@implementation PipView

/**
 * This routine is called at app launch time when this class is unpacked from the nib.
 */
- (void) awakeFromNib {
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 10.0;
}

@end
