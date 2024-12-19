#ifndef SCRIPT_PLAYER_H
#define SCRIPT_PLAYER_H

#import <Foundation/Foundation.h>

@interface ScriptPlayer : NSObject


- (void)setRepeatTime:(int)rt;
- (void)setInterval:(float)intv;
- (void)setSpeed:(float)sp;
- (void)setPath:(NSString*)path;
- (void)forceStop:(NSError**)error;
- (void)setSwitchApp:(BOOL)value;

- (id)initWithPath:(NSString*)path;

- (int)play:(NSError**)error;
- (BOOL)isPlaying;
- (NSString*)getCurrentBundlePath;

@end

#endif