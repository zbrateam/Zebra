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

+ (NSString *)execute:(NSString *)command withArguments:(NSArray <NSString *> *_Nullable)arguments asRoot:(BOOL)root {
    ZBCommand *task = [[ZBCommand alloc] init];
    task.command = command;
    task.arguments = arguments;
    task.asRoot = root;
    task.output = [NSMutableString new];
    
    [task execute];
    return task.output;
}

- (id)initWithDelegate:(id <ZBCommandDelegate>)delegate {
    self = [super init];
    
    if (self) {
        if (delegate) self->delegate = delegate;
    }
    
    return self;
}

- (id)initWithCommand:(NSString *)command arguments:(NSArray <NSString *> *_Nullable)arguments root:(BOOL)root delegate:(id <ZBCommandDelegate>)delegate {
    self = [self initWithDelegate:delegate];
    
    if (self) {
        self.command = command;
        self.arguments = arguments;
        self.asRoot = root;
    }
    
    return self;
}

- (void)setAsRoot:(BOOL)asRoot {
    NSMutableArray *mutableArguments = self.arguments ? [self.arguments mutableCopy] : [NSMutableArray new];
    if (_asRoot && !asRoot && mutableArguments.count > 0) { // If we're set to run as root but we no longer want to, remove the original command from the arguments array and set it back to self.command
        self.command = mutableArguments[0];
        self.arguments = mutableArguments;
        
        _asRoot = asRoot;
    }
    else if (!_asRoot && asRoot) { // If we're not set to run as root but we want to, set supersling as the command and duplicate the original command into the arguments array
        [mutableArguments insertObject:self.command atIndex:0];
        self.arguments = mutableArguments;
        self.command = @"/usr/libexec/zebra/supersling";
        
        _asRoot = asRoot;
    }
    
    if (!_asRoot && !asRoot && (!mutableArguments.count || ![[mutableArguments objectAtIndex:0] isEqual:self.command])) { // If we're not set as root and we don't want to, we need to make sure the first arugment in the array is the binary we want to run
        [mutableArguments insertObject:self.command atIndex:0];
        self.arguments = mutableArguments;
    }
}

- (int)execute {
    // Allocate space for arguments array
    NSUInteger argc = [self.arguments count];
    char **argv = (char **)malloc((argc + 1) * sizeof(char*));
    
    // Convert our arguments array from NSStrings to char pointers
    for (int i = 0; i < argc; i++) {
        argv[i] = strdup(self.arguments[i].UTF8String);
    }
    argv[argc] = NULL;
    
    // Create output and error pipes
    int *outPipe = malloc(sizeof(int) * 2);
    int *errPipe = malloc(sizeof(int) * 2);
    if (pipe(outPipe) == -1 || pipe(errPipe) == -1) {
        free(outPipe);
        free(errPipe);
        return errno; // pipe() sets errno on failure
    }
    
    // Create our file actions to read data back from posix_spawn
    posix_spawn_file_actions_t child_fd_actions;
    posix_spawn_file_actions_init(&child_fd_actions);
    posix_spawn_file_actions_addclose(&child_fd_actions, outPipe[0]);
    posix_spawn_file_actions_addclose(&child_fd_actions, errPipe[0]);
    posix_spawn_file_actions_adddup2(&child_fd_actions, outPipe[1], STDOUT_FILENO);
    posix_spawn_file_actions_adddup2(&child_fd_actions, errPipe[1], STDERR_FILENO);
    posix_spawn_file_actions_addclose(&child_fd_actions, outPipe[1]);
    posix_spawn_file_actions_addclose(&child_fd_actions, errPipe[1]);

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
            if (string) {
                if (self->delegate) [self->delegate receivedData:string];
                if (self.output) [self.output appendString:string];
            }
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
            if (string) {
                if (self->delegate) [self->delegate receivedErrorData:string];
                if (self.output) [self.output appendString:string];
            }
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
    
    // Spawn the child process
    pid_t pid = 0;
    int ret = posix_spawnp(&pid, self.command.UTF8String, &child_fd_actions, nil, argv, environ);
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
