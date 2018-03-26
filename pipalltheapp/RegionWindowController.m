
#import "RegionWindowController.h"

@implementation RegionWindowController

- (NSString*) windowNibName {
    return @"RegionWindowController";
}

- (void) windowDidLoad {
    [super windowDidLoad];
    self.window.delegate = self;
    self.regionSelectableView.delegate = self;
    self.regionSelectableView.alphaValue = 0.5;
}

- (void) showWindow: (id) sender {
    [super showWindow: sender];
    [self.window center];
    [self.window makeKeyAndOrderFront: nil];
    [NSApp activateIgnoringOtherApps: YES];
}

- (void) setImage: (NSImage*) image {
    self.imageView.image = image;
}

- (void) setSize: (NSSize) size {
    self.window.contentAspectRatio = size;
    [self.window setFrame: CGRectMake(0, 0, size.width, size.height) display: NO animate: NO];
}

#pragma mark - NSWindowDelegate

- (void) windowWillClose: (NSNotification*) notification {
    // [self.delegate didNotSelectRegion];
}

#pragma mark - RegionSelectableViewDelegate

- (void) didSelectRect: (NSRect) rect {
    CGRect convertedRect = CGRectMake(
        rect.origin.x,
        self.window.frame.size.height - rect.origin.y - rect.size.height,
        rect.size.width,
        rect.size.height
    );
    [self.delegate didSelectRegion: convertedRect forWindowInfo: self.currentWindowInfo];
    [self close];
}

@end
