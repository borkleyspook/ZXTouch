#import "ScriptPlayer.h"
#include "Play.h"
#include "SocketServer.h"
#include "Process.h"
#include "Task.h"
#include "AlertBox.h"
#include "Config.h"
#include "Common.h"
#import <rootless.h>
#import <Foundation/Foundation.h>
#include "NSTask.h"

static BOOL isPlaying = false;

@implementation ScriptPlayer
{
    int repeatTime;
    float interval;
    float speed;
    NSString* scriptBundlePath;
    UIWindow *_playIndicator;
    int currentScriptType; // -1 no task has specified; 0 not playing but has upcoming task; 1 raw file playing; 2 py file playing
    NSTimer *replayTimer;
    UIView *circleView;
    Boolean scriptPlayForceStop;
    Boolean switchAppBeforePlaying;
}

- (BOOL)isPlaying {
    return isPlaying;
}

- (NSString*)getCurrentBundlePath {
    if (!scriptBundlePath)
    {
        return @"";
    }
    return get_rootless_path(scriptBundlePath);
}

- (void)setPath:(NSString*)path {
    if (isPlaying)
    {
        NSLog(@"com.zjx.springboard: cannot change script path because a script is playing.");
        return;
    }
    scriptBundlePath = get_rootless_path(path);
}

- (void)setRepeatTime:(int)rt {
    if (isPlaying)
    {
        NSLog(@"com.zjx.springboard: cannot change repeat time because a script is playing.");
        return;
    }
    repeatTime = rt;
}

- (void)setInterval:(float)intv {
    if (isPlaying)
    {
        NSLog(@"com.zjx.springboard: cannot change interval because a script is playing.");
        return;
    }
    interval = intv;
}

- (void)setSpeed:(float)sp {
    if (isPlaying)
    {
        NSLog(@"com.zjx.springboard: cannot change speed because a script is playing.");
        return;
    }
    speed = sp;
}

- (void)setSwitchApp:(BOOL)value {
    if (isPlaying)
    {
        NSLog(@"com.zjx.springboard: cannot change speed because a script is playing.");
        return;
    }
    switchAppBeforePlaying = value;
}


- (id)init {
    self = [super init];
    if (self)
    {
        [self clear];
    }
    return self;
}

- (id)initWithPath:(NSString*)path {
    self = [super init];
    if (self)
    {
        scriptBundlePath = get_rootless_path(path);
        currentScriptType = -1;
    }
    return self;
}

-(int)runScript:(NSError**)error {
    if (!scriptBundlePath)
    {
        NSLog(@"com.zjx.springboard: Unable to run the script. ScriptBundlePath not set.");
        *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Unable to run the script. ScriptBundlePath not set.\r\n"}];
        return -1;
    }

    BOOL isDir;
    if (![[NSFileManager defaultManager] fileExistsAtPath:scriptBundlePath isDirectory:&isDir] || !isDir)
    {
        NSLog(@"com.zjx.springboard: Unable to run the script. Path not found or it is not a directory.");
        *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Unable to run the script. Path not found or it is not a directory.\r\n"}];
        return -1;
    }

    // read info.plist into dictionary
    NSString *infoFilePath = get_rootless_path([NSString stringWithFormat:@"%@/info.plist", scriptBundlePath]);
    if (![[NSFileManager defaultManager] fileExistsAtPath:infoFilePath isDirectory:&isDir])
    {
        NSLog(@"com.zjx.springboard: Unable to run the script. Info.plist not found.");
        *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Unable to run the script. Info.plist not found.\r\n"}];
        return -1;
    }
    NSDictionary *scriptInfo = [NSDictionary dictionaryWithContentsOfFile:infoFilePath];
    // get entry file extension
    NSString *entryFileName = scriptInfo[@"Entry"];
    NSString *fileExtension = [entryFileName pathExtension];

    NSString *foregroundApp = scriptInfo[@"FrontApp"];
    // call different functions depending on file extension

    // show indicator
    dispatch_async(dispatch_get_main_queue(), ^{
        _playIndicator = [[UIWindow alloc] initWithFrame:CGRectMake(0,0,10*2,10*2)];
        _playIndicator.windowLevel = UIWindowLevelStatusBar;
        _playIndicator.hidden = NO;
        [_playIndicator setBackgroundColor:[UIColor clearColor]];
        [_playIndicator setUserInteractionEnabled:NO];

        circleView = [[UIView alloc] initWithFrame:CGRectMake(0,0,10*2,10*2)];

        //circleView.alpha = 1;
        circleView.layer.cornerRadius = 10;  // half the width/height
        circleView.backgroundColor = [UIColor greenColor];
        [_playIndicator addSubview:circleView];
    });

    NSString *entryFilePath = get_rootless_path([scriptBundlePath stringByAppendingPathComponent:entryFileName]);
    NSLog(@"com.zjx.sprinboard: currently playing: %@. Repeat time: %d", entryFilePath, repeatTime);
    

    if ([fileExtension isEqualToString:@"raw"])
    {
        currentScriptType = 1;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError *err = nil;
            [self playFromRawFile:entryFilePath foregroundApp:foregroundApp err:&err];
        }); 
    }
    else if ([fileExtension isEqualToString:@"py"])
    {
        currentScriptType = 2;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError *err = nil;
            [self playFromPythonFile:entryFilePath foregroundApp:foregroundApp err:&err];
        });
        
    }
}

// play the script
- (int)play:(NSError**)error 
{
    if (isPlaying)
    {
        NSLog(@"com.zjx.springboard: Unable to run the script. Another script is currently running.");
        *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Unable to run the script. Another script is currently running.\r\n"}];
        return -1;
    }
   [self runScript:error];
}


-(void)playFromRawFile:(NSString*) filePath foregroundApp:(NSString*)foregroundApp err:(NSError**)err
{
    isPlaying = true;
    if (switchAppBeforePlaying)
    {
        bringAppForeground(foregroundApp);
    }

    FILE *file = fopen([filePath UTF8String], "r");

    if (!file)
    {
        showAlertBox(@"Error", [NSString stringWithFormat:@"Cannot play this script because zxtouch cannot open the file. File path: %@", filePath], 999);
        isPlaying = false;
        return;
    }
    
    char buffer[256];
    int taskType;
    int sleepTime;
    
    while (fgets(buffer, sizeof(char)*256, file) != NULL)
    {
        if (scriptPlayForceStop)
        {
            scriptPlayForceStop = false;
            break;
        }
        if (speed > 0 && speed != 1)
        {
            // check whether need to speed up
            int type, sleepTime;
            sscanf(buffer, "%2d", &type);
            if (type == TASK_USLEEP)
            {
                sscanf(buffer, "%2d%d", &type, &sleepTime);
                sleepTime = sleepTime / speed; // truncate the float part
                processTask((UInt8*)[[NSString stringWithFormat:@"18%d", sleepTime] UTF8String], NULL);
            }
            else
            {
                processTask((UInt8*)buffer, NULL);
            }
        }
        else
        {
            processTask((UInt8*)buffer, NULL);
        }

    }

    [self playHasStopped];
}

-(void) playFromPythonFile:(NSString*) filePath foregroundApp:(NSString*) foregroundApp err:(NSError**) err
{
    isPlaying = true;
    filePath = get_rootless_path(filePath);

    if (switchAppBeforePlaying)
    {
        bringAppForeground(foregroundApp);
    }
    
    // check python exists
    // Fix the python check
    if (![[NSFileManager defaultManager] fileExistsAtPath:ROOT_PATH_NS(@"/usr/bin/python3")])
    {
        showAlertBox(@"Error", @"Cannot play this script. /usr/bin/python3 not found. Please install Python 3 on your device.", 999);
        isPlaying = false;
        return;
    }
    else
    {
        // showAlertBox(@"Success", @"/usr/bin/python3 found.", 999);
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        showAlertBox(@"Error", [NSString stringWithFormat:@"Cannot play this script. Script file not found in bdl folder. Script path: %@", filePath], 999);
        isPlaying = false;
        return;
    }
    // Fix the command with rootless paths
    NSString *zxtouchbPath = ROOT_PATH_NS(@"/usr/bin/zxtouchb");
    // showAlertBox(@"Success", zxtouchbPath, 999);
    NSString *scriptRuntimePath = ROOT_PATH_NS(@"/var/mobile/Library/ZXTouch/coreutils/ScriptRuntime");
    // showAlertBox(@"Success", scriptRuntimePath, 999);
    NSString *commandToRun = [NSString stringWithFormat:@"%@ -e \"PYTHONPATH=/var/jb/usr/lib/python3/site-packages /var/jb/usr/bin/python3 -u \\\"%@\\\" 2>&1 | %@/add_datetime.sh\" >> %@/output", zxtouchbPath, filePath, scriptRuntimePath, scriptRuntimePath];
    // /var/jb/usr/bin/zxtouchb -e "PYTHONPATH=/var/jb/usr/lib/python3/site-packages /var/jb/usr/bin/python3 -u '/var/jb/var/mobile/Library/ZXTouch/scripts/examples/Device Info.bdl/device_info.py' 2>&1 | /var/jb/var/mobile/Library/ZXTouch/coreutils/ScriptRuntime/add_datetime.sh" >> /var/jb/var/mobile/Library/ZXTouch/coreutils/ScriptRuntime/output
    NSLog(@"com.zjx.springboard: command to run for running py file %@", commandToRun);
    // showAlertBox(@"Success", commandToRun, 999);

    // here I made it run in background because of a weird thing: ios objc cannot call second system() if the first system() does not return
    //scriptPlayForceStop = true;

    // Record the exact start time
    __weak typeof(self) weakSelf = self;
    NSDate *startDate = [NSDate date]; 

    // Inside your GUI App logic
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:get_rootless_path(@"/bin/sh")];
    [task setArguments:@[@"-c", commandToRun]];

    // DO NOT call [task waitUntilExit] if you want it in the background
    [task launch]; 

    // Instead of calling [self playHasStopped] immediately, 
    // use a completion block or a timer to check if the task is still running.

    // This block triggers ONLY when the script actually finishes
    [task setTerminationHandler:^(NSTask *t) {
        // Calculate the time difference immediately
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startDate];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Ensure UI-related updates happen on the main thread
            [weakSelf playHasStopped];
            NSLog(@"com.zjx.zxtouch: Script execution finished with status: %d", [t terminationStatus]);
            NSLog(@"com.zjx.zxtouch: Task detected as finished in %.2f seconds", duration);
        });
    }];
}

- (void)replay:(NSTimer*)nstimer {
    NSLog(@"com.zjx.springboard: script is replaying...");
    // showAlertBox(@"Success", @"com.zjx.springboard: script is replaying...", 999);
    NSError *err = nil;

    [self runScript:&err];

    CFRunLoopStop(CFRunLoopGetCurrent());
}

-(void) playHasStopped
{
    NSLog(@"com.zjx.springboard: script has finished");
    // showAlertBox(@"Success", @"com.zjx.springboard: script has finished", 999);

    // check whether need to replay
    if (repeatTime != 0)
    {    
        dispatch_async(dispatch_get_main_queue(), ^{
            circleView.backgroundColor = [UIColor orangeColor];
        });

        NSLog(@"com.zjx.springboard: need replay. Replay time: %d", repeatTime);

        replayTimer = [NSTimer scheduledTimerWithTimeInterval:interval
         target:self selector:@selector(replay:) 
         userInfo:nil repeats:NO];
        repeatTime--;

        currentScriptType = 0;

        CFRunLoopRun();
    }
    else
    {
        [self clear];
    }



}

- (void)clear {
    repeatTime = 0;
    interval = 0.0f;
    speed = 1.0f;
    scriptBundlePath = nil;
    isPlaying = false;
    currentScriptType = -1;
    //scriptPlayForceStop = false;

    // remove indicator
    dispatch_async(dispatch_get_main_queue(), ^{
        _playIndicator.hidden = YES;
        _playIndicator = nil;
    });

    if (replayTimer)
        [replayTimer invalidate];

    replayTimer = nil;
}

- (void)forceStop:(NSError**)error {
    if (currentScriptType == -1)
    {
        NSLog(@"com.zjx.springboard: Cannot stop playing script. No script is playing.");
        *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Cannot stop script. No script is playing.\r\n"}];
        return;
    }

    if (currentScriptType == 0)
    {
        [self clear];
    }
    else if (currentScriptType == 1)
    {
        // make stop to be true
        scriptPlayForceStop = true;
        [self clear];
    }
    else if (currentScriptType == 2)
    {
        // FIXED: kill all python3 process without sudo
        NSString *killCommand = [NSString stringWithFormat:@"%@ -e \"killall -9 python3\"", 
            ROOT_PATH_NS(@"/usr/bin/zxtouchb")];
        system2([killCommand UTF8String], NULL, NULL);
        [self clear];
    }
    else
    {
        NSLog(@"com.zjx.springboard: unknown currently playing script type.");
        *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Cannot stop script. Unknown currently playing script type.\r\n"}];
        return;
    }

}

@end