// Import the rootless header for path macros
#import <rootless.h>

#define DOCUMENT_ROOT_FOLDER_NAME "ZXTouch"
#define RECORDING_FILE_FOLDER_NAME "recording"
#define SCRIPT_FOLDER_NAME "scripts"
#define CONFIG_FOLDER_NAME "config/tweak"
#define COMMON_CONFIG_NAME "config.plist"

// Use ROOT_PATH_NS for NSString paths
#define SCRIPT_PLAY_CONFIG_PATH ROOT_PATH_NS(@"/var/mobile/Library/ZXTouch/config/tweak/script_play_settings.plist")
#define ACTIVATOR_CONFIG_PATH ROOT_PATH_NS(@"/var/mobile/Library/ZXTouch/config/tweak/activator.plist")