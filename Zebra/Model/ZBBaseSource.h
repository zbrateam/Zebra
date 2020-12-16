//
//  ZBBaseSource.h
//  Zebra
//
//  Created by Wilson Styres on 1/2/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Tabs/Sources/Helpers/ZBSourceVerificationStatus.h>

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ZBSourceErrorDomain;

typedef enum : NSUInteger {
    ZBSourceErrorUnknown = -1,
    ZBSourceWarningInsecure = 1000,
    ZBSourceWarningIncompatible = 1001,
} ZBSourceError;

typedef NS_ENUM(NSUInteger, ZBSourceColumn) {
    ZBSourceColumnArchitectures,
    ZBSourceColumnArchiveType,
    ZBSourceColumnCodename,
    ZBSourceColumnComponents,
    ZBSourceColumnDistribution,
    ZBSourceColumnLabel,
    ZBSourceColumnOrigin,
    ZBSourceColumnPaymentEndpoint,
    ZBSourceColumnRemote,
    ZBSourceColumnDescription,
    ZBSourceColumnSuite,
    ZBSourceColumnSupportsFeaturedPackages,
    ZBSourceColumnURL,
    ZBSourceColumnUUID,
    ZBSourceColumnVersion,
    ZBSourceColumnCount,
};

typedef char *_Nonnull *_Nonnull ZBControlSource;

@interface ZBBaseSource : NSObject

@property (readonly) BOOL remote;

/*!
 @brief The archive type
 @discussion Indicates the type of archive. Deb indicates that the archive contains binary packages (deb), the pre-compiled packages that we normally use. Deb-src indicates source packages, which are the original program sources plus the Debian control file (.dsc) and the diff.gz containing the changes needed for packaging the program.
 @remark Though deb-src is an available option, Zebra does not currently support it.
 */
@property (readonly) NSString *archiveType;

/*! @brief URL to the repository that you want to download the packages from. */
@property (readonly) NSString *repositoryURI;

/*!
    @brief Repository distribution
    @discussion The 'distribution' can be either the release code name / alias or the release class respectively. Most iOS APT repositories opt to use the "Flat Repository Format" with a distribution of ./
*/
@property (readonly) NSString *distribution;

/*!
    @brief Components of a repository
    @remark Most iOS APT repositories opt to not have any components
 */
@property (readonly) NSArray <NSString *> *_Nullable components;

/*! @brief A URL generated that points to the directory where all the components for the repository should be located */
@property (readonly) NSURL *mainDirectoryURL;

/*! @brief A URL generated that points to the directory where all the Packages files for the repository should be located */
@property (readonly) NSURL *packagesDirectoryURL;

/*! @brief A URL generated that points to the directory where the Release file for the repository should be located */
@property (readonly) NSURL *releaseURL;

/*! @brief An identifier of a NSURLSessionDownloadTask to retrieve information about the task downloading the repository's release file */
@property NSUInteger releaseTaskIdentifier;

/*! @brief An identifier of a NSURLSessionDownloadTask to retrieve information about the task downloading the repository's package file */
@property NSUInteger packagesTaskIdentifier;

/*! @brief Indicates whether or not the task downloading the Packages file is completed and the repo should be parsed */
@property BOOL packagesTaskCompleted;

/*! @brief Indicates whether or not the task downloading the Release file is completed and the repo should be parsed */
@property unsigned int releaseTasksCompleted;

/*! @brief A file path that points to the downloaded Packages file (NULL if no file has been downloaded and the database entry should not be updated) */
@property NSString *_Nullable packagesFilePath;

/*! @brief A file path that points to the downloaded Release file (NULL if no file has been downloaded and the database entry should not be updated) */
@property NSString *_Nullable releaseFilePath;

@property (nullable) NSURL *paymentEndpointURL;

@property BOOL supportsFeaturedPackages;

@property NSString *_Nullable featuredPackages;

/*! @brief The base filename of the repository, based on the URL */
@property (readonly) NSString * _Nullable uuid;

/*! @brief The verification status of the source */
@property ZBSourceVerificationStatus verificationStatus;

/*! @brief the source's origin if one has been retrieved */
@property NSString *origin;

/*! @brief the source's label if one has been retrieved */
@property NSString *label;

/*! @brief the source's icon URL*/
@property (readonly) NSURL *iconURL;

/*! @brief warnings (issues that could arise) that might have occured when downloading or parsing the source */
@property (nonatomic) NSArray * _Nullable warnings;

/*! @brief errors (indicating a failure) that might have occured when downloading or parsing the source */
@property (nonatomic) NSArray * _Nullable errors;

+ (NSSet <ZBBaseSource *> *)baseSourcesFromURLs:(NSArray *)URLs;
+ (NSSet <ZBBaseSource *> *)baseSourcesFromList:(NSURL *)listLocation error:(NSError **)error;
- (id)initWithArchiveType:(NSString *)archiveType repositoryURI:(NSString *)repositoryURI distribution:(NSString *)distribution components:(NSArray <NSString *> *_Nullable)components; 
- (id)initFromSourceLine:(NSString *)debLine;
- (id)initFromSourceGroup:(NSString *)sourceGroup;
- (id)initFromURL:(NSURL *)url;

/*!
    @brief Verifies that a source exists in a proper format by checking for a Packages file that exists in packagesDirectoryURL
    @discussion First checks Packages.xz, then .bz2, then .gz, then .lzma, then for an uncompressed file to download
    @param completion the completion block to run once verification completes
*/
- (void)verify:(nullable void (^)(ZBSourceVerificationStatus status))completion;
- (void)getLabel:(void (^)(NSString *label))completion;
- (NSString *)debLine;
- (BOOL)canDelete;
- (BOOL)isEqual:(ZBBaseSource *)object;
- (BOOL)exists;
- (NSArray <NSString *> *)lists;
- (NSUInteger)numberOfPackages;
@end

NS_ASSUME_NONNULL_END
