
#import <Cocoa/Cocoa.h>
#import "WindowInfo.h"
#import "RegionSelectableView.h"

@protocol RegionWindowControllerDelegate

- (void) didSelectRegion: (CGRect) region forWindowInfo: (WindowInfo*) windowInfo;
- (void) didNotSelectRegion;

@end

@interface RegionWindowController : NSWindowController <NSWindowDelegate, RegionSelectableViewDelegate>

@property (weak) IBOutlet NSImageView* imageView;
@property (weak) id<RegionWindowControllerDelegate> delegate;
@property (weak) WindowInfo* currentWindowInfo;
@property (weak) IBOutlet RegionSelectableView *regionSelectableView;

- (void) setSize: (NSSize) size;
- (void) setImage: (NSImage*) image;

@end
