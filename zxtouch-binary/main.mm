#import <Foundation/Foundation.h>
#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <string.h>
#include "Common.h"
#include "NSTask.h" // in ~/theos/include/NSTask.h

#define SPRINGBOARD_PORT 6000
#define equal(a, b) strcmp(a, b) == 0

int executeCommand();
int playBackFromRawFile();

int getSpringboardSocket() {
    int sock = 0, valread;
     struct sockaddr_in serv_addr;

     if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0)
     {
         NSLog(@"### com.zjx.zxtouchb:  Socket creation error");
         return -1;
     }
    
     serv_addr.sin_family = AF_INET;
     serv_addr.sin_port = htons(SPRINGBOARD_PORT);
        
     // Convert IPv4 and IPv6 addresses from text to binary form
     if(inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr)<=0)
     {
         NSLog(@"### com.zjx.zxtouchb: Invalid address. Address not supported");
         return -1;
     }
    
     if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0)
     {
         NSLog(@"### com.zjx.zxtouchb: \nConnection Failed \n");
         return -1;
     }
    
    return sock;
}


int main(int argc, char *argv[], char *envp[]) {
    if (argc < 2)
    {
        NSLog(@"com.zjx.zxtouchb: usage: zxtouchd task [...]");
        printf("com.zjx.zxtouchb: usage: zxtouchd task [...]");
        return 0;
    }
    
    if (equal(argv[1], "-e"))
    {
        executeCommand();
        // notify tweak that the task has been finished
        //int spSocket = getSpringboardSocket();
        //send(spSocket, "90\r\n", strlen("90\r\n"), 0);
        //NSLog(@"com.zjx.zxtouchb: 90 has been sent");
    }
    else if (equal(argv[1], "-pr")) // play back from raw file
    {
        playBackFromRawFile();
    }
    else
    {
        NSLog(@"com.zjx.zxtouchb: usage: zxtouchd [parameter] [...]");
    }

    /*
    else if (strcmp(argv[1], "-r") == 0 || strcmp(argv[1], "--run-script-from-shell-output") == 0) //when user want to run scripts on local machine, then they don't have to create socket themself. They can use this.
    {
        if (argc < 3)
        {
            NSLog(@"com.zjx.zxtouchb: please specify command to run.");
            return 0;
        }
        
        int sbSocket = getSpringboardSocket();
        NSString *commandToSend = [NSString stringWithFormat:@"17%s\n\r", argv[2]];

        char *commandToSendChar = (char*)[commandToSend UTF8String];
        send(sbSocket , commandToSendChar, strlen(commandToSendChar) , 0);
        close(sbSocket);
    }
    else if (strcmp(argv[1], "--content-from-file") == 0)
    {
        if (argc < 3)
        {
            NSLog(@"com.zjx.zxtouchb: please specify file path.");
            return 0;
        }
    
        system([[NSString stringWithFormat:@"cat %s", argv[2]] UTF8String]);
    }
    else
     */

    return 0;
}

int executeCommand()
{
    NSArray *parameterArr = [[NSProcessInfo processInfo] arguments];

    if ([parameterArr count] < 3)
    {
        NSLog(@"com.zjx.zxtouchb: please specify the command to be executed.");
        return 0;
    }
    NSLog(@"com.zjx.zxtouchb: command to run: %@", [NSString stringWithFormat:@"%@", parameterArr[2]] );

    @autoreleasepool {
        NSTask *task = [[NSTask alloc] init];

        // 设置执行的命令和参数
        // FIX: Redirect the shell path to the rootless location
        // Use the function we created earlier: get_rootless_path(@"/bin/sh")
        NSString *shellPath = get_rootless_path(@"/bin/sh");
        [task setLaunchPath:shellPath]; 

        // Use index 2 as established in your command structure
        [task setArguments:@[@"-c", parameterArr[1]]];

        NSPipe *outputPipe = [NSPipe pipe];
        NSPipe *errorPipe = [NSPipe pipe]; // Create error pipe
        [task setStandardOutput:outputPipe];
        [task setStandardError:errorPipe]; // Capture errors

        [task launch];
        [task waitUntilExit];

        // Read Standard Output
        NSData *outData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];

        // Read Standard Error
        NSData *errData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        NSString *errorOutput = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];

        // Print to terminal immediately
        if (output.length > 0) {
            printf("STDOUT: %s\n", [output UTF8String]);
        }
        if (errorOutput.length > 0) {
            printf("STDERR: %s\n", [errorOutput UTF8String]);
        }
        
        // Also print the exit status
        printf("Task Exited with status: %d\n", [task terminationStatus]);
        fflush(stdout); 
    }
    
    //return system([[NSString stringWithFormat:@"%@", parameterArr[2]] UTF8String]);
}


int playBackFromRawFile()
{
    NSArray *parameterArr = [[NSProcessInfo processInfo] arguments];

    if ([parameterArr count] < 3)
    {
        NSLog(@"com.zjx.zxtouchb: please specify the raw file path.");
        return 0;
    }
    
    int sbSocket = getSpringboardSocket();
    
    FILE *file = fopen([parameterArr[2] UTF8String], "r");
    
    char buffer[256];
    int taskType;
    int sleepTime;
    
    while (fgets(buffer, sizeof(char)*256, file) != NULL){
        //NSLog(@"sleep: %s",buffer);

        sscanf(buffer, "%2d%d", &taskType, &sleepTime);
        if (taskType == 18)
        {
            //[NSThread sleepForTimeInterval:sleepTime/1000000];
            usleep(sleepTime/2);
        }
        else
        {
            send(sbSocket , buffer, strlen(buffer) , 0);
        }
    }
}

