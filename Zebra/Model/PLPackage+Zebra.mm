//
//  PLPackage+Zebra.m
//  Zebra
//
//  Created by Wilson Styres on 4/4/21.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "PLPackage+Zebra.h"

#import <Model/PLSource+Zebra.h>
#import <Tabs/Packages/Helpers/ZBPackageActions.h>

#import <SDWebImage/SDWebImage.h>
#import <Plains/Utilities/NSString+Plains.h>

@implementation PLPackage (Zebra)

- (BOOL)mightRequirePayment {
    return NO;
}

- (ZBPackageActionType)possibleActions {
    ZBPackageActionType action = 0;
    
    BOOL installed = self.installed;
    if (self.source) {
        if (installed) {
            action |= ZBPackageActionReinstall;
            if (self.hasUpdate) {
                action |= ZBPackageActionUpgrade;
            }
            if (self.lesserVersions.count > 1) {
                action |= ZBPackageActionDowngrade;
            }
        } else {
            action |= ZBPackageActionInstall;
        }
    }
    
    if (installed) {
        action |= ZBPackageActionRemove;
    }
    
    return action;
}

- (NSUInteger)possibleExtraActions {
    ZBPackageExtraActionType action = 0;
    
    if (self.installed) {
        if (self.held) {
            action |= ZBPackageExtraActionShowUpdates;
        } else {
            action |= ZBPackageExtraActionHideUpdates;
        }
    }
    
    return action;
}

- (void)setPackageIconForImageView:(UIImageView *)imageView {
    UIImage *sectionImage = [PLSource imageForSection:self.section];
    if (self.iconURL) {
        [imageView sd_setImageWithURL:self.iconURL placeholderImage:sectionImage];
    }
    else {
        [imageView setImage:sectionImage];
    }
}

- (NSArray *)information {
    NSMutableArray *information = [NSMutableArray new];
    BOOL installed = self.installed;
    
    NSArray <PLPackage *> *allVersions = self.allVersions;
    if (allVersions.count > 1 && installed) {
        NSString *installedVersion = [self installedVersion];
        NSString *latestVersion = allVersions[0].version;

        if ([installedVersion compareVersion:latestVersion] == NSOrderedAscending) {
            NSDictionary *latestVersionInfo = @{@"name": NSLocalizedString(@"Latest Version", @""), @"value": latestVersion, @"cellType": @"info"};
            [information addObject:latestVersionInfo];
        }

        if (installedVersion) {
            NSDictionary *installedVersionInfo = @{@"name": NSLocalizedString(@"Installed Version", @""), @"value": installedVersion, @"cellType": @"info"};
            [information addObject:installedVersionInfo];
        }
    } else if (allVersions.count) {
        NSString *latestVersion = allVersions[0].version;
        if (latestVersion) {
            NSDictionary *latestVersionInfo = @{@"name": NSLocalizedString(@"Version", @""), @"value": latestVersion, @"cellType": @"info"};
            [information addObject:latestVersionInfo];
        }
    }
    
    NSString *bundleIdentifier = self.identifier;
    if (bundleIdentifier) {
        NSDictionary *bundleIdentifierInfo = @{@"name": NSLocalizedString(@"Bundle Identifier", @""), @"value": bundleIdentifier, @"cellType": @"info"};
        [information addObject:bundleIdentifierInfo];
    }
    
    if (installed) {
        NSString *installedSize = self.installedSizeString;
        if (installedSize) { // Show the installed size
            NSMutableDictionary *installedSizeInfo = [@{@"name": NSLocalizedString(@"Size", @""), @"value": installedSize, @"cellType": @"info", @"class": @"ZBPackageFilesViewController"} mutableCopy];
            [information addObject:installedSizeInfo];
        }
        else { // Package is installed but has no installed size, just display installed files
            NSMutableDictionary *installedFilesInfo = [@{@"name": NSLocalizedString(@"Installed Files", @""), @"cellType": @"info", @"class": @"ZBPackageFilesViewController"} mutableCopy];
            [information addObject:installedFilesInfo];
        }
    }
    else { // Show the download size
        NSString *downloadSize = self.downloadSizeString;
        if (downloadSize) {
            NSMutableDictionary *downloadSizeInfo = [@{@"name": NSLocalizedString(@"Size", @""), @"value": downloadSize, @"cellType": @"info"} mutableCopy];
            [information addObject:downloadSizeInfo];
        }
    }
    
    NSString *authorName = [self authorName];
    if (authorName) {
        NSDictionary *authorNameInfo = @{@"name": NSLocalizedString(@"Author", @""), @"value": authorName, @"cellType": @"info", @"class": @"ZBPackagesByAuthorTableViewController"};
        [information addObject:authorNameInfo];
    }
    else {
        NSString *maintainerName = [self maintainerName];
        if (maintainerName) {
            NSDictionary *maintainerNameInfo = @{@"name": NSLocalizedString(@"Maintainer", @""), @"value": maintainerName, @"cellType": @"info"};
            [information addObject:maintainerNameInfo];
        }
    }
    
    NSString *sourceOrigin = [[self source] origin];
    if (sourceOrigin) {
//        if (self.source.remote) {
            NSDictionary *sourceOriginInfo = @{@"name": NSLocalizedString(@"Source", @""), @"value": sourceOrigin, @"cellType": @"info", @"class": @"ZBSourceViewController"};
            [information addObject:sourceOriginInfo];
//        } else {
//            NSDictionary *sourceOriginInfo = @{@"name": NSLocalizedString(@"Source", @""), @"value": sourceOrigin, @"cellType": @"info"};
//            [information addObject:sourceOriginInfo];
//        }
    }
    
    NSString *section = [self section];
    if (section) {
        NSDictionary *sectionInfo = @{@"name": NSLocalizedString(@"Section", @""), @"value": section, @"cellType": @"info"};
        [information addObject:sectionInfo];
    }
    
    if (self.depends.count) {
        NSMutableArray *strippedDepends = [NSMutableArray new];
        for (NSString *depend in self.depends) {
            if ([depend containsString:@" | "]) {
                NSArray *ord = [depend componentsSeparatedByString:@" | "];
                [strippedDepends addObject:[ord componentsJoinedByString:@" or "]];
            }
            else if (![strippedDepends containsObject:depend]) {
                [strippedDepends addObject:depend];
            }
        }

        NSDictionary *dependsInfo = @{@"name": NSLocalizedString(@"Dependencies", @""), @"value": [NSString stringWithFormat:@"%lu Dependencies", (unsigned long)strippedDepends.count], @"cellType": @"info", @"more": [strippedDepends componentsJoinedByString:@"\n"]};
        [information addObject:dependsInfo];
    }

    if (self.conflicts.count) {
        NSMutableArray *strippedConflicts = [NSMutableArray new];
        for (NSString *conflict in self.conflicts) {
            if ([conflict containsString:@" | "]) {
                NSArray *orc = [conflict componentsSeparatedByString:@" | "];
                for (__strong NSString *conflict in orc) {
                    NSRange range = [conflict rangeOfString:@"("];
                    if (range.location != NSNotFound) {
                        conflict = [conflict substringToIndex:range.location];
                    }

                    if (![strippedConflicts containsObject:conflict]) {
                        [strippedConflicts addObject:conflict];
                    }
                }
            }
            else if (![strippedConflicts containsObject:conflict]) {
                [strippedConflicts addObject:conflict];
            }
        }

        NSDictionary *conflictsInfo = @{@"name": NSLocalizedString(@"Conflicts", @""), @"value": [NSString stringWithFormat:@"%lu Conflicts", (unsigned long)strippedConflicts.count], @"cellType": @"info", @"more": [strippedConflicts componentsJoinedByString:@"\n"]};
        [information addObject:conflictsInfo];
    }
//
//    if (self.lowestCompatibleVersion) {
//        NSString *compatibility;
//        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(self.lowestCompatibleVersion) && SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(self.highestCompatibleVersion)) {
//            compatibility = @"✅";
//        } else {
//            compatibility = @"⚠️";
//        }
//
//        NSDictionary *compatibiltyInfo = @{@"name": NSLocalizedString(@"Compatibility", @""), @"value": [NSString stringWithFormat:NSLocalizedString(@"iOS %@ - %@ %@", @""), self.lowestCompatibleVersion, self.highestCompatibleVersion, compatibility], @"cellType": @"info"};
//        [information addObject:compatibiltyInfo];
//    }
    
    NSURL *homepage = self.homepageURL;
    if (homepage) {
        NSDictionary *homepageInfo = @{@"name": NSLocalizedString(@"Developer Website", @""), @"cellType": @"link", @"link": homepage, @"image": @"Web Link"};
        [information addObject:homepageInfo];
    }
    
    BOOL showSupport = self.authorEmail || self.maintainerEmail;
    if (showSupport) {
        NSDictionary *homepageInfo = @{@"name": NSLocalizedString(@"Support", @""), @"cellType": @"link", @"class": @"ZBPackageSupportViewController", @"image": @"Email"};
        [information addObject:homepageInfo];
    }

    NSURL *depiction = self.depictionURL;
    if (depiction) {
        NSDictionary *depictionInfo = @{@"name": NSLocalizedString(@"View Depiction in Safari", @""), @"cellType": @"link", @"link": depiction, @"image": @"Web Link"};
        [information addObject:depictionInfo];
    }
    
    return information;
}

@end
