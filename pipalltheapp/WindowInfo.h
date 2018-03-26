
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@class WindowInfo;

typedef NSMutableArray<WindowInfo*>* WindowsInfoArray;
typedef NSMutableDictionary<NSString*, WindowsInfoArray>* WindowsInfoIndexed;
typedef void (^NSImageBlock)(NSImage*);

@interface WindowInfo : NSObject

@property (nonatomic, strong) NSString* applicationName;
@property (nonatomic) unsigned int windowId;
@property (nonatomic) int windowOrder;
@property (nonatomic) CGRect bounds;
@property (nonatomic) int pid;

+ (WindowsInfoIndexed) List;
+ (void) Capture: (WindowInfo*) windowInfo withBlock: (NSImageBlock) block;
+ (void) Capture: (WindowInfo*) windowInfo at: (CGRect) screenBounds withBlock: (NSImageBlock) block;

@end
