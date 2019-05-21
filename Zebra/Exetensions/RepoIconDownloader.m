//
//  RepoIconDownloader.m
//  Zebra
//
//  Created by Louis on 21/05/2019.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "RepoIconDownloader.h"
#import "ZBRepo.h"

#define kRepoIconSize 35

@interface RepoIconDownloader ()

@property (nonatomic, strong) NSURLSessionDataTask *sessionTask;

@end


#pragma mark -

@implementation RepoIconDownloader

- (void)startDownload
{
    if (self.repo.iconURL != NULL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:self.repo.iconURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f];
        _sessionTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
           if (error != nil) {
               NSLog(@"%@", request.URL.absoluteString);
               NSLog(@"%@", error);
           }
           [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
               UIImage *image = [[UIImage alloc] initWithData:data];
               if (image.size.width != kRepoIconSize || image.size.height != kRepoIconSize) {
                   CGSize itemSize = CGSizeMake(kRepoIconSize, kRepoIconSize);
                   UIGraphicsBeginImageContextWithOptions(itemSize, NO, 0.0f);
                   CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                   [image drawInRect:imageRect];
                   self.repo.iconImage = UIGraphicsGetImageFromCurrentImageContext();
                   UIGraphicsEndImageContext();
               }
               else {
                   self.repo.iconImage = image;
               }
               if (self.completionHandler != nil) {
                    self.completionHandler();
               }
            }];
        }];
        [self.sessionTask resume];
    }
}

- (void)cancelDownload
{
    [self.sessionTask cancel];
    _sessionTask = nil;
}

@end

