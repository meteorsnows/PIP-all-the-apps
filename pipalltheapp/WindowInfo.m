
#import "WindowInfo.h"

@implementation WindowInfo


CGWindowListOption listOptions = kCGWindowListOptionAll
| kCGWindowListOptionOnScreenOnly
| kCGWindowListExcludeDesktopElements
;

/**
 * Optimization notes:
 * using kCGWindowImageNominalResolution compared to none
 *     reduce the time to capture (TTC) by a factor of 3
 *     and drop the CPU usage from 50% to 14% (relative value mesured on my mac)
 * not using kCGWindowImageShouldBeOpaque
 *     reduce the TTC of 0.5ms and drop the CPU usage from 14% to 11%
 */
CGWindowImageOption imageOptions = kCGWindowImageDefault
| kCGWindowImageBoundsIgnoreFraming
| kCGWindowImageNominalResolution
;

CGWindowListOption captureOptions = kCGWindowListOptionIncludingWindow;

/**
 * Ask the window server for the list of windows
 */
+ (WindowsInfoIndexed) List {
#if TIMING
    int start = getUptimeInMilliseconds();
#endif
    CFArrayRef cgWindowList = CGWindowListCopyWindowInfo(listOptions, kCGNullWindowID);
#if TIMING
    NSLog(@"Listed windows in: %ims", getUptimeInMilliseconds() - start);
#endif

    int order = 0;
    NSMutableDictionary<NSString*, WindowsInfoArray>* windowInfoByName = [NSMutableDictionary new];
    NSArray* windowList = CFBridgingRelease(cgWindowList);
    for (NSDictionary* windoRawInfo in windowList) {
        WindowInfo* windowInfo = [WindowInfo FilterWindowList: windoRawInfo andOrder: ++order];
        if (windowInfo != nil) {
            if (windowInfoByName[windowInfo.applicationName] == nil) {
                windowInfoByName[windowInfo.applicationName] = [NSMutableArray new];
            }
            [windowInfoByName[windowInfo.applicationName] addObject: windowInfo];
        }
    }

    return windowInfoByName;
}

/**
 * Actual code for the window image capture
 * The block will be passed a NSImage and will be called on the main thread
 * The parameter `screenBounds' specifies the rectangle in screen space
 * (origin at the upper-left; y-value increasing downward). Setting
 * `screenBounds' to `CGRectInfinite' will include all the windows on the
 * entire desktop. Setting `screenBounds' to `CGRectNull' will use the
 * bounding box of the specified windows as the screen space rectangle.
 */
+ (void) Capture: (WindowInfo*) windowInfo at: (CGRect) screenBounds withBlock: (NSImageBlock) block {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        
#if TIMING
        int start = getUptimeInMilliseconds();
#endif
        CGImageRef windowImage = CGWindowListCreateImage(screenBounds, captureOptions, windowInfo.windowId, imageOptions);
#if TIMING
        NSLog(@"Captured window in: %ims", getUptimeInMilliseconds() - start);
#endif

        if (windowImage != NULL) {
            /**
             * Optimization notes:
             * NSImage *image = [[NSImage alloc] initWithCGImage: windowImage size:NSZeroSize];
             * will take 90% CPU using NSBitmapImageRep is a must here (down to 50% before other optimizations)
             */
            NSBitmapImageRep* bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage: windowImage];
            NSImage* image = [[NSImage alloc] init]; // not using new here
            [image addRepresentation: bitmapRep];
            dispatch_async(dispatch_get_main_queue(), ^{
                block(image);
            });
            CGImageRelease(windowImage);
        }
    });
}

+ (void) Capture: (WindowInfo*) windowInfo withBlock: (NSImageBlock) block {
    [self Capture: windowInfo at: CGRectNull withBlock: block];
}

/**
 * Window info parsing and filtering
 */
+ (nullable WindowInfo*) FilterWindowList: (NSDictionary*) entry andOrder: (int) order {

    // The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
    // However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
    int sharingState = [entry[(id) kCGWindowSharingState] intValue];
    if (sharingState != kCGWindowSharingNone) {
        // Here we filter by window size, if it is too small we remove it as it will mostly be a Menu Bar App
        // So we grab the Window Bounds
        CGRect bounds;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef) entry[(id) kCGWindowBounds], &bounds);
        if (bounds.size.width < 48 || bounds.size.height < 48) return nil;

        WindowInfo* windowInfo = [WindowInfo new];
        windowInfo.bounds = bounds;

        // PID is required so we assume it's present.
        windowInfo.pid = [entry[(id) kCGWindowOwnerPID] intValue];;

        // Grab the application name, but since it's optional we need to check before we can use it.
        // Non named app will be under the same "Other Apps" entry
        NSString* applicationName = entry[(id) kCGWindowOwnerName];
        if (applicationName == NULL) {
            // The application name was not provided, so we group these under "Other Apps"
            applicationName = @"Other Apps";
        }

        // Some app are removed by name, example: Dock
        if (
            [applicationName caseInsensitiveCompare: @"Dock"] == NSOrderedSame ||
            [applicationName caseInsensitiveCompare: @"pipalltheapp"] == NSOrderedSame
            ) {
            return nil;
        }
        windowInfo.applicationName = applicationName;

        // Grab the Window ID & Window Level. Both are required, so just copy from one to the other
        windowInfo.windowId = [entry[(id) kCGWindowNumber] unsignedIntValue];
        // windowInfo.windowLevelKey = entry[(id) kCGWindowLayer];

        // Finally, we are passed the windows in order from front to back by the window server
        // keep that order by maintaining a window order key that we'll use later
        windowInfo.windowOrder = order;
        return windowInfo;
    }
    return nil;
}

- (NSString*) description {
    return [NSString stringWithFormat: @"WindowInfo: '%@' id: %i order: %i", self.applicationName, self.windowId, self.windowOrder];
}

#if TIMING
int getUptimeInMilliseconds() {
    const int64_t kOneMillion = 1000 * 1000;
    static mach_timebase_info_data_t timebaseInfo;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        (void) mach_timebase_info(&timebaseInfo);
    });
    return (int)((mach_absolute_time() * timebaseInfo.numer) / (kOneMillion * timebaseInfo.denom));
}
#endif

@end
