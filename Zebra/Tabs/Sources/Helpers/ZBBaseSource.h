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

/*!
 @brief The archive type
 @discussion Indicates the type of archive. Deb indicates that the archive contains binary packages (deb), the pre-compiled packages that we normally use. Deb-src indicates source packages, which are the original program sources plus the Debian control file (.dsc) and the diff.gz containing the changes needed for packaging the program.
 @remark Though deb-src is an available option, Zebra does not currently support it.
 */
@property (nonatomic) NSString *archiveType;

/*! @brief URL to the repository that you want to download the packages from. */
@property (nonatomic) NSString *repositoryURI;

/*!
    @brief Repository distribution
    @discussion The 'distribution' can be either the release code name / alias or the release class respectively. Most iOS APT repositories opt to use the "Flat Repository Format" with a distribution of ./
*/
@property (nonatomic) NSString *distribution;

/*!
    @brief Components of a repository
    @remark Most iOS APT repositories opt to not have any components
 */
@property (nonatomic) NSArray <NSString *> *_Nullable components;

/*! @brief A URL generated that points to the directory where all the components for the repository should be located */
@property (nonatomic) NSURL *mainDirectoryURL;

/*! @brief A URL generated that points to the directory where all the Packages files for the repository should be located */
@property (nonatomic) NSURL *packagesDirectoryURL;

/*! @brief A URL generated that points to the directory where the Release file for the repository should be located */
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
@property (nonatomic) NSString *_Nullable packagesFilePath;

/*! @brief A file path that points to the downloaded Release file (NULL if no file has been downloaded and the database entry should not be updated) */
@property (nonatomic) NSString *_Nullable releaseFilePath;

/*! @brief The base filename of the repository, based on the URL */
@property (nonatomic) NSString *baseFilename;

@property BOOL verifying;
@property BOOL verified;

+ (NSSet <ZBBaseSource *> *)baseSourcesFromList:(NSURL *)listLocation error:(NSError **)error;
- (id)initWithArchiveType:(NSString *)archiveType repositoryURI:(NSString *)repositoryURI distribution:(NSString *)distribution components:(NSArray <NSString *> *_Nullable)components;
- (id)initFromSourceLine:(NSString *)debLine;
- (id)initFromSourceGroup:(NSString *)sourceGroup;

/*!
    @brief Verifies that a source exists in a proper format by checking for a Packages file that exists in packagesDirectoryURL
    @discussion First checks Packages.xz, then .bz2, then .gz, then .lzma, then for an uncompressed file to download
    @param completion the completion block to run once verification completes
*/
- (void)verify:(void (^)(BOOL exists))completion;
- (NSString *)debLine;
- (BOOL)canDelete;
- (BOOL)isEqual:(ZBBaseSource *)object;
@end

NS_ASSUME_NONNULL_END
