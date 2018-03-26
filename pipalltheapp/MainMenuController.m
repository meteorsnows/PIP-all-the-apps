
#include <mach/mach_time.h>
#import "MainMenuController.h"

@implementation MainMenuController

/**
 * Refresh loop that will respect the framerate (image per seconds)
 */
- (void) startRefreshForBlock: (LooperBlock) block {
    if (self.refreshInProgress) {
        float time = 1000 / self.framerate;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [self startRefreshForBlock: block];
            block();
        });
    }
}

static int skipCountForLastSec = 0;

/**
 * This is started every seconds and shows the number of skipped frames then reset it to zero
 */
- (void) skipedLoopChecker {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self skipedLoopChecker];
        NSLog(@"Skiped frame last sec: %i", skipCountForLastSec);
        skipCountForLastSec = 0;
    });
}

#pragma mark - Lifecycle

- (void) awakeFromNib {
    self.framerate = FRAMERATE_HIGH;
    self.refreshInProgress = NO;

    // UI
    self.appMenu.delegate = self;
    self.appMenu.autoenablesItems = NO;

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSVariableStatusItemLength];
    self.statusItem.image = [NSImage imageNamed: @"MenuBarIcon"];
    self.statusItem.image.template = YES;
    self.statusItem.menu = self.appMenu;
    
    // [self skipedLoopChecker];
}

#pragma mark - PipWindowControllerDelegate

- (void) pipWindowClosed {
    self.refreshInProgress = NO;
}

- (void) pipWindowRefreshRate: (int) framerate {
    NSLog(@"Update framerate to: %i", framerate);
    self.framerate = framerate;
}

- (void) askForFullWindow {
    NSLog(@"Ask for full window");
    // Close the current pip
    [self.pipWindowController close];
    // Reopen it without bounds
    [self openPipWindowFor: self.currentWindowInfo];
}

- (void) askForSubRegion {
    NSLog(@"Ask for sub-region");
    // Close the current pip
    [self.pipWindowController close];
    
    // Create a new region window    
    if (self.regionWindowController) {
        [self.regionWindowController close];
    }
    
    self.regionWindowController = [RegionWindowController new];
    self.regionWindowController.delegate = self;
    self.regionWindowController.currentWindowInfo = self.currentWindowInfo;
    [self.regionWindowController setSize: self.currentWindowInfo.bounds.size];
    [self.regionWindowController showWindow: nil];
    [WindowInfo Capture: self.currentWindowInfo withBlock: ^(NSImage* image) {
        [self.regionWindowController setImage: image];
    }];
}

#pragma mark - RegionWindowControllerDelegate

- (void) didSelectRegion: (CGRect) region forWindowInfo: (WindowInfo*) windowInfo {
    self.currentScreenBounds = CGRectMake(
        windowInfo.bounds.origin.x + region.origin.x,
        windowInfo.bounds.origin.y + region.origin.y,
        region.size.width,
        region.size.height
    );
    NSLog(@"3- Did select region x:%f y:%f width:%f height:%f", self.currentScreenBounds.origin.x, self.currentScreenBounds.origin.y, self.currentScreenBounds.size.width, self.currentScreenBounds.size.height);
    [self openPipWindowFor: self.currentWindowInfo];
}

- (void) didNotSelectRegion {
    // Reopen pip window
    [self openPipWindowFor: self.currentWindowInfo];
}

#pragma mark - NSMenuDelegate

- (void) menuWillOpen: (NSMenu*) menu {
    [self updateWindowList];
}

#pragma mark - UI

- (void) resetAppMenu {
    for (NSMenuItem* menuItem in self.appMenu.itemArray) {
        if (menuItem.tag > 0) {
            [self.appMenu removeItem: menuItem];
        }
    }
}

- (void) buildAppMenuWithList: (WindowsInfoIndexed) windowInfoByName {
    [self resetAppMenu];
    for (NSString* index in windowInfoByName) {
        WindowsInfoArray list = windowInfoByName[index];
        NSMenuItem* menuItem;
        if (list.count <= 1) {
            menuItem = [self buildItemFromWindowInfo: list[0]];
        } else {
            // Sub list for App with multiple widows
            NSMenu* submenu = [NSMenu new];
            NSString* applicationName = @"";
            for (WindowInfo* windowInfo in list) {
                [submenu addItem: [self buildSubitemFromWindowInfo: windowInfo]];
                applicationName = windowInfo.applicationName;
            }
            menuItem = [self buildItemCommomWithTitle: applicationName];
            menuItem.submenu = submenu;
        }
        // Insert into the main menu from top
        // because we have Preferences and Quit at the bottom
        [self.appMenu insertItem: menuItem atIndex: 0];
    }
}

- (NSMenuItem*) buildItemCommomWithTitle: (NSString*) title {
    NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle: title action: nil keyEquivalent: @""];
    menuItem.tag = 1; // Tag 1 to allow to remove it easily later
    menuItem.enabled = YES;
    return menuItem;
}

- (NSMenuItem*) buildItemFromWindowInfo: (WindowInfo*) windowInfo {
    NSMenuItem* menuItem = [self buildItemCommomWithTitle: windowInfo.applicationName];
    // We use NSMenuItem with setRepresentedObject to pass the windoInfo object arround
    [menuItem setRepresentedObject: windowInfo];
    [menuItem setTarget: self];
    [menuItem setAction: @selector(onSelectedItem:)];
    return menuItem;
}

/**
 * in this case the sub list will display a live capture of each window so the user can choose
 */
- (NSMenuItem*) buildSubitemFromWindowInfo: (WindowInfo*) windowInfo {
    NSMenuItem* submenuItem = [[NSMenuItem alloc] initWithTitle: windowInfo.applicationName action: nil keyEquivalent: @""];
    submenuItem.enabled = YES;
    PipMenuButton* windowThumbButton = [[PipMenuButton alloc] initWithFrame: NSMakeRect(0, 0, 200, 160)];
    [WindowInfo Capture: windowInfo withBlock: ^(NSImage* image) {
        windowThumbButton.image = image;
    }];
    windowThumbButton.block = ^{
        [self onSelectedFromSubitemWithWindowInfo: windowInfo];
        [self.appMenu cancelTracking];
    };
    [submenuItem setView: windowThumbButton]; // custom view
    return submenuItem;
}

- (void) updateWindowList {
    [self buildAppMenuWithList: [WindowInfo List]];
}

#pragma mark - Actions

/**
 * Action when the sub-item is clicked in the menu
 */
- (void) onSelectedFromSubitemWithWindowInfo: (WindowInfo*) windowInfo {
    self.currentWindowInfo = windowInfo;
    self.currentScreenBounds = CGRectNull;
    NSLog(@"Selected: %@", windowInfo);
    [self openPipWindowFor: windowInfo];
}

/**
 * Action when the NSMenuItem is selected
 */
- (void) onSelectedItem: (NSMenuItem*) menuItem {
    // Get back the windowInfo
    WindowInfo* windowInfo = menuItem.representedObject;
    self.currentWindowInfo = windowInfo;
    self.currentScreenBounds = CGRectNull;
    NSLog(@"Selected: %@", windowInfo);
    [self openPipWindowFor: windowInfo];
}

- (void) openPipWindowFor: (WindowInfo*) windowInfo {

    if (self.pipWindowController) {
        [self.pipWindowController close];
    }

    self.pipWindowController = [PipWindowController new];
    self.pipWindowController.delegate = self;
    self.pipWindowController.currentWindowInfo = self.currentWindowInfo;
    [self.pipWindowController setClickThrough: self.isClickThrough];
    if (CGRectIsNull(self.currentScreenBounds)) {
        [self.pipWindowController setRatioFromSize: self.currentWindowInfo.bounds.size];
    }
    else {
        [self.pipWindowController setRatioFromSize: self.currentScreenBounds.size];
    }
    [self.pipWindowController showWindow: nil];
#if TIMING
    // [self stress];
    // return;
#endif
    // Allow refresh and start it
    self.refreshInProgress = YES;
    [self startRefreshForBlock: [self refreshBlock]];
}

/**
 * The actual refresh action
 */
- (LooperBlock) refreshBlock {
    return ^{
        // If a capture is already in progress while we are asked for a new loop
        // skip and report the skip
        if (self.captureInProgress) {
            skipCountForLastSec++;
            return;
        }

        self.captureInProgress = YES;
        [WindowInfo Capture: self.currentWindowInfo at: self.currentScreenBounds withBlock: ^(NSImage* image) {
            [self.pipWindowController setImage: image];
            self.captureInProgress = NO;
        }];
        return;
    };
}

- (IBAction) clickThroughAction: (NSMenuItem*) sender {
    self.isClickThrough = !self.isClickThrough;
    sender.state = self.isClickThrough ? NSControlStateValueOn : NSControlStateValueOff;
    if (self.pipWindowController) {
        [self.pipWindowController setClickThrough: self.isClickThrough];
    }
}

- (IBAction) preferencesAction: (NSMenuItem*) sender {
    if (self.preferencesWindowController == nil) {
        self.preferencesWindowController = [PreferencesWindowController new];
    }
    [self.preferencesWindowController showWindow: nil];
}

- (IBAction) quitAction: (NSMenuItem*) sender {
    [NSApp terminate: self];
}

#pragma mark - Helpers

#if TIMING
// This method is to test the speed of the capturing process
- (void) stress {
    [WindowInfo Capture: self.currentWindowInfo withBlock: ^(NSImage* image) {
        self.pipWindowController.pipImageView.image = image;
        [self stress];
    }];
}
#endif

@end
