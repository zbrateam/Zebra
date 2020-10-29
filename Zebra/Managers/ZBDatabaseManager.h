//
//  ZBDatabaseManager.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

@class ZBBasePackage;
@class ZBPackage;
@class ZBBaseSource;
@class ZBSource;
@class UIImage;

@import Foundation;
@import SQLite3;

NS_ASSUME_NONNULL_BEGIN

@interface ZBDatabaseManager : NSObject

/*! @brief A shared instance of ZBDatabaseManager */
+ (instancetype)sharedInstance;

#pragma mark - Managing Transactions

- (void)performTransaction:(void (^)(void))transaction;

#pragma mark - Package Retrieval

/*!
 @brief Get an instance of all packages that belong to a source.
 @discussion This array is full of ZBBasePackage instances, a ZBBasePackage instance will forward unknown selectors to a ZBPackage instance using -packageWithUniqueIdentifier: so either class behaves the same.
 @param source The source you want to retrieve packages from.
 @return An array of instances that represent the highest version available from a source for each package.
 */
- (NSArray <ZBPackage *> *)packagesFromSource:(ZBSource *)source;

/*!
 @brief Get an instance of all packages that belong to a source within a specific section.
 @discussion This array is full of ZBBasePackage instances, a ZBBasePackage instance will forward unknown selectors to a ZBPackage instance using -packageWithUniqueIdentifier: so either class behaves the same.
 @param source The source you want to retrieve packages from.
 @param section The section that you would like to filter packages from.
 @return An array of instances that represent the highest version available from a source within a section for each package.
 */
- (NSArray <ZBPackage *> *)packagesFromSource:(ZBSource *)source inSection:(NSString * _Nullable)section;

/*!
 @brief Get an instance of a package with a specific unique identifier.
 @param uuid The uuid you want to lookup.
 @discussion This method is used when forwarding unknown selectors from a ZBBasePackage instance to a ZBPackage instance.
 @return An instance of ZBPackage that has a UUID equal to the UUID specified.
 */
- (ZBPackage *_Nullable)packageWithUniqueIdentifier:(NSString *)uuid;

/*!
 @brief A list of packages that have updates available.
 @remark Packages that have updates ignored will not be present in this array
 @return An array of packages that have updates.
 */
- (NSArray <ZBPackage *> * _Nullable)packagesWithUpdates;

/*!
 @brief Get the instance of the package that is installed to the user's device
 @param package The package that you want an installed instance of.
 @return An instance of ZBPackage that is installed to the user's device.
 */
- (ZBPackage *)installedInstanceOfPackage:(ZBPackage *)package;

/*!
 @brief Get instances of packages by an author
 @discussion This array is full of ZBBasePackage instances, a ZBBasePackage instance will forward unknown selectors to a ZBPackage instance using -packageWithUniqueIdentifier: so either class behaves the same.
 @param name The author's name.
 @param email The author's email (optional).
 @return An array of instances that are created by the author
 */
- (NSArray <ZBPackage *> *)packagesByAuthorWithName:(NSString *)name email:(NSString *_Nullable)email;

- (NSArray * _Nullable)packagesWithReachableIcon:(int)limit excludeFrom:(NSArray <ZBSource *> *_Nullable)blacklistedSources;

#pragma mark - Package Information

/*!
 @brief Get the version string of the package that is installed to the user's device.
 @param package The package that you want an installed version string of.
 @return A NSString representing the version of the package installed to the user's device.
 */
- (NSString *)installedVersionOfPackage:(ZBPackage *)package;

/*!
 @brief All version strings that are available for a package
 @param package The package that you want versions for.
 @return An array of all version strings in all sources available in the database for a package.
 */
- (NSArray <NSString *> *)allVersionsForPackage:(ZBPackage *)package;

/*!
 @brief All version strings that are available for a package
 @param package The package that you want versions for.
 @param source The source you want as a filter.
 @return An array of all version strings in a source available in the database for a package.
 */
- (NSArray <NSString *> *)allVersionsForPackage:(ZBPackage *)package inSource:(ZBSource *_Nullable)source;

#pragma mark - Package Searching

- (void)searchForPackagesByName:(NSString *)name completion:(void (^)(NSArray <ZBPackage *> *packages))completion;
- (void)searchForPackagesByDescription:(NSString *)description completion:(void (^)(NSArray <ZBPackage *> *packages))completion;
- (void)searchForPackagesByAuthorWithName:(NSString *)name completion:(void (^)(NSArray <ZBPackage *> *packages))completion;

#pragma mark - Source Retrieval

/*!
 @brief All of the sources that are in the database.
 @return A set of ZBSource instances that represent the sources that are in the database. This does *not* include sources that are in sources.list
 */
- (NSSet <ZBSource *> *)sources;

/*!
 @brief All of the sources that are in the database that have a payment endpoint and can use the modern payment API.
 @return A set of ZBSource instances that are able to use the modern payment API.
 */
- (NSSet <ZBSource *> *)sourcesWithPaymentEndpoint;

#pragma mark - Source Information

/*!
 @brief A simplified list of packages that are available from a source.
 @param source The source that you would like to retrieve a package list from.
 @return A dictionary keyed by package identifiers that contains the highest version for each package identifier in a source
 */
- (NSDictionary *)packageListFromSource:(ZBSource *)source;

/*!
 @brief Unique identifiers for all packages from a source
 @param source The source that you would like to retrieve a list of unique identifiers from.
 @return A set of unique identifiers representing all the packages available from a source.
 */
- (NSSet *)uniqueIdentifiersForPackagesFromSource:(ZBBaseSource *)source;

- (NSUInteger)numberOfPackagesInSource:(ZBSource *)source;

- (NSDictionary *)sectionReadoutForSource:(ZBSource *)source;

#pragma mark - Package Management

- (void)insertPackage:(char * _Nonnull * _Nonnull)package;

- (void)deletePackagesWithUniqueIdentifiers:(NSSet *)uniqueIdentifiers;

#pragma mark - Source Management

- (void)insertSource:(char * _Nonnull * _Nonnull)source;

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

#pragma mark - Package retrieval

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

#pragma mark - Dependency Resolution

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

@end

NS_ASSUME_NONNULL_END
