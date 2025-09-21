// Tweak.xm - Clean Substrate version
#import <execinfo.h>
#import <mach-o/dyld.h>
#include <string.h>
#import <rootless.h> // For rootless awareness if needed
#include <substrate.h>

static char *(*dyld_get_image_name_old)(uint32_t index);
char *dyld_get_image_name_new(uint32_t index);

char *dyld_get_image_name_new(uint32_t index)
{
    char *imageName = dyld_get_image_name_old(index);
    
    if (imageName && strstr(imageName, "appdelegate.dylib") != NULL) {
        return (char *)"/System/Library/PrivateFrameworks/CertUI.framework/CertUIA";
    }
    return imageName;
}

%ctor {
    MSHookFunction((void *)_dyld_get_image_name, (void *)dyld_get_image_name_new, (void **)&dyld_get_image_name_old);
    NSLog(@"[ZXTouch] Tweak loaded successfully with Substrate");
}