//
//  ZBDummySource.h
//  Zebra
//
//  Created by Wilson Styres on 4/15/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Delegates/ZBSourceVerificationStatus.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBDummySource : NSObject {
    NSURL *mainDirectoryURL;
    NSURL *packagesDirectoryURL;
    NSURL *releaseURL;
}
@property NSString *archiveType;
@property NSString *repositoryURI;
@property NSString *distribution;
@property NSArray <NSString *> *components;
@property NSURL *iconURL;
@property NSString *origin;
@property ZBSourceVerificationStatus verificationStatus;
- (instancetype)initWithURL:(NSURL *)URL;
@end

NS_ASSUME_NONNULL_END
