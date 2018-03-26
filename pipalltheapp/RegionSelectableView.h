
#import <Cocoa/Cocoa.h>

@protocol RegionSelectableViewDelegate

- (void) didSelectRect: (NSRect) rect;

@end

@interface RegionSelectableView : NSView

@property (weak) id <RegionSelectableViewDelegate> delegate;

@end
