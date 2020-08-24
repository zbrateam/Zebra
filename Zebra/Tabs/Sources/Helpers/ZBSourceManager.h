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
 @parameter sourceID the sourceID you want to search for
 @return A ZBSource instance with a corresponding sourceID
 */
- (ZBSource *)sourceMatchingSourceID:(int)sourceID;

/*!
 @brief Adds sources to Zebra's sources.list
 @parameter sources a set of unique sources to add to Zebra
 @parameter error an error pointer that will be set if an error occurs while adding a source
 */
- (void)addSources:(NSSet <ZBBaseSource *> *)sources error:(NSError **_Nullable)error;

/*!
 @brief Removes sources from Zebra's sources.list and database
 @parameter sources a set of unique sources to remove from Zebra
 @parameter error an error pointer that will be set if an error occurs while removing a source
 */
- (void)removeSources:(NSSet <ZBBaseSource *> *)sources error:(NSError **_Nullable)error;

/*!
 @brief Refresh all sources in Zebra's sources.list
 @parameter useCaching whether or not to use cached information that Zebra has already downloaded
 @parameter requested whether this is an automatic update or if the user requested it
 @parameter error an error pointer that will be set if an error occurs while refreshing a source
 */
- (void)refreshSourcesUsingCaching:(BOOL)useCaching userRequested:(BOOL)requested error:(NSError **_Nullable)error;
/*!
 @brief Refresh only certain sources in zebra's sources.list
 @parameter sources the sources to refresh
 @parameter error an error pointer that will be set if an error occurs while refreshing a source
*/
- (void)refreshSources:(NSSet <ZBBaseSource *> *)sources error:(NSError **_Nullable)error;

- (void)cancelSourceRefresh;

- (void)addDelegate:(id <ZBSourceDelegate>)delegate;
- (void)removeDelegate:(id <ZBSourceDelegate>)delegate;

- (BOOL)isSourceBusy:(ZBBaseSource *)source;

- (void)verifySources:(NSSet <ZBBaseSource *> *)sources delegate:(id <ZBSourceVerificationDelegate>)delegate;
@end

NS_ASSUME_NONNULL_END
