//
//  ZBCommand.m
//  Zebra
//
//  Created by Wilson Styres on 9/9/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBCommand.h"
#import "ZBDevice.h"
#import "spawn.h"

typedef struct ZBCommandFds {
    int stdOut[2];
    int stdErr[2];
    int finish[2];
} ZBCommandFds;

static const int ZBCommandFinishFileno = 3;

@implementation ZBCommand {
    id <ZBCommandDelegate> delegate;
    ZBCommandFds *fds;
}

+ (NSString *)execute:(NSString *)command withArguments:(NSArray <NSString *> *_Nullable)arguments asRoot:(BOOL)root {
    // As this method is intended for convenience, the arguments array isn’t expected to have the
    // first argument, which is typically the path or name of the binary being invoked. Add it now.
    arguments = [@[command] arrayByAddingObjectsFromArray:arguments ?: @[]];
    ZBCommand *task = [[ZBCommand alloc] initWithCommand:command arguments:arguments root:root delegate:nil];
    task.output = [NSMutableString new];
    return [task execute] == 0 ? task.output : nil;
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
        _command = command;
        _arguments = arguments;
        self.asRoot = root;
    }

    return self;
}

- (void)setAsRoot:(BOOL)asRoot {
    if (@available(iOS 13, *)) {
        // Nothing special to do here
    } else {
        NSMutableArray <NSString *> *mutableArguments = [_arguments mutableCopy] ?: [NSMutableArray array];
        if (_asRoot && !asRoot && mutableArguments.count > 0) {
            // If we're set to run as root but we no longer want to, remove the original command from the arguments array and set it back to self.command
            _command = mutableArguments[0];
            _arguments = mutableArguments;
        } else if (!_asRoot && asRoot) {
            // If we're not set to run as root but we want to, set supersling as the command and duplicate the original command into the arguments array
            [mutableArguments insertObject:_command atIndex:0];
            _arguments = mutableArguments;
            _command = @INSTALL_PREFIX @"/usr/libexec/zebra/supersling";
        }

        if (!_asRoot && !asRoot && (!mutableArguments.count || ![mutableArguments[0] isEqualToString:_command])) { // If we're not set as root and we don't want to, we need to make sure the first arugment in the array is the binary we want to run
            [mutableArguments insertObject:_command atIndex:0];
            _arguments = mutableArguments;
        }
    }

    _asRoot = asRoot;
}

- (void)setUseFinishFd:(BOOL)useFinishFd {
    _useFinishFd = useFinishFd;

    NSUInteger binaryIndex = _asRoot ? 1 : 0;
    if (@available(iOS 13, *)) {
        binaryIndex = 0;
    }

    if (_arguments.count > binaryIndex) {
        NSString *binary = _arguments[binaryIndex];
        if ([binary isEqualToString:@"apt"]) {
            // We need to insert this flag to ensure our fd is passed through to dpkg.
            NSMutableArray <NSString *> *mutableArguments = [_arguments mutableCopy] ?: [NSMutableArray array];
            NSString *flag = [NSString stringWithFormat:@"-oAPT::Keep-Fds::=%d", ZBCommandFinishFileno];
            if (_useFinishFd) {
                [mutableArguments insertObject:flag atIndex:MIN(binaryIndex + 1, mutableArguments.count)];
            } else {
                [mutableArguments removeObject:flag];
            }
            _arguments = mutableArguments;
        }
    }
}

- (int)execute {
    // Create output and error pipes
    fds = malloc(sizeof(ZBCommandFds));
    if (pipe(fds->stdOut) == -1 || pipe(fds->stdErr) == -1) {
        free(fds);
        return errno; // pipe() sets errno on failure
    }

    if (_useFinishFd) {
        if (pipe(fds->finish) == -1) {
            free(fds);
            return errno; // pipe() sets errno on failure
        }
    }

    // Convert our arguments array from NSStrings to char pointers
    char **argv = (char **)malloc((_arguments.count + 1) * sizeof(char *));
    for (int i = 0; i < _arguments.count; i++) {
        argv[i] = strdup(_arguments[i].UTF8String);
    }
    argv[_arguments.count] = NULL;

    // Construct environment vars
    NSMutableArray <NSString *> *environmentVars = [NSMutableArray array];
    [environmentVars addObject:[NSString stringWithFormat:@"PATH=%@", [ZBDevice path]]];
    if (_useFinishFd) {
        // $CYDIA enables maintenance scripts to send “finish” messages to the package manager.
        // Contains two integers. First is the fd to write to, second is the API version
        // (currently 1).
        [environmentVars addObject:[NSString stringWithFormat:@"CYDIA=%d 1", ZBCommandFinishFileno]];
    }

    // Convert our environment array from NSStrings to char pointers
    char **envp = (char **)malloc((environmentVars.count + 1) * sizeof(char *));
    for (int i = 0; i < environmentVars.count; i++) {
        envp[i] = strdup(environmentVars[i].UTF8String);
    }
    envp[environmentVars.count] = NULL;

    // Create our file actions to read data back from posix_spawn
    posix_spawn_file_actions_t child_fd_actions;
    posix_spawn_file_actions_init(&child_fd_actions);
    posix_spawn_file_actions_addclose(&child_fd_actions, fds->stdOut[0]);
    posix_spawn_file_actions_addclose(&child_fd_actions, fds->stdErr[0]);
    posix_spawn_file_actions_adddup2(&child_fd_actions, fds->stdOut[1], STDOUT_FILENO);
    posix_spawn_file_actions_adddup2(&child_fd_actions, fds->stdErr[1], STDERR_FILENO);
    posix_spawn_file_actions_addclose(&child_fd_actions, fds->stdOut[1]);
    posix_spawn_file_actions_addclose(&child_fd_actions, fds->stdErr[1]);

    if (_useFinishFd) {
        posix_spawn_file_actions_addclose(&child_fd_actions, fds->finish[0]);
        posix_spawn_file_actions_adddup2(&child_fd_actions, fds->finish[1], ZBCommandFinishFileno);
        posix_spawn_file_actions_addclose(&child_fd_actions, fds->finish[1]);
    }

    // Create persona config if needed
    posix_spawnattr_t child_fd_attrs;
    posix_spawnattr_init(&child_fd_attrs);

    if (@available(iOS 13, *)) {
        if (_asRoot) {
            posix_spawnattr_set_persona_np(&child_fd_attrs, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
            posix_spawnattr_set_persona_uid_np(&child_fd_attrs, 0);
            posix_spawnattr_set_persona_gid_np(&child_fd_attrs, 0);
        }
    }

    // Setup the dispatch queues for reading output and errors
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);
    dispatch_queue_t readQueue = dispatch_queue_create("xyz.willy.Zebra.david", DISPATCH_QUEUE_CONCURRENT);

    // Setup the dispatch handler for the output pipes
    dispatch_source_t stdOutSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fds->stdOut[0], 0, readQueue);
    dispatch_source_t stdErrSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fds->stdErr[0], 0, readQueue);
    dispatch_source_t finishSource = nil;

    if (_useFinishFd) {
        finishSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fds->finish[0], 0, readQueue);
    }

    void (^handleSourceEvent)(dispatch_source_t, int, void (^)(NSString *)) = ^(dispatch_source_t source, int fd, void (^action)(NSString *)) {
        char *buffer = (char *)malloc(BUFSIZ * sizeof(char));
        size_t bytes = read(fd, buffer, BUFSIZ);

        if (bytes > 0) {
            // Read from output and notify delegate
            NSString *string = [[NSString alloc] initWithBytes:buffer length:bytes encoding:NSUTF8StringEncoding];
            if (string) {
                action(string);
            }
        }
        else {
            // The fd was closed; cancel the dispatch_source.
            dispatch_source_cancel(source);
        }

        free(buffer);
    };

    dispatch_source_set_event_handler(stdOutSource, ^{
        handleSourceEvent(stdOutSource, self->fds->stdOut[0], ^(NSString *string) {
            if (self->delegate) [self->delegate receivedData:string];
            if (self.output) [self.output appendString:string];
        });
    });
    dispatch_source_set_event_handler(stdErrSource, ^{
        handleSourceEvent(stdErrSource, self->fds->stdErr[0], ^(NSString *string) {
            if (self->delegate) [self->delegate receivedErrorData:string];
            if (self.output) [self.output appendString:string];
        });
    });

    dispatch_source_set_cancel_handler(stdOutSource, ^{
        close(self->fds->stdOut[0]);
        dispatch_semaphore_signal(lock);
    });
    dispatch_source_set_cancel_handler(stdErrSource, ^{
        close(self->fds->stdErr[0]);
        dispatch_semaphore_signal(lock);
    });

    if (_useFinishFd) {
        dispatch_source_set_event_handler(finishSource, ^{
            handleSourceEvent(finishSource, self->fds->finish[0], ^(NSString *string) {
                if (self->delegate) [self->delegate receivedFinishData:string];
            });
        });
        dispatch_source_set_cancel_handler(finishSource, ^{
            // Finish fd isn’t expected to be closed, so no semaphore involved here.
            close(self->fds->finish[0]);
        });
    }


    // Activate the dispatch sources
    dispatch_resume(stdOutSource);
    dispatch_resume(stdErrSource);

    if (_useFinishFd) {
        dispatch_resume(finishSource);
    }

    // Spawn the child process
    pid_t pid = 0;
    int ret = posix_spawnp(&pid, _command.UTF8String, &child_fd_actions, &child_fd_attrs, argv, envp);
    free(argv);
    free(envp);
    if (ret < 0) {
        close(fds->stdOut[0]);
        close(fds->stdOut[1]);
        close(fds->stdErr[0]);
        close(fds->stdErr[1]);
        if (_useFinishFd) {
            close(fds->finish[0]);
            close(fds->finish[1]);
        }
        return ret;
    }

    // Close the write ends of the pipes so no odd data comes through them
    close(fds->stdOut[1]);
    close(fds->stdErr[1]);

    // We need to wait twice, once for the output handler and once for the error handler
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);

    // Waits for the child process to terminate
    int status = 0;
    waitpid(pid, &status, 0);

    // The finish fd is unlikely to have closed on its own, so close it now.
    if (_useFinishFd && !dispatch_source_testcancel(finishSource)) {
        dispatch_source_cancel(finishSource);
    }

    // Free our pipes
    free(fds);

    // Get the true status code, if the process exited normally. If it died for some other reason,
    // we return the actual value we got back from waitpid(3), which should still be useful for
    // debugging what went wrong.
    if (WIFSIGNALED(status)) {
        return 128 + WTERMSIG(status);
    } else if (WIFEXITED(status)) {
        return WEXITSTATUS(status);
    }
    return status;
}

@end
