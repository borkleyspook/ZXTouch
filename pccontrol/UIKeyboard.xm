#include "UIKeyboard.h"
#import <Foundation/NSDistributedNotificationCenter.h>

#define TASK_GET_TEXT_FROM_CLIPBOARD 6
#define TASK_SAVE_TEXT_TO_CLIPBOARD 7

NSString* inputTextFromRawData(UInt8 *eventData, NSError **error)
{
    NSArray *data = [[NSString stringWithUTF8String:(char*)eventData] componentsSeparatedByString:@";;"];

    NSString *taskContent = @"";

    if ([data count] < 1) {
        *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Error: Specify task id.\r\n"}];
        return nil;
    }

    if ([data count] >= 2) {
        taskContent = data[4];
    }

    // This broadcast is safe; it tells the TWEAK inside Notes to do the work.
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.zjx.zxtouch.keyboardcontrol" 
                                                                   object:NULL 
                                                                 userInfo:@{@"task_id": data, @"task_content": taskContent} 
                                                        deliverImmediately:true];
    return @"";
}