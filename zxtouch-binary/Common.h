#import <Foundation/Foundation.h>

// This allows any file that imports Common.h to use the function
static inline NSString* get_rootless_path(NSString* path) {
    if (!path) return nil;
    if ([path hasPrefix:@"/var/jb/"]) {
        return path;
    }
    return [@"/var/jb" stringByAppendingString:path];
}