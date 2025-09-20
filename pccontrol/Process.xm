#include "Process.h"
#include "Common.h"
int (*openApp)(CFStringRef, Boolean);

static void* sbServices = NULL;

int switchProcessForegroundFromRawData(UInt8 *eventData)
{
    return bringAppForeground([NSString stringWithFormat:@"%s", eventData]);
}

int bringAppForeground(NSString *appIdentifier)
{
    // Lazy load SpringBoardServices framework
    if (!sbServices) {
        sbServices = dlopen("/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices", RTLD_LAZY);
        if (!sbServices) {
            NSLog(@"### com.zjx.springboard: Failed to load SpringBoardServices framework");
            return -1;
        }
    }
    
    CFStringRef appBundleName = CFStringCreateWithFormat(NULL, NULL, CFSTR("%@"), appIdentifier);
    NSLog(@"### com.zjx.springboard: Switch to application: %@", appBundleName);
    
    if (!openApp) {
        openApp = (int(*)(CFStringRef, Boolean))dlsym(sbServices,"SBSLaunchApplicationWithIdentifier");
        if (!openApp) {
            NSLog(@"### com.zjx.springboard: Failed to find SBSLaunchApplicationWithIdentifier");
            CFRelease(appBundleName);
            return -1;
        }
    }

    int result = openApp(appBundleName, false);
    CFRelease(appBundleName);
    return result;
}

id getFrontMostApplication()
{
    //TODO: might cause problem here. Both _accessibilityFrontMostApplication failed or front most application springboard will cause app be nil.
    __block id app = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        @try{
            SpringBoard *springboard = (SpringBoard*)[%c(SpringBoard) sharedApplication];
            app = [springboard _accessibilityFrontMostApplication];
            //NSLog(@"com.zjx.springboard: app: %@, id: %@", app, [app displayIdentifier]);
        }
        @catch (NSException *exception) {
            NSLog(@"com.zjx.springboard: Debug: %@", exception.reason);
        }
    });
    return app;
}