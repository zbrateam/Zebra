//
//  ZBRefreshViewController.m
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#import <ZBTabBarController.h>
#import <ZBDevice.h>
#import <ZBAppDelegate.h>
#import <Database/ZBDatabaseManager.h>
#import <Downloads/ZBDownloadManager.h>
#import <ZBSourceManager.h>
#include <Parsel/parsel.h>
#import "ZBRefreshViewController.h"

typedef enum {
    ZBStateCancel = 0,
    ZBStateDone
} ZBRefreshButtonState;

@interface ZBRefreshViewController () {
    ZBDatabaseManager *databaseManager;
    BOOL hadAProblem;
    ZBRefreshButtonState buttonState;
    NSMutableArray *imaginarySources;
}
@property (strong, nonatomic) IBOutlet UIButton *completeOrCancelButton;
@property (strong, nonatomic) IBOutlet UITextView *consoleView;
@end

@implementation ZBRefreshViewController

@synthesize delegate;
@synthesize messages;
@synthesize completeOrCancelButton;
@synthesize consoleView;

#pragma mark - Initializers

- (id)init {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"refreshController"];
    
    if (self) {
        self.messages = NULL;
        self.dropTables = NO;
        self.baseSources = NULL;
    }
    
    return self;
}

- (id)initWithMessages:(NSArray *)messages {
    self = [self init];
    
    if (self) {
        self.messages = messages;
    }
    
    return self;
}

- (id)initWithDropTables:(BOOL)dropTables {
    self = [self init];
    
    if (self) {
        self.dropTables = dropTables;
    }
    
    return self;
}

- (id)initWithBaseSources:(NSSet<ZBBaseSource *> *)baseSources delegate:(id <ZBSourceVerificationDelegate>)delegate {
    self = [self init];
    
    if (self) {
        NSMutableSet *validSources = [NSMutableSet new];
        
        for (ZBBaseSource *source in baseSources) {
            if (source.verificationStatus == ZBSourceExists) {
                [validSources addObject:source];
            }
            else {
                if (!imaginarySources) imaginarySources = [NSMutableArray new];
                [imaginarySources addObject:source];
            }
        }
        
        self.baseSources = validSources;
        self.delegate = delegate;
    }
    
    return self;
}

- (id)initWithMessages:(NSArray *)messages dropTables:(BOOL)dropTables {
    self = [self init];
    
    if (self) {
        self.messages = messages;
        self.dropTables = dropTables;
    }
    
    return self;
}

- (id)initWithMessages:(NSArray *)messages baseSources:(NSSet<ZBBaseSource *> *)baseSources {
    self = [self init];
    
    if (self) {
        self.messages = messages;
        self.baseSources = baseSources;
    }
    
    return self;
}

- (id)initWithDropTables:(BOOL)dropTables baseSources:(NSSet<ZBBaseSource *> *)baseSources {
    self = [self init];
    
    if (self) {
        self.dropTables = dropTables;
        self.baseSources = baseSources;
    }
    
    return self;
}

- (id)initWithMessages:(NSArray *)messages dropTables:(BOOL)dropTables baseSources:(NSSet<ZBBaseSource *> *)baseSources {
    self = [self init];
    
    if (self) {
        self.messages = messages;
        self.dropTables = dropTables;
        self.baseSources = baseSources;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    if (_dropTables) {
        [self setCompleteOrCancelButtonHidden:YES];
    } else {
        [self updateCompleteOrCancelButtonText:NSLocalizedString(@"Cancel", @"")];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableCancelButton) name:@"disableCancelRefresh" object:nil];
    [self.view setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [consoleView setBackgroundColor:[UIColor tableViewBackgroundColor]];
}

- (void)disableCancelButton {
    buttonState = ZBStateDone;
    [self setCompleteOrCancelButtonHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.view setBackgroundColor:[UIColor tableViewBackgroundColor]];
    [consoleView setBackgroundColor:[UIColor tableViewBackgroundColor]];
    
    if (!messages) {
        databaseManager = [ZBDatabaseManager sharedInstance];
        [databaseManager addDatabaseDelegate:self];
        
        if (_dropTables) {
            [databaseManager dropTables];
        }
        
        if (self.baseSources.count) {
            // Update only the repos specified
            [databaseManager updateSources:self.baseSources useCaching:NO];
        } else {
            // Update every repo
            [databaseManager updateDatabaseUsingCaching:NO userRequested:YES];
        }
    } else {
        hadAProblem = YES;
        for (NSString *message in messages) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self writeToConsole:message atLevel:ZBLogLevelError];
            });
        }
        [consoleView setNeedsLayout];
        buttonState = ZBStateDone;
        [self clearProblems];
    }
}

- (IBAction)completeOrCancelButton:(id)sender {
    if (buttonState == ZBStateDone) {
        [self goodbye];
    }
    else {
        if (_dropTables) {
            return;
        }
        [databaseManager cancelUpdates:self];
        [((ZBTabBarController *)self.tabBarController) clearRepos];
        [self writeToConsole:@"Refresh cancelled\n" atLevel:ZBLogLevelInfo]; // TODO: localization
        
        buttonState = ZBStateDone;
        [self setCompleteOrCancelButtonHidden:NO];
        [self updateCompleteOrCancelButtonText:NSLocalizedString(@"Done", @"")];
    }
}

- (void)clearProblems {
    messages = NULL;
    hadAProblem = NO;
    [self clearConsoleText];
}

- (void)goodbye {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(goodbye) withObject:nil waitUntilDone:NO];
    } else {
        [self clearProblems];
        ZBTabBarController *controller = (ZBTabBarController *)[self presentingViewController];
        [self dismissViewControllerAnimated:YES completion:^{
            if (self->delegate) {
                [self->delegate finishedSourceVerification:NULL imaginarySources:self->imaginarySources];
            }
            else if ([controller isKindOfClass:[ZBTabBarController class]]) {
                [controller forwardToPackage]; //this is probably broken now but since this is POC ill fix later
            }
        }];
    }
}

#pragma mark - UI Updates

- (void)setCompleteOrCancelButtonHidden:(BOOL)hidden {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->completeOrCancelButton setHidden:hidden];
    });
}

- (void)updateCompleteOrCancelButtonText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.completeOrCancelButton setTitle:text forState:UIControlStateNormal];
    });
}

- (void)clearConsoleText {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->consoleView setText:nil];
    });
}

- (void)writeToConsole:(NSString *)str atLevel:(ZBLogLevel)level {
    if (str == NULL)
        return;
    if (![str hasSuffix:@"\n"])
        str = [str stringByAppendingString:@"\n"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIColor *color = [UIColor whiteColor];
        UIFont *font;
        switch (level) {
            case ZBLogLevelDescript ... ZBLogLevelInfo: {
                if ([ZBSettings interfaceStyle] < ZBInterfaceStyleDark) {
                    color = [UIColor blackColor];
                }
                font = [UIFont fontWithName:level == ZBLogLevelDescript ? @"CourierNewPSMT" : @"CourierNewPS-BoldMT" size:10.0];
                break;
            }
            case ZBLogLevelError: {
                color = [UIColor redColor];
                font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:10.0];
                break;
            }
            case ZBLogLevelWarning: {
                color = [UIColor yellowColor];
                font = [UIFont fontWithName:@"CourierNewPSMT" size:10.0];
                break;
            }
            default:
                break;

        }

        NSDictionary *attrs = @{ NSForegroundColorAttributeName: color, NSFontAttributeName: font };
        
        [self->consoleView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:attrs]];

        if (self->consoleView.text.length) {
            NSRange bottom = NSMakeRange(self->consoleView.text.length -1, 1);
            [self->consoleView scrollRangeToVisible:bottom];
        }
    });
}


#pragma mark - Database Delegate

- (void)databaseStartedUpdate {
    hadAProblem = NO;
}

- (void)databaseCompletedUpdate:(int)packageUpdates {
    ZBTabBarController *tabController = [ZBAppDelegate tabBarController];
    if (packageUpdates != -1) {
        [tabController setPackageUpdateBadgeValue:packageUpdates];
    }
    if (!hadAProblem) {
        [self goodbye];
    } else {
        [self setCompleteOrCancelButtonHidden:NO];
        [self updateCompleteOrCancelButtonText:NSLocalizedString(@"Done", @"")];
    }
    [[ZBSourceManager sharedInstance] needRecaching];
}

- (void)postStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level {
    if (level == ZBLogLevelError || level == ZBLogLevelWarning) {
        hadAProblem = YES;
    }
    [self writeToConsole:status atLevel:level];
}

@end
