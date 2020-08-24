//
//  ZBSourceManager.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@class ZBSource;
@class ZBBaseSource;

#import "ZBSourceVerificationDelegate.h"
#import "ZBSourceDelegate.h"
#import <Database/ZBDatabaseDelegate.h>
#import <Downloads/ZBDownloadDelegate.h>

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface ZBSourceManager : NSObject <ZBDatabaseDelegate, ZBDownloadDelegate>

/*! @brief An array of source objects, from the database and sources.list (if the source is not loaded), that Zebra keeps track of */
@property (readonly) NSArray <ZBSource *> *sources;

@property (readonly, getter=isRefreshInProgress) BOOL refreshInProgress;

/*! @brief A shared instance of ZBSourceManager */
+ (id)sharedInstance;

/*!
 @brief Obtain a ZBSource instance from the database that matches a certain sourceID
 @param sourceID the sourceID you want to search for
 @return A ZBSource instance with a corresponding sourceID
 */
- (ZBSource *)sourceMatchingSourceID:(int)sourceID;

/*!
 @brief Adds sources to Zebra's sources.list
 @param sources a set of unique sources to add to Zebra
 @param error an error pointer that will be set if an error occurs while adding a source
 */
- (void)addSources:(NSSet <ZBBaseSource *> *)sources error:(NSError **_Nullable)error;

/*!
 @brief Removes sources from Zebra's sources.list and database
 @param sources a set of unique sources to remove from Zebra
 @param error an error pointer that will be set if an error occurs while removing a source
 */
- (void)removeSources:(NSSet <ZBBaseSource *> *)sources error:(NSError **_Nullable)error;

/*!
 @brief Update Zebra's sources.
 @discussion Updates the database from the sources contained in sources.list and from the local packages contained in /var/lib/dpkg/status
 @param useCaching Whether or not to use already downloaded package file if a 304 is returned from the server. If set to NO, all of the package files will be downloaded again,
 @param requested If YES, the user has requested this update and it should be performed. If NO, the database should only be updated if it hasn't been updated in the last 30 minutes.
 */
- (void)refreshSourcesUsingCaching:(BOOL)useCaching userRequested:(BOOL)requested error:(NSError **_Nullable)error;
/*!
 @brief Refresh only certain sources in zebra's sources.list
 @param sources the sources to refresh
 @param useCaching Whether or not to use already downloaded package file if a 304 is returned from the server. If set to NO, all of the package files will be downloaded again,
 @param error an error pointer that will be set if an error occurs while refreshing a source
*/
- (void)refreshSources:(NSSet <ZBBaseSource *> *)sources useCaching:(BOOL)useCaching error:(NSError **_Nullable)error;

- (void)cancelSourceRefresh;

- (void)addDelegate:(id <ZBSourceDelegate>)delegate;
- (void)removeDelegate:(id <ZBSourceDelegate>)delegate;

- (BOOL)isSourceBusy:(ZBBaseSource *)source;

- (void)verifySources:(NSSet <ZBBaseSource *> *)sources delegate:(id <ZBSourceVerificationDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
