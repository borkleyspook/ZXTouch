// Tweak.xm
// Modernized for ElleKit (Dopamine 2.x) and rootless iOS 15+
#import <execinfo.h>
#import <mach-o/dyld.h>
#include <string.h>
#import <dlfcn.h> // For dlopen/dlsym
#import <rootless.h> // For rootless awareness if needed

// ElleKit is the default hooking framework in Dopamine 2.0+
#import <ellekit.h>

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
    // Symbol-based hooking for maximum reliability
    void *symbol = dlsym(RTLD_DEFAULT, "_dyld_get_image_name");
    if (symbol) {
        HOOK(symbol, dyld_get_image_name_new, dyld_get_image_name_old);
    }
}