//
//  ZBBaseSource.h
//  Zebra
//
//  Created by Wilson Styres on 1/2/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBBaseSource : NSObject
@property (nonatomic) NSString *archiveType;
@property (nonatomic) NSString *repositoryURI;
@property (nonatomic) NSString *distribution;
@property (nonatomic) NSArray <NSString *> *_Nullable components;

@property (nonatomic) NSURL *packagesDirectoryURL;
@property (nonatomic) NSURL *releaseURL;

/*! @brief An identifier of a NSURLSessionDownloadTask to retrieve information about the task downloading the repository's release file */
@property NSUInteger releaseTaskIdentifier;

/*! @brief An identifier of a NSURLSessionDownloadTask to retrieve information about the task downloading the repository's package file */
@property NSUInteger packagesTaskIdentifier;

/*! @brief Indicates whether or not the task downloading the Packages file is completed and the repo should be parsed */
@property BOOL packagesTaskCompleted;

/*! @brief Indicates whether or not the task downloading the Release file is completed and the repo should be parsed */
@property BOOL releaseTaskCompleted;

/*! @brief A file path that points to the downloaded Packages file (NULL if no file has been downloaded and the database entry should not be updated) */
@property (nonatomic, strong) NSString *_Nullable packagesFilePath;

/*! @brief A file path that points to the downloaded Release file (NULL if no file has been downloaded and the database entry should not be updated) */
@property (nonatomic, strong) NSString *_Nullable releaseFilePath;

+ (NSArray <ZBBaseSource *> *)baseSourcesFromList:(NSString *)listPath error:(NSError **)error;
- (id)initWithArchiveType:(NSString *)archiveType repositoryURI:(NSString *)repositoryURI distribution:(NSString *)distribution components:(NSArray <NSString *> *)components;
- (id)initFromSourceLine:(NSString *)debLine;
@end

NS_ASSUME_NONNULL_END
