//
//  ZBDummySource.h
//  Zebra
//
//  Created by Wilson Styres on 4/15/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ZBSourceVerificationStatus) {
    ZBSourceVerifying,  //Currently verifying
    ZBSourceExists,     //Exists
    ZBSourceImaginary,  //Doesn't exist
    ZBSourceUnverified  //Not yet verified
};

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
@property NSString *UUID;
@property ZBSourceVerificationStatus verificationStatus;
+ (NSSet <ZBDummySource *> *)baseSourcesFromURLs:(NSArray *)URLs;
+ (NSSet <ZBDummySource *> *)baseSourcesFromList:(NSURL *)listLocation error:(NSError **_Nullable)error;
- (instancetype)initWithURL:(NSURL *)URL;
- (void)verify:(nullable void (^)(ZBSourceVerificationStatus status))completion;
- (void)getOrigin:(void (^)(NSString *label))completion;
@end

NS_ASSUME_NONNULL_END
