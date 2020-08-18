//
//  ZBDatabaseManager.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@class ZBPackage;
@class ZBProxyPackage;
@class ZBSource;
@class UIImage;

@import Foundation;
@import SQLite3;

#import <ZBDownloadDelegate.h>
#import "ZBDatabaseDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBDatabaseManager : NSObject <ZBDownloadDelegate>

/*! @brief A reference to the database. */
@property (atomic) sqlite3 * _Nullable database;

/*! @brief Property indicating whether or not the databaseDelegate should present the console when performing actions. */
@property (nonatomic) BOOL needsToPresentRefresh;

/*!
 @brief The database delegates
 @discussion Used to communicate with the view controllers the status of many database operations.
 */
@property (nonatomic, strong) NSMutableArray <id <ZBDatabaseDelegate>> *databaseDelegates;

/*!
 @brief The current download manager
 @discussion The current download manager used during database update.
 */
@property (nonatomic, strong) ZBDownloadManager *_Nullable downloadManager;

/*! @brief A shared instance of ZBDatabaseManager */
+ (instancetype)sharedInstance;

+ (BOOL)needsMigration;

/*!
 @brief The last time the database was updated.
 @return An NSDate that provides the last time that the database was fully updated.
 */
+ (NSDate *)lastUpdated;

#pragma mark - Opening and Closing the Database
/*!
 @brief Opens the database.
 @discussion Opens the database only if there are no current database users.
 @remark If the database is already open, nothing happens and SQLITE_OK is returned.
 @return SQLITE_OK if the database has been succesfully opened and another SQLITE error message if there was a problem.
 */
- (int)openDatabase;

/*!
 @brief Closes the database.
 @discussion Decrements the number of current users and closes the database only if there are no other database users.
 @return SQLITE_OK if the database has been succesfully closed and another SQLITE error message if there was a problem.
 */
- (int)closeDatabase;

/*!
 @brief Boolean check to see if the database is currently open.
 @return YES if the database is open, NO otherwise.
 */
- (BOOL)isDatabaseOpen;

/*!
 @brief Boolean checks whether the database is being updated.
 @return YES if the database is being updated, NO otherwise.
 */
- (BOOL)isDatabaseBeingUpdated;
- (void)setDatabaseBeingUpdated:(BOOL)updated;
- (void)setHaltDatabaseOperations:(BOOL)halt;

- (void)bulkDatabaseStartedUpdate;
- (void)bulkDatabaseCompletedUpdate:(int)updates;
- (void)bulkPostStatusUpdate:(NSString *)status atLevel:(ZBLogLevel)level;
- (void)bulkSetSource:(NSString *)bfn busy:(BOOL)busy;
- (void)cancelUpdates:(id <ZBDatabaseDelegate>)delegate;

/*!
 @brief Prints sqlite_errmsg to the log.
 */
- (void)printDatabaseError;

#pragma mark - Populating the database

/*!
 @brief Update the database.
 @discussion Updates the database from the sources contained in sources.list and from the local packages contained in /var/lib/dpkg/status
 @param useCaching Whether or not to use already downloaded package file if a 304 is returned from the server. If set to NO, all of the package files will be downloaded again,
 @param requested If YES, the user has requested this update and it should be performed. If NO, the database should only be updated if it hasn't been updated in the last 30 minutes.
 */
- (void)updateDatabaseUsingCaching:(BOOL)useCaching userRequested:(BOOL)requested;

- (void)updateSource:(ZBBaseSource *)source useCaching:(BOOL)useCaching;
- (void)updateSources:(NSSet <ZBBaseSource *> *)sources useCaching:(BOOL)useCaching;

/*!
 @brief Parses files located in the filenames dictionary.
 @discussion Updates the database from the sources contained in sources.list and from the local packages contained in /var/lib/dpkg/status
 @param sources An NSArray containing completed ZBBaseSources
 */
- (void)parseSources:(NSArray <ZBBaseSource *> *)sources;

/*!
 @brief Imports installed packages and checks for updates.
 @param checkForUpdates Whether or not to check for package updates.
 @param sender The class that is calling this method (used for databaseDelegate callbacks).
 */
- (void)importLocalPackagesAndCheckForUpdates:(BOOL)checkForUpdates sender:(id)sender;

/*!
 @brief Imports installed packages into database.
 @discussion Imports installed packages from /var/lib/dpkg/status into the database with a sourceID of 0 or -1 depending on the type of package. If a package has a tag of role::cydia it will be imported into sourceID -1 (as these packages aren't normally displayed to the user).
 */
- (void)importLocalPackages;

/*!
 @brief Checks for packages that need updates from the installed database.
 @discussion Loops through each package in -installedPackages and calls -topVersionForPackage: for each of them. If the top version is greater than the one installed, that package needs an update and then is imported into the UPDATES table.
 */
- (void)checkForPackageUpdates;

/*!
 @brief Drops all of the tables in the database.
 */
- (void)dropTables;

/*!
 @brief Add database delegate.
 @param delegate A database delegate to be added.
 */
- (void)addDatabaseDelegate:(id <ZBDatabaseDelegate>)delegate;

/*!
 @brief Remove database delegate.
 @param delegate A database delegate to be removed.
 */
- (void)removeDatabaseDelegate:(id <ZBDatabaseDelegate>)delegate;

/*!
 @brief Saves the current date and time into NSUseDefaults.
 */
- (void)updateLastUpdated;

#pragma mark - Source management

/*!
 @brief Get a sourceID from a base file name
 @param bfn The base file name.
 @return A sourceID for the matching base file name. -1 if no match was found.
 */
- (int)sourceIDFromBaseFileName:(NSString *)bfn;

/*!
@brief Get a sourceID from a base url
@param baseURL the base url
@return A sourceID for the matching base url. -1 if no match was found.
*/
- (int)sourceIDFromBaseURL:(NSString *)baseURL strict:(BOOL)strict;

/*!
@brief Get a ZBSource instance  from a base url
@param baseURL the base url
@return A ZBSource instance for the matching base url.
*/
- (ZBSource * _Nullable)sourceFromBaseURL:(NSString *)baseURL;

/*!
@brief Get a ZBSource instance  from a base filename
@param baseFilename the base filename
@return A ZBSource instance for the matching base filename
*/
- (ZBSource * _Nullable)sourceFromBaseFilename:(NSString *)baseFilename;

/*!
 @brief The next sourceID in the database.
 @return The next sourceID.
 */
- (int)nextSourceID;

/*!
 @brief The number of packages in a source.
 @param source (Nullable) The source.
 @param section (Nullable) A subsection of the source to count the number of packages in.
 @return The number of packages in that source/section.
 */
- (int)numberOfPackagesInSource:(ZBSource * _Nullable)source section:(NSString * _Nullable)section;

/*!
 @brief Overload of -numberOfPackagesInSource:section:
 @param enableFiltering Show or hide the packages with sections filtered out.
 */
- (int)numberOfPackagesInSource:(ZBSource * _Nullable)source section:(NSString * _Nullable)section enableFiltering:(BOOL)enableFiltering;

/*!
 @brief All of the sources that are in the database.
 @return An array of ZBSources that represent the sources that are in the database. It could also contain ZBBaseSources that were not able to be linked in the database (could not be downloaded)
 */
- (NSSet <ZBSource *> * _Nullable)sources;
- (NSSet <ZBSource *> * _Nullable)sourcesWithPaymentEndpoint;
- (ZBSource * _Nullable)sourceFromSourceID:(int)sourceID;

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
 @brief Get a certain number of packages from a corresponding source.
 @discussion Queries the database for packages from a source in a section. Use limit and start to specify which portion of the database you want the packages from. If no source is provided, all packages are retrieved. Will then clean up the packages (remove duplicate packages) and then return an array.
 @param source The corresponding source.
 @param section (Nullable) A specific section to get a list of packages from (NULL if you want all packages from that source).
 @param limit The number of packages that you want to grab from the database (does not correspond to the number of packages returned).
 @param start An offset from row zero in the database.
 @return A cleaned array of packages (no duplicate package IDs) from the corresponding source.
 */
- (NSArray <ZBPackage *> * _Nullable)packagesFromSource:(ZBSource * _Nullable)source inSection:(NSString * _Nullable)section numberOfPackages:(int)limit startingAt:(int)start;

/*!
 @brief Overload of -packagesFromSource:inSection:numberOfPackages:startingAt:
 @param enableFiltering Show or hide the packages with sections filtered out.
 */
- (NSArray <ZBPackage *> * _Nullable)packagesFromSource:(ZBSource * _Nullable)source inSection:(NSString * _Nullable)section numberOfPackages:(int)limit startingAt:(int)start enableFiltering:(BOOL)enableFiltering;

/*!
 @brief A list of packages that the user has installed on their device.
 @return An array of packages from sourceID 0 (installed).
 */
- (NSMutableArray <ZBPackage *> * _Nullable)installedPackages:(BOOL)includeVirtualDependencies;

/*!
 @brief A list of packages (including packages that Provide: another package
 @discussion Queries the database for installed packages. Then it runs another pass for each installed package found and queries the Provides: field. Installed packages are placed in the "installed" array of the top level dictionary while virtual packages will be placed in the "virtual" array of the top level dictionary.
 @return A dictionary whose top level keys are "installed" and "virtual". Each array will contain another dictionary with "package" and "version" (if applicable).
 */
- (NSDictionary <NSString *, NSArray <NSDictionary *> *> *)installedPackagesList;

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
 @param fullSearch Whether or not we should limit the amount of packages returned (limits to 30 if true)
 @return A cleaned array of packages (no duplicate package IDs, also could be proxy packages) that match the search term.
 */
- (NSArray * _Nullable)searchForPackageName:(NSString *)name fullSearch:(BOOL)fullSearch;

/*!
 @brief A list of authors that have a name similar to the search term.
 @param authorName The name of the author.
 @param fullSearch Whether or not we should limit the amount of authors returned (limits to 30 if true)
 @return A cleaned array of authors (no duplicates) that match the search term.
 */
- (NSArray <NSArray <NSString *> *> * _Nullable)searchForAuthorName:(NSString *)authorName fullSearch:(BOOL)fullSearch;

/*!
 @brief A list of authors names whose email exactly matches the search term
 @param authorEmail The email of the author.
 @param fullSearch Whether or not we should limit the amount of authors returned (limits to 30 if true)
 @return A cleaned array of authors (no duplicates) that match the search term.
 */
- (NSArray <NSString *> * _Nullable)searchForAuthorFromEmail:(NSString *)authorEmail fullSearch:(BOOL)fullSearch;

/*!
 @brief Get a certain number of packages from package identifiers list.
 @discussion Queries the database for packages from package identifiers list. Will then clean up the packages (remove duplicate packages) and then return an array.
 @param requestedPackages (Nullable) An array with package identifiers.
 @return A cleaned array of packages (no duplicate package IDs) from the corresponding source.
 */
- (NSArray <ZBPackage *> * _Nullable)packagesFromIdentifiers:(NSArray<NSString *> *)requestedPackages;

- (ZBPackage * _Nullable)packageFromProxy:(ZBProxyPackage *)proxy;

#pragma mark - Package status

/*!
 @brief Check whether or not a specific package has an update using its identifier.
 @param packageIdentifier The package ID that you want to check the update status for.
 @return YES if the package has an update, NO if there is no update (or if the update is hidden).
 */
- (BOOL)packageIDHasUpdate:(NSString *)packageIdentifier;

/*!
 @brief Check whether or not a specific package has an update.
 @param package A ZBPackage instance containing the package you want to check the update status for.
 @return YES if the package has an update, NO if there is no update (or if the update is hidden).
 */
- (BOOL)packageHasUpdate:(ZBPackage *)package;

/*!
 @brief Check whether or not a specific package is installed using its identifier.
 @param packageIdentifier The package ID that you want to check the installed status for.
 @param version (Nullable) The specific version you want to see if it is installed. Pass NULL if the version is irrelevant.
 @return YES if the package is installed, NO if it is not.
 */
- (BOOL)packageIDIsInstalled:(NSString *)packageIdentifier version:(NSString *_Nullable)version;

/*!
 @brief Check whether or not a specific package is installed.
 @param package A ZBPackage instance containing the package that you want to check the installed status for.
 @param strict YES if the specific version matters, NO if it does not.
 @return YES if the package is installed, NO if it is not. If strict is NO, this will indicate if the package ID is installed.
 */
- (BOOL)packageIsInstalled:(ZBPackage *)package versionStrict:(BOOL)strict;

/*!
 @brief Check whether or not a specific package is available for download from a source using its identifier.
 @param packageIdentifier The package ID that you want to check the availability status for.
 @param version (Nullable) The specific version you want to see if it is available. Pass NULL if the version is irrelevant.
 @return YES if the package is available for download, NO if it is not.
 */
- (BOOL)packageIDIsAvailable:(NSString *)packageIdentifier version:(NSString *_Nullable)version;

/*!
 @brief Check whether or not a specific package is available for download from a source.
 @param package A ZBPackage instance containing the package that you want to check the availability status for.
 @param strict YES if the specific version matters, NO if it does not.
 @return YES if the package is available for download, NO if it is not. If strict is NO, this will indicate if the package ID is available.
 */
- (BOOL)packageIsAvailable:(ZBPackage *)package versionStrict:(BOOL)strict;

/*!
 @brief Get a package with equal version from the database.
 @param identifier The package's identifier.
 @param version the version.
 @return A ZBPackage instance that satisfies the parameters.
 */
- (ZBPackage * _Nullable)packageForID:(NSString *)identifier equalVersion:(NSString *)version;

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
 @brief Removes duplicate versions from an array of packages.
 @discussion Loops through the array and compares each package to the highest version and removes every duplicate packageID that is lower than the highest version.
 @param packageList A list of packages that need to be cleaned.
 @return An array of every other version of a package in the database.
 */
- (NSArray <ZBPackage *> *)cleanUpDuplicatePackages:(NSArray <ZBPackage *> *)packageList;

/*!
 @brief Returns all packages made by the specific author.
 @param name The author's name that you wish to look for.
 @param email The author's email that you wish to look for.
 @return An array of every package made by the specified author.
 */
- (NSArray * _Nullable)packagesByAuthorName:(NSString *)name email:(NSString *_Nullable)email fullSearch:(BOOL)fullSearch;

- (NSArray * _Nullable)packagesWithDescription:(NSString *)description fullSearch:(BOOL)fullSearch;

/*!
 @brief Returns all packages with a reachable icon.
 @param limit Specify how many rows are selected.
 @return An array of all packages with a reachable icon.
 */
- (NSArray * _Nullable)packagesWithReachableIcon:(int)limit excludeFrom:(NSArray <ZBSource *> *_Nullable)blacklistedSources;

- (ZBPackage * _Nullable)localVersionForPackage:(ZBPackage *)package;
- (NSString * _Nullable)installedVersionForPackage:(ZBPackage *)package;
@end

NS_ASSUME_NONNULL_END
