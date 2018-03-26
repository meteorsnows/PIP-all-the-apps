
#import <Cocoa/Cocoa.h>

typedef void (^PipMenuButtonBlock)(void);

@interface PipMenuButton : NSImageView

@property (nonatomic, strong) PipMenuButtonBlock block;

@end
