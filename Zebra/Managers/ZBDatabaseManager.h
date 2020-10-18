//
//  ZBDatabaseManager.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@class ZBPackage;
@class ZBProxyPackage;
@class ZBBasePackage;
@class ZBSource;
@class UIImage;

@import Foundation;
@import SQLite3;

#import <Downloads/ZBDownloadDelegate.h>
#import "ZBDatabaseDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBDatabaseManager : NSObject

@property (nonatomic, getter=isDatabaseBeingUpdated) BOOL databaseBeingUpdated;

/*!
 @brief The database delegates
 @discussion Used to communicate with the view controllers the status of many database operations.
 */
@property (nonatomic, strong) NSMutableArray <id <ZBDatabaseDelegate>> *databaseDelegates;

/*! @brief A shared instance of ZBDatabaseManager */
+ (instancetype)sharedInstance;

/*!
 @brief Whether or not the database needs to update to the new model
 @return A boolean value indicating whether or not the database should be updated to the new model
 */
+ (BOOL)needsMigration;

/*!
 @brief The last time the database was updated.
 @return An NSDate that provides the last time that the database was fully updated.
 */
+ (NSDate *)lastUpdated;

#pragma mark - Source management

- (ZBSource * _Nullable)sourceWithUniqueIdentifier:(NSString *)uuid;

/*!
 @brief All of the sources that are in the database.
 @return An array of ZBSources that represent the sources that are in the database.
 */
- (NSSet <ZBSource *> * _Nullable)sources;
- (NSSet <ZBSource *> * _Nullable)sourcesWithPaymentEndpoint;

/*!
 @brief Updates the URI for the source with the matching sourceID.
 @param source The source that needs to be updated.
 */
- (void)updateURIForSource:(ZBSource *)source;

/*!
 @brief Deletes the source and all the packages that have a matching sourceID.
 @param source The source that needs to be deleted.
 */
- (void)deleteSource:(ZBSource *)source;

- (NSArray * _Nullable)sectionReadout;

/*!
 @brief A list of section names and number of packages in each section.
 @param source The corresponding source.
 @return A dictionary of section names and number of packages in a corresponding source in the format <SectionName: NumberOfPackages>.
 */
- (NSDictionary * _Nullable)sectionReadoutForSource:(ZBSource *)source;

- (NSURL * _Nullable)paymentVendorURLForSource:(ZBSource *)source;

#pragma mark - Package retrieval

/*!
 @brief A list of packages that their updates have been ignored, installed or not.
 @return An array of packages that their updates have been ignored.
 */
- (NSMutableArray <ZBPackage *> * _Nullable)packagesWithIgnoredUpdates;

/*!
 @brief A list of packages that have updates available.
 @remark Packages that have updates ignored will not be present in this array
 @return An array of packages that have updates.
 */
- (NSMutableArray <ZBPackage *> * _Nullable)packagesWithUpdates;

/*!
 @brief A list of packages that have a name similar to the search term.
 @param name The name of the package.
 @return A cleaned array of packages (no duplicate package IDs, also could be proxy packages) that match the search term.
 */
- (NSArray * _Nullable)searchForPackageName:(NSString *)name;

/*!
 @brief A list of authors that have a name similar to the search term.
 @param authorName The name of the author.
 @return A cleaned array of authors (no duplicates) that match the search term.
 */
- (NSArray <NSArray <NSString *> *> * _Nullable)searchForAuthorByName:(NSString *)authorName;

/*!
 @brief A list of authors names whose email exactly matches the search term
 @param authorEmail The email of the author
 @return A cleaned array of authors (no duplicates) that match the search term.
 */
- (NSArray <NSString *> * _Nullable)searchForAuthorByEmail:(NSString *)authorEmail;

/*!
 @brief Get a certain number of packages from package identifiers list.
 @discussion Queries the database for packages from package identifiers list. Will then clean up the packages (remove duplicate packages) and then return an array.
 @param requestedPackages (Nullable) An array with package identifiers.
 @return A cleaned array of packages (no duplicate package IDs) from the corresponding source.
 */
- (NSArray <ZBPackage *> * _Nullable)packagesFromIdentifiers:(NSArray<NSString *> *)requestedPackages;

#pragma mark - Package status

/*!
 @brief Check whether or not a specific package is available for download from a source using its identifier.
 @param package The package ID that you want to check the availability status for.
 @param version (Nullable) The specific version you want to see if it is available. Pass NULL if the version is irrelevant.
 @return YES if the package is available for download, NO if it is not.
 */
- (BOOL)isPackageAvailable:(ZBPackage *)package checkVersion:(BOOL)checkVersion;

/*!
 @brief Check to see if the updates are ignored for a package.
 @param package The package.
 @return YES if user has ignored the updates are ignored, NO if otherwise
 */
- (BOOL)areUpdatesIgnoredForPackage:(ZBPackage *)package;

/*!
 @brief Sets the ignore colum in the UPDATES table for the corresponding package
 @param ignore whether or want the package needs to be ignored
 @param package The package.
 */
- (void)setUpdatesIgnored:(BOOL)ignore forPackage:(ZBPackage *)package;

#pragma mark - Package lookup

/*!
 @brief Mainly used in dependency resolution, this will return whether or not there is a package that provides the same functionality as the given one.
 @param identifier The identifier of the package in question.
 @return A ZBPackage instance that matches the parameters.
 */
- (ZBPackage * _Nullable)packageThatProvides:(NSString *)identifier thatSatisfiesComparison:(NSString *)comparison ofVersion:(NSString *)version thatIsNot:(ZBPackage *_Nullable)exclude;

/*!
 @brief Mainly used in dependency resolution, this will return a ZBPackage instance that matches the parameters.
 @param identifier The identifier of the package in question.
 @param comparison (Nullable) Used for version comparison. Must be "<<", "<=", "=", ">=", or ">>". Pass NULL if no comparison needed.
 @param version (Nullable) Used for version comparison. Pass NULL if no comparison needed.
 @return A ZBPackage instance that matches the parameters.
 */
- (ZBPackage * _Nullable)packageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version;

/*!
@brief Mainly used in dependency resolution, this will return an installed ZBPackage instance that matches the parameters.
@param identifier The identifier of the package in question.
@param comparison (Nullable) Used for version comparison. Must be "<<", "<=", "=", ">=", or ">>". Pass NULL if no comparison needed.
@param version (Nullable) Used for version comparison. Pass NULL if no comparison needed.
@return A ZBPackage instance that matches the parameters.
*/
- (ZBPackage * _Nullable)installedPackageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version;
- (ZBPackage * _Nullable)installedPackageForIdentifier:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version includeVirtualPackages:(BOOL)checkVirtual;

/*!
 @brief An array of every version of a package in the database.
 @param packageIdentifier The package you want versions for.
 @return A sorted array of every version of a package in the database.
 */
- (NSArray <ZBPackage *> * _Nullable)allVersionsForPackageID:(NSString *)packageIdentifier;
- (NSArray <ZBPackage *> * _Nullable)allVersionsForPackageID:(NSString *)packageIdentifier inSource:(ZBSource *_Nullable)source;

/*!
 @brief An array of every version of a package in the database.
 @param package The package you want versions for.
 @return A sorted array of every version of a package in the database.
 */
- (NSArray <ZBPackage *> * _Nullable)allVersionsForPackage:(ZBPackage *)package;
- (NSArray <ZBPackage *> * _Nullable)allVersionsForPackage:(ZBPackage *)package inSource:(ZBSource *_Nullable)source;

/*!
 @brief An array of every other version of a package in the database.
 @param packageIdentifier The package you want versions for.
 @param version The version to exclude.
 @return A sorted array of every other version of a package in the database.
 */
- (NSArray <ZBPackage *> * _Nullable)otherVersionsForPackageID:(NSString *)packageIdentifier version:(NSString *)version;

/*!
 @brief An array of every other version of a package in the database.
 @param package The package you want versions for.
 @return A sorted array of every other version of a package in the database.
 */
- (NSArray <ZBPackage *> * _Nullable)otherVersionsForPackage:(ZBPackage *)package;

/*!
 @brief The highest version of a package that exists in the database.
 @param package The package you want to search for.
 @return A ZBPackage instance representing the highest version in the database.
 */
- (nullable ZBPackage *)topVersionForPackage:(ZBPackage *)package;
- (nullable ZBPackage *)topVersionForPackage:(ZBPackage *)package inSource:(ZBSource *_Nullable)source;

/*!
 @brief The highest version of a package that exists in the database.
 @param packageIdentifier The package identifier you want to search for.
 @return A ZBPackage instance representing the highest version in the database.
 */
- (nullable ZBPackage *)topVersionForPackageID:(NSString *)packageIdentifier;
- (nullable ZBPackage *)topVersionForPackageID:(NSString *)packageIdentifier inSource:(ZBSource *_Nullable)source;

/*!
@brief Packages that depend on another package
@param package The package that you want to search for
@return An array of ZBPackage instances that contain every package that depends on the search parameter
*/
- (NSArray <ZBPackage *> * _Nullable)packagesThatDependOn:(ZBPackage *)package;

/*!
@brief Packages that conflict with another package
@param package The package that you want to search for
@return An array of ZBPackage instances that contain every package that conflicts with the search parameter
*/
- (NSArray <ZBPackage *> * _Nullable)packagesThatConflictWith:(ZBPackage *)package;

#pragma mark - Helper methods

/*!
 @brief Returns all packages made by the specific author.
 @param name The author's name that you wish to look for.
 @param email The author's email that you wish to look for.
 @return An array of every package made by the specified author.
 */
- (NSArray * _Nullable)packagesByAuthorName:(NSString *)name email:(NSString *_Nullable)email;

- (NSArray * _Nullable)packagesWithDescription:(NSString *)description;

/*!
 @brief Returns all packages with a reachable icon.
 @param limit Specify how many rows are selected.
 @return An array of all packages with a reachable icon.
 */
- (NSArray * _Nullable)packagesWithReachableIcon:(int)limit excludeFrom:(NSArray <ZBSource *> *_Nullable)blacklistedSources;

- (NSDictionary <NSString *, NSArray <NSDictionary *> *> *)installedPackagesList;

- (BOOL)packageHasUpdate:(ZBPackage *)package;

#pragma mark - New Stuff

- (NSArray <ZBBasePackage *> *)packagesMatchingFilters:(NSString *)filters;
- (NSSet *)uniqueIdentifiersForPackagesFromSource:(ZBBaseSource *)source;
- (void)deletePackagesWithUniqueIdentifiers:(NSSet *)uniqueIdentifiers;
- (void)insertPackage:(char * _Nonnull * _Nonnull)package;
- (void)insertSource:(char * _Nonnull * _Nonnull)source;
- (int)beginTransaction;
- (int)endTransaction;

/*!
 @brief Get all packages from a  source
 @param source The  source you want to retrieve packages from.
 @return A cleaned array of packages (no duplicate package IDs) from the corresponding source.
 */
- (NSArray <ZBPackage *> *)packagesFromSource:(ZBSource *)source;

/*!
 @brief Get packages from a source within a section
 @param source The source you want to retrieve packages from.
 @param section A specific section to get a list of packages from (NULL if you want all packages from that source).
 @return A cleaned array of packages (no duplicate package IDs) from the corresponding source.
 */
- (NSArray <ZBPackage *> *)packagesFromSource:(ZBSource *)source inSection:(NSString * _Nullable)section;

- (ZBPackage *)packageWithUniqueIdentifier:(NSString *)uuid;
- (ZBBasePackage *)installedInstanceOfPackage:(ZBPackage *)package;
- (NSString *)installedVersionOfPackage:(ZBPackage *)package;
- (NSDictionary *)packageListFromSource:(ZBSource *)source;

@end

NS_ASSUME_NONNULL_END
