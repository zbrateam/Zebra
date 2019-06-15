//
//  ZBDatabaseManager.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@class ZBPackage;
@class ZBRepo;
@class UIImage;

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <Downloads/ZBDownloadDelegate.h>
#import <ZBDatabaseDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBDatabaseManager : NSObject <ZBDownloadDelegate>

/*! @brief A reference to the database. */
@property (atomic) sqlite3 *database;

/*! @brief Property indicating whether or not the databaseDelegate should present the console when performing actions. */
@property (nonatomic) BOOL needsToPresentRefresh;

/*!
 @brief The database delegate
 @discussion Used to communicate with the presented view controller the status of many database operations.
 */
@property (nonatomic, weak) id <ZBDatabaseDelegate> databaseDelegate;

/*! @brief A shared instance of ZBDatabaseManager */
+ (instancetype)sharedInstance;

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
 @return true if the database is open, false otherwise.
 */
- (BOOL)isDatabaseOpen;

/*!
 @brief Prints sqlite_errmsg to the log.
 */
- (void)printDatabaseError;

#pragma mark - Populating the database

/*!
 @brief Update the database.
 @discussion Updates the database from the repos contained in sources.list and from the local packages contained in /var/lib/dpkg/status
 @param useCaching Whether or not to use already downloaded package file if a 304 is returned from the server. If set to false, all of the package files will be downloaded again,
 @param requested If true, the user has requested this update and it should be performed. If false, the database should only be updated if it hasn't been updated in the last 30 minutes.
 */
- (void)updateDatabaseUsingCaching:(BOOL)useCaching userRequested:(BOOL)requested;

/*!
 @brief Parses files located in the filenames dictionary.
 @discussion Updates the database from the repos contained in sources.list and from the local packages contained in /var/lib/dpkg/status
 @param filenames An NSDictionary containing "release" and "packages" both of which are NSArrays containing the files to parse into the database.
 */
- (void)parseRepos:(NSDictionary *)filenames;

/*!
 @brief Imports installed packages and checks for updates.
 @param checkForUpdates Whether or not to check for package updates.
 @param sender The class that is calling this method (used for databaseDelegate callbacks).
 */
- (void)importLocalPackagesAndCheckForUpdates:(BOOL)checkForUpdates sender:(id)sender;

/*!
 @brief Imports installed packages into database.
 @discussion Imports installed packages from /var/lib/dpkg/status into the database with a repoID of 0 or -1 depending on the type of package. If a package has a tag of role::cydia it will be imported into repoID -1 (as these packages aren't normally displayed to the user).
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
 @brief Saves the current date and time into NSUseDefaults.
 */
- (void)updateLastUpdated;

#pragma mark - Repo management

/*!
 @brief Get a repoID from a base file name
 @param bfn The base file name.
 @return A repoID for the matching base file name. -1 if no match was found.
 */
- (int)repoIDFromBaseFileName:(NSString *)bfn;

/*!
 @brief The next repoID in the database.
 @return The next repoID.
 */
- (int)nextRepoID;

/*!
 @brief The number of packages in a repo.
 @param section (Nullable) A subsection of the repo to count the number of packages in.
 @return The number of packages in that repo/section.
 */
- (int)numberOfPackagesInRepo:(ZBRepo * _Nullable)repo section:(NSString * _Nullable)section;

/*!
 @brief All of the repos that are in the database.
 @return An array of ZBRepos that represent the repos that are in the database.
 */
- (NSArray <ZBRepo *> *)repos;

/*!
 @brief Deletes the repo and all the packages that have a matching repoID.
 @param repo The repo that needs to be deleted.
 */
- (void)deleteRepo:(ZBRepo *)repo;

/*!
 @brief The CydiaIcon for a corresponding repo (if there is one).
 @param repo The corresponding repo.
 */
- (UIImage *)iconForRepo:(ZBRepo *)repo;

/*!
 @brief Save a UIImage into the database for a corresponding repo's Cydia Icon.
 @param icon The UIImage needing to be saved.
 @param repo The corresponding repo.
 */
- (void)saveIcon:(UIImage *)icon forRepo:(ZBRepo *)repo;

/*!
 @brief A list of section names and number of packages in each section.
 @param repo The corresponding repo.
 @return A dictionary of section names and number of packages in a corresponding repo in the format <SectionName: NumberOfPackages>.
 */
- (NSDictionary *)sectionReadoutForRepo:(ZBRepo *)repo;

#pragma mark - Package retrieval

/*!
 @brief Get a certain number of packages from a corresponding repo.
 @discussion Queries the database for packages from a repo in a section. Use limit and start to specify which portion of the database you want the packages from. If no repo is provided, all packages are retrieved. Will then clean up the packages (remove duplicate packages) and then return an array.
 @param repo The corresponding repo.
 @param section (Nullable) A specific section to get a list of packages from (NULL if you want all packages from that repo).
 @param limit The number of packages that you want to grab from the database (does not correspond to the number of packages returned).
 @param start An offset from row zero in the database.
 @return A cleaned array of packages (no duplicate package IDs) from the corresponding repo.
 */
- (NSArray <ZBPackage *> *)packagesFromRepo:(ZBRepo * _Nullable)repo inSection:(NSString * _Nullable)section numberOfPackages:(int)limit startingAt:(int)start;

/*!
 @brief A list of packages that the user has installed on their device.
 @return An array of packages from repoID 0 (installed).
 */
- (NSMutableArray <ZBPackage *> *)installedPackages;

/*!
 @brief A list of packages that their updates have been ignored, installed or not.
 @return An array of packages that their updates have been ignored.
 */
- (NSMutableArray <ZBPackage *>*)packagesWithIgnoredUpdates;

/*!
 @brief A list of packages that have updates available.
 @remark Packages that have updates ignored will not be present in this array
 @return An array of packages that have updates.
 */
- (NSMutableArray <ZBPackage *>*)packagesWithUpdates;

/*!
 @brief A list of packages that have a name similar to the search term.
 @param name The name of the package.
 @param results The number of results that will be returned from the database (does not correspond to the number of packages returned).
 @return A cleaned array of packages (no duplicate package IDs) that match the search term.
 */
- (NSArray <ZBPackage *> *)searchForPackageName:(NSString *)name numberOfResults:(int)results;

/*!
 @brief Get a certain number of packages from package identifiers list.
 @discussion Queries the database for packages from package identifiers list. Will then clean up the packages (remove duplicate packages) and then return an array.
 @param requestedPackages (Nullable) An array with package identifiers.
 @return A cleaned array of packages (no duplicate package IDs) from the corresponding repo.
 */
- (NSArray <ZBPackage *> *)purchasedPackages:(NSArray<NSString *> *)requestedPackages;
#pragma mark - Package status

/*!
 @brief Check whether or not a specific package has an update using its identifier.
 @param packageIdentifier The package ID that you want to check the update status for.
 @return true if the package has an update, false if there is no update (or if the update is hidden).
 */
- (BOOL)packageIDHasUpdate:(NSString *)packageIdentifier;

/*!
 @brief Check whether or not a specific package has an update.
 @param package A ZBPackage instance containing the package you want to check the update status for.
 @return true if the package has an update, false if there is no update (or if the update is hidden).
 */
- (BOOL)packageHasUpdate:(ZBPackage *)package;

/*!
 @brief Check whether or not a specific package is installed using its identifier.
 @param packageIdentifier The package ID that you want to check the installed status for.
 @param version (Nullable) The specific version you want to see if it is installed. Pass NULL if the version is irrelevant.
 @return true if the package is installed, false if it is not.
 */
- (BOOL)packageIDIsInstalled:(NSString *)packageIdentifier version:(NSString *_Nullable)version;

/*!
 @brief Check whether or not a specific package is installed.
 @param package A ZBPackage instance containing the package that you want to check the installed status for.
 @param strict true if the specific version matters, false if it does not.
 @return true if the package is installed, false if it is not. If strict is false, this will indicate if the package ID is installed.
 */
- (BOOL)packageIsInstalled:(ZBPackage *)package versionStrict:(BOOL)strict;

/*!
 @brief Check whether or not a specific package is available for download from a repo using its identifier.
 @param packageIdentifier The package ID that you want to check the availability status for.
 @param version (Nullable) The specific version you want to see if it is available. Pass NULL if the version is irrelevant.
 @return true if the package is available for download, false if it is not.
 */
- (BOOL)packageIDIsAvailable:(NSString *)packageIdentifier version:(NSString *_Nullable)version;

/*!
 @brief Check whether or not a specific package is available for download fro ma repo.
 @param package A ZBPackage instance containing the package that you want to check the availability status for.
 @param strict true if the specific version matters, false if it does not.
 @return true if the package is available for download, false if it is not. If strict is false, this will indicate if the package ID is available.
 */
- (BOOL)packageIsAvailable:(ZBPackage *)package versionStrict:(BOOL)strict;

/*!
 @brief Get a package with equal version from the database.
 @param identifier The package's identifier.
 @param version the version.
 @return A ZBPackage instance that satisfies the parameters.
 */
- (ZBPackage *)packageForID:(NSString *)identifier equalVersion:(NSString *)version;

/*!
 @brief Check to see if the updates are ignored for a package.
 @param package The package.
 @return true if user has ignored the updates are ignored, false if otherwise
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
 @param installed Whether or not to check the installed database for this package
 @return A ZBPackage instance that matches the parameters.
 */
- (ZBPackage *)packageThatProvides:(NSString *)identifier checkInstalled:(BOOL)installed;

/*!
 @brief Mainly used in dependency resolution, this will return a ZBPackage instance that matches the parameters.
 @param identifier The identifier of the package in question.
 @param comparison (Nullable) Used for version comparison. Must be "<<", "<=", "=", ">=", or ">>". Pass NULL if no comparison needed.
 @param version (Nullable) Used for version comparison. Pass NULL if no comparison needed.
 @param installed Whether or not to check the installed database for this package
 @param provides Whether or not to check for packages that have this package identifier in the Provides: field
 @return A ZBPackage instance that matches the parameters.
 */
- (ZBPackage *)packageForID:(NSString *)identifier thatSatisfiesComparison:(NSString * _Nullable)comparison ofVersion:(NSString * _Nullable)version checkInstalled:(BOOL)installed checkProvides:(BOOL)provides;

/*!
 @brief Mainly used in dependency resolution, this will return whether or not a specific package satisfies a version comparison.
 @param package A ZBPackage instance.
 @param comparison Used for version comparison. Must be "<<", "<=", "=", ">=", or ">>".
 @param version Used for version comparison.
 @return true if the package does satisfy this version comparison, false if otherwise.
 */
- (BOOL)doesPackage:(ZBPackage *)package satisfyComparison:(NSString *)comparison ofVersion:(NSString *)version;

/*!
 @brief An array of every version of a package in the database.
 @param packageIdentifier The package you want versions for.
 @return A sorted array of every version of a package in the database.
 */
- (NSArray <ZBPackage *> *)allVersionsForPackageID:(NSString *)packageIdentifier;

/*!
 @brief An array of every version of a package in the database.
 @param package The package you want versions for.
 @return A sorted array of every version of a package in the database.
 */
- (NSArray <ZBPackage *> *)allVersionsForPackage:(ZBPackage *)package;

/*!
 @brief An array of every other version of a package in the database.
 @param packageIdentifier The package you want versions for.
 @param version The version to exclude.
 @return A sorted array of every other version of a package in the database.
 */
- (NSArray <ZBPackage *> *)otherVersionsForPackageID:(NSString *)packageIdentifier version:(NSString *)version;

/*!
 @brief An array of every other version of a package in the database.
 @param package The package you want versions for.
 @return A sorted array of every other version of a package in the database.
 */
- (NSArray <ZBPackage *> *)otherVersionsForPackage:(ZBPackage *)package;

/*!
 @brief The highest version of a package that exists in the database.
 @param package The package you want to search for.
 @return A ZBPackage instance representing the highest version in the database.
 */
- (nullable ZBPackage *)topVersionForPackage:(ZBPackage *)package;

/*!
 @brief The highest version of a package that exists in the database.
 @param packageIdentifier The package identifier you want to search for.
 @return A ZBPackage instance representing the highest version in the database.
 */
- (nullable ZBPackage *)topVersionForPackageID:(NSString *)packageIdentifier;

#pragma mark - Helper methods

/*!
 @brief Removes duplicate versions from an array of packages.
 @discussion Loops through the array and compares each package to the highest version and removes every duplicate packageID that is lower than the highest version.
 @param packageList A list of packages that need to be cleaned.
 @return An array of every other version of a package in the database.
 */
- (NSArray <ZBPackage *> *)cleanUpDuplicatePackages:(NSMutableArray <ZBPackage *> *)packageList;

@end

NS_ASSUME_NONNULL_END
