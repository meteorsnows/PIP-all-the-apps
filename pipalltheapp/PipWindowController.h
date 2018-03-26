
#import <Cocoa/Cocoa.h>
#import "Constant.h"
#import "WindowInfo.h"

@protocol PipWindowControllerDelegate

- (void) pipWindowClosed;
- (void) pipWindowRefreshRate: (int) framerate;
- (void) askForFullWindow;
- (void) askForSubRegion;

@end

@interface PipWindowController : NSWindowController <NSWindowDelegate>

@property (weak) IBOutlet NSView* view;
@property (weak) IBOutlet NSImageView* pipImageView;
@property (weak) IBOutlet NSBox* overlayViewContainer;
@property (weak) id<PipWindowControllerDelegate> delegate;
@property (weak) WindowInfo* currentWindowInfo;
@property (assign) BOOL isClickThrough;

- (void) setClickThrough: (BOOL) isClickThrough;
- (void) setImage: (NSImage*) image;
- (void) setRatioFromSize: (CGSize) size;

@end
