//
//  Config.h
//  zxtouch
//
//  Created by Jason on 2021/1/16.
//

#ifndef Config_h
#define Config_h

// Import the rootless header for path macros
#import <rootless.h>

// Use ROOT_PATH_NS for NSString paths and ROOT_PATH for C strings
#define SCRIPTS_PATH ROOT_PATH_NS(@"/mobile/Library/ZXTouch/scripts/")
#define RUNTIME_OUTPUT_PATH ROOT_PATH_NS(@"/mobile/Library/ZXTouch/coreutils/ScriptRuntime/output")

#define SPRINGBOARD_CONFIG_PATH ROOT_PATH_NS(@"/mobile/Library/ZXTouch/config/tweak/config.plist")

#define SCRIPT_PLAY_CONFIG_PATH ROOT_PATH_NS(@"/mobile/Library/ZXTouch/config/tweak/script_play_settings.plist")
#define ACTIVATOR_CONFIG_PATH ROOT_PATH_NS(@"/mobile/Library/ZXTouch/config/tweak/activator.plist")

#define TOUCH_INDICATOR_DEFAULT_ALPHA 0.7

#endif /* Config_h */
