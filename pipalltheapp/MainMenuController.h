
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Constant.h"
#import "WindowInfo.h"
#import "PreferencesWindowController.h"
#import "PipWindowController.h"
#import "PipMenuButton.h"
#import "RegionWindowController.h"

typedef void (^LooperBlock)(void);

@interface MainMenuController : NSObject <NSMenuDelegate, PipWindowControllerDelegate, RegionWindowControllerDelegate>

@property (assign) BOOL isClickThrough;
@property (nonatomic) BOOL captureInProgress;
@property (nonatomic) BOOL refreshInProgress;
@property (nonatomic) int framerate; // Frames per second
@property (strong, nonatomic) WindowInfo* currentWindowInfo;
@property (nonatomic) CGRect currentScreenBounds;

@property (strong, nonatomic) NSStatusItem* statusItem;
@property (weak) IBOutlet NSMenu* appMenu;
@property (weak) IBOutlet NSMenuItem* loadingMenuItem;

@property (strong, nonatomic) PreferencesWindowController* preferencesWindowController;
@property (strong, nonatomic) PipWindowController* pipWindowController;
@property (strong, nonatomic) RegionWindowController* regionWindowController;

@end
