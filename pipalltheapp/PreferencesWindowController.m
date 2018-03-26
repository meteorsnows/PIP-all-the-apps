
#import "PreferencesWindowController.h"

@interface PreferencesWindowController ()

@end

@implementation PreferencesWindowController

- (NSString*) windowNibName {
    return @"PreferencesWindowController";
}

- (void) windowDidLoad {
    [super windowDidLoad];
    [self.window center];
    [self.window makeKeyAndOrderFront: nil];
    [NSApp activateIgnoringOtherApps: YES];
    // TODO when clicking on preference while
    // the window is not foreground it should show it
}

@end
