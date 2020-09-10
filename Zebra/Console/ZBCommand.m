//
//  ZBCommand.m
//  Zebra
//
//  Created by Wilson Styres on 9/9/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBCommand.h"
#import <spawn.h>

extern char **environ;

@interface ZBCommand () {
    id <ZBCommandDelegate> delegate;
}
@end

@implementation ZBCommand

- (id)initWithDelegate:(id <ZBCommandDelegate>)delegate {
    self = [super init];
    
    if (self) {
        self->delegate = delegate;
    }
    
    return self;
}

- (int)runCommand:(NSString *)command withArguments:(NSArray *)arguments asRoot:(BOOL)root {
    
    // Setup su/sling if needed
    if (root) {
        NSMutableArray *trueArgs = [arguments mutableCopy];
        [trueArgs insertObject:command atIndex:0];
        
        command = @"/usr/libexec/zebra/supersling";
        arguments = trueArgs;
    }
    
    // Create output and error pipes
    int *outPipe = malloc(sizeof(int) * 2);
    int *errPipe = malloc(sizeof(int) * 2);
    if (pipe(outPipe) == -1 || pipe(errPipe) == -1) {
        free(outPipe);
        free(errPipe);
        return errno; // pipe() sets errno on failure
    }
    
    // Create our file actions to read data back from posix_spawn
    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_addclose(&actions, outPipe[0]);
    posix_spawn_file_actions_addclose(&actions, errPipe[0]);
    posix_spawn_file_actions_adddup2(&actions, outPipe[1], STDOUT_FILENO);
    posix_spawn_file_actions_adddup2(&actions, errPipe[1], STDERR_FILENO);
    posix_spawn_file_actions_addclose(&actions, outPipe[1]);
    posix_spawn_file_actions_addclose(&actions, errPipe[1]);
    
    // Convert our arguments array from NSStrings to char pointers
    NSUInteger count = [arguments count];
    char **argv = (char **)malloc((count + 1) * sizeof(char*));

    for (unsigned int i = 0; i < count; i++) {
        argv[i] = strdup([[arguments objectAtIndex:i] UTF8String]);
    }
    argv[count] = NULL;
    
    // Spawn the child process
    pid_t pid = 0;
    int ret = posix_spawnp(&pid, [command UTF8String], &actions, nil, argv, environ);
    free(argv);
    if (ret < 0) {
        close(outPipe[0]);
        close(outPipe[1]);
        free(outPipe);
        close(errPipe[0]);
        close(errPipe[1]);
        free(errPipe);
        return ret;
    }
    
    // Close the write ends of the pipes so no odd data comes through them
    close(outPipe[1]);
    close(errPipe[1]);

    // Setup the dispatch queues for reading output and errors
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);
    dispatch_queue_t readQueue = dispatch_queue_create("xyz.willy.Zebra.david", DISPATCH_QUEUE_CONCURRENT);
    
    // Setup the dispatch handler for the output pipe
    dispatch_source_t outSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, outPipe[0], 0, readQueue);
    dispatch_source_set_event_handler(outSource, ^{
        char *buffer = malloc(BUFSIZ * sizeof(char));
        ssize_t bytes = read(outPipe[0], buffer, BUFSIZ);
        
        // Read from output and notify delegate
        if (bytes > 0) {
            NSString *string = [[NSString alloc] initWithBytes:buffer length:bytes encoding:NSUTF8StringEncoding];
            if (string) [self->delegate receivedData:string];
        }
        else {
            dispatch_source_cancel(outSource);
        }
        
        free(buffer);
    });
    dispatch_source_set_cancel_handler(outSource, ^{
        close(outPipe[0]);
        dispatch_semaphore_signal(lock);
    });
    
    // Setup up the dispatch handler for the error pipe
    dispatch_source_t errSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, errPipe[0], 0, readQueue);
    dispatch_source_set_event_handler(errSource, ^{
        char *buffer = malloc(BUFSIZ * sizeof(char));
        ssize_t bytes = read(errPipe[0], buffer, BUFSIZ);
    
        // Read from error and notify delegate
        if (bytes > 0) {
            NSString *string = [[NSString alloc] initWithBytes:buffer length:bytes encoding:NSUTF8StringEncoding];
            if (string) [self->delegate receivedErrorData:string];
        }
        else {
            dispatch_source_cancel(errSource);
        }
        
        free(buffer);
    });
    dispatch_source_set_cancel_handler(errSource, ^{
        close(errPipe[0]);
        dispatch_semaphore_signal(lock);
    });
    
    // Activate the dispatch sources
    dispatch_activate(outSource);
    dispatch_activate(errSource);
    
    // We need to wait twice, once for the output handler and once for the error handler
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    
    // Waits for the child process to terminate
    int status = 0;
    waitpid(pid, &status, 0);
    
    // Free our pipes
    free(outPipe);
    free(errPipe);
    
    return status;
}

@end
