//
//  RepoIconDownloader.h
//  Zebra
//
//  Created by Louis on 21/05/2019.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBRepo.h"

@class ZBRepo;

@interface RepoIconDownloader : NSObject

@property (nonatomic, strong) ZBRepo *repo;
@property (nonatomic, copy) void (^completionHandler)(void);

- (void)startDownload;
- (void)cancelDownload;

@end
