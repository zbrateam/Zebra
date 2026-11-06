// To parse this JSON:
//
//   NSError *error = NULL;
//   ZBRedditPosts *redditPosts = [ZBRedditPosts fromData:data error:&error];

#import <Foundation/Foundation.h>
#import "ZBJSONObject.h"

@class ZBRedditPost;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Object interfaces

@interface ZBRedditPosts : ZBJSONObject
@property (nonatomic, nullable, strong) NSArray <ZBRedditPost *> *data;
@end

@interface ZBRedditPost : ZBJSONObject
@property (nonatomic, nullable, strong) NSString *title;
@property (nonatomic, nullable, strong) NSString *url;
@property (nonatomic, nullable, strong) NSString *thumbnail;
@property (nonatomic, nullable, strong) NSString *tags;
@end

NS_ASSUME_NONNULL_END
