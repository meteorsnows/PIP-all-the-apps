
#import "PipWindow.h"

@implementation PipWindow

/**
 * In Interface Builder, the class for the window is set to this subclass.
 * Overriding the initializer provides a mechanism for controlling
 * how objects of this class are created.
 */
- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (NSWindowStyleMask) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag {
    
    // Using NSBorderlessWindowMask results in a window without a title bar.
    self = [super initWithContentRect: contentRect styleMask: NSWindowStyleMaskBorderless backing: NSBackingStoreBuffered defer: NO];

    if (self != nil) {
        // Start with no transparency for all drawing into the window
        self.alphaValue = 1.0;

        // Turn off opacity so that the parts of the window that are not drawn into are transparent.
        self.opaque = NO;

        self.backgroundColor = NSColor.clearColor;

        // Floating
        self.level = NSFloatingWindowLevel;
        self.titlebarAppearsTransparent = YES;
        //self.titleVisibility = NSWindowTitleHidden;

        // No decorations, no title
        // self.styleMask = NSWindowStyleMaskBorderless;

        // This is to stay on top even on full screen app
        // TODO option?
        self.collectionBehavior = NSWindowCollectionBehaviorStationary
         | NSWindowCollectionBehaviorCanJoinAllSpaces
         | NSWindowCollectionBehaviorFullScreenAuxiliary
         ;
    }
    return self;
}

/**
 * Custom windows that use the NSBorderlessWindowMask can't become key by default.
 * Override this method so that controls in this window will be enabled.
 */
- (BOOL) canBecomeKeyWindow {
    return YES;
}

/**
 * Start tracking a potential drag operation here when the user first clicks the mouse,
 * to establish the initial location.
 */
- (void) mouseDown: (NSEvent*) theEvent {
    // Get the mouse location in window coordinates.
    self.initialLocation = theEvent.locationInWindow;
}

/**
 * Once the user starts dragging the mouse, move the window with it.
 * The window has no title bar for the user to drag
 * (so we have to implement dragging ourselves)
 */
- (void) mouseDragged: (NSEvent*) theEvent {
    
    NSRect windowFrame = self.frame;
    NSPoint newOrigin = windowFrame.origin;

    // Get the mouse location in window coordinates.
    NSPoint currentLocation = theEvent.locationInWindow;
    // Update the origin with the difference between the new mouse location and the old mouse location.
    newOrigin.x += (currentLocation.x - self.initialLocation.x);
    newOrigin.y += (currentLocation.y - self.initialLocation.y);

    // Move the window to the new location
    [self setFrameOrigin: newOrigin];
}

@end
