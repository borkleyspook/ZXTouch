// Tweak.xm
// Modernized for rootless iOS 15+
#import <execinfo.h>
#import <mach-o/dyld.h>
#include <string.h>
#import <dlfcn.h> // For dlopen/dlsym
#import <rootless.h> // For rootless awareness if needed

// since the tweak is injected to the applications, it should be hidden in case of unexpected behaviors
static char *(*dyld_get_image_name_old)(uint32_t index);
char *dyld_get_image_name_new(uint32_t index);

char *dyld_get_image_name_new(uint32_t index)
{
    char *imageName = dyld_get_image_name_old(index);
    
    // Robust method: Check for the dylib name anywhere in the path
    // This works regardless of install location (rootful, rootless, or different jailbreak)
    if (imageName && strstr(imageName, "appdelegate.dylib") != NULL) {
        return "/System/Library/PrivateFrameworks/CertUI.framework/CertUIA";
    }
    
    return imageName;
}

// Constructor - called when the tweak loads
__attribute__((constructor)) static void init() {
    // Use libhooker's LBHookFunction instead of MSHookFunction
    LBHookFunction((void *)_dyld_get_image_name, 
                   (void *)dyld_get_image_name_new, 
                   (void **)&dyld_get_image_name_old);
    
    NSLog(@"[ZXTouch] Tweak loaded successfully with libhooker");
}