
#import "PipWindowController.h"

@implementation PipWindowController

- (NSString*) windowNibName {
    return @"PipWindowController";
}

- (void) windowDidLoad {
    [super windowDidLoad];
    [self setClickThrough: NO];
    self.window.delegate = self;

    // Hover
    NSTrackingArea* area = [[NSTrackingArea alloc] initWithRect: self.view.frame options: NSTrackingMouseEnteredAndExited
         | NSTrackingInVisibleRect
         | NSTrackingActiveAlways
         owner: self userInfo: nil
    ];
    [self.view addTrackingArea: area];
    self.overlayViewContainer.hidden = YES;
}

- (void) setImage: (NSImage*) image {
    self.pipImageView.image = image;
}

- (void) setRatioFromSize: (CGSize) size {
    self.window.contentAspectRatio = size;
    CGFloat width  = 300;
    CGFloat height = width * size.height / size.width;
    [self.window setFrame: NSMakeRect(0, 0, width, height) display: NO animate: NO];
}

- (void) showWindow: (id) sender {
    [super showWindow: sender];
    [self.window center];
    [self.window makeKeyAndOrderFront: nil];
    [NSApp activateIgnoringOtherApps: YES];
}

- (void) setClickThrough: (BOOL) isClickThrough {
    self.isClickThrough = isClickThrough;
    self.window.ignoresMouseEvents = self.isClickThrough;
}

#pragma mark - NSWindowDelegate

- (void) windowWillClose: (NSNotification*) notification {
    [self.delegate pipWindowClosed];
}

#pragma mark - Actions

- (IBAction) actionHighFramerate: (NSButtonCell*) sender {
    NSLog(@"High Framerate selected");
    [self.delegate pipWindowRefreshRate: FRAMERATE_HIGH];
}

- (IBAction) actionLowFramerate: (NSButtonCell*) sender {
    NSLog(@"Low Framerate selected");
    [self.delegate pipWindowRefreshRate: FRAMERATE_LOW];
}

- (IBAction) actionClose: (NSButton*) sender {
    [self.window close];
}

- (IBAction) actionAlpha: (NSSlider*) sender {
    self.window.alphaValue = sender.floatValue / 100.0;
}

- (IBAction) actionBringToFront: (NSButton*) sender {
    NSRunningApplication* run = [NSRunningApplication runningApplicationWithProcessIdentifier: self.currentWindowInfo.pid];
    [run activateWithOptions: NSApplicationActivateIgnoringOtherApps];
}

- (IBAction) actionDefineSubRegion: (NSButton*) sender {
    [self.delegate askForSubRegion];
}

- (IBAction) actionEndSubRegion: (NSButton*) sender {
    [self.delegate askForFullWindow];
}

- (void) mouseEntered: (NSEvent*) theEvent {
    if (self.isClickThrough) return;
    self.overlayViewContainer.hidden = NO;
}

- (void) mouseExited: (NSEvent*) theEvent {
    // if (self.isClickThrough) return;
    self.overlayViewContainer.hidden = YES;
}

- (void) mouseDown: (NSEvent*) theEvent {

}

@end
