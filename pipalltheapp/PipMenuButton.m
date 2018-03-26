
#import "PipMenuButton.h"

@implementation PipMenuButton

- (BOOL) acceptsFirstResponder {
    return YES;
}

- (void) mouseDown: (NSEvent*) theEvent {
    if (self.block) self.block();
    //[super mouseDown: theEvent];
}

@end
