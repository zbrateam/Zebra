//
//  RepoIconDownloader.h
//  Zebra
//
//  Created by Louis on 21/05/2019.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackage.h"

@class ZBPackage;

@interface PackageIconDownloader : NSObject

@property (nonatomic, strong) ZBPackage *package;
@property (nonatomic, copy) void (^completionHandler)(void);

- (void)startDownload;
- (void)cancelDownload;

@end
