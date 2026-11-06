//
//  ZBCommunitySourcesTableViewController.m
//  Zebra
//
//  Created by midnightchips on 6/30/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBCommunitySourcesTableViewController.h"

#import "ZBLog.h"
#import "ZBDevice.h"
#import "ZBSettings.h"
#import "ZBDependencyResolver.h"
#import "UIColor+GlobalColors.h"
#import "ZBRefreshViewController.h"
#import "ZBSourceTableViewCell.h"
#import "ZBSource.h"
#import "ZBSourceImportTableViewController.h"
#import "NSURLSession+Zebra.h"
#import "UIImageView+Zebra.h"
#import "ZBCommunitySources.h"

@interface ZBCommunitySourcesTableViewController () {
    NSArray <ZBCommunitySource *> *communitySourceCache;
    ZBSourceManager *sourceManager;
    NSMutableArray <NSArray <ZBCommunitySource *> *> *sources;
}
@end

@implementation ZBCommunitySourcesTableViewController

- (id)init {
    self = [super initWithStyle:[ZBDevice tableViewStyle]];

    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseCompletedUpdate) name:@"ZBDatabaseCompletedUpdate" object:nil];

        sourceManager = [ZBSourceManager sharedInstance];
        sources = [NSMutableArray new];

        [self populateSources];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }

    [self.tableView registerNib:[UINib nibWithNibName:@"ZBSourceTableViewCell" bundle:nil] forCellReuseIdentifier:@"sourceTableViewCell"];
}

- (void)databaseCompletedUpdate {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self populateSources];
    });
}

- (void)populateSources {
    [sources removeAllObjects];

    //Populate package managers
    NSArray *managers = [self packageManagers];
    if (managers.count) {
        [sources addObject:managers];
    }

    //Populate utility source
    NSArray *utilitySources = [self utilitySources];
    if (utilitySources.count) {
        [sources addObject:utilitySources];
    }

    //Populate community sources
    NSArray *communitySources = [self communitySources];
    if (communitySources.count) {
        [sources addObject:communitySources];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (NSArray <ZBCommunitySource *> *)packageManagers {
    NSMutableArray *result = [NSMutableArray new];
    if ([[NSFileManager defaultManager] fileExistsAtPath:@INSTALL_PREFIX @"/Applications/Cydia.app/Cydia"]) {
        NSDictionary *dict = @{@"type" : @"transfer",
                               @"name" : @"Cydia",
                               @"label": [NSString stringWithFormat:NSLocalizedString(@"Transfer sources from %@ to Zebra", @""), @"Cydia"],
                               @"url"  : @"file://" @INSTALL_PREFIX @"/etc/apt/sources.list.d/",
                               @"ext"  : @"list",
                               @"icon" : @"file://" @INSTALL_PREFIX @"/Applications/Cydia.app/Icon-60@2x.png"};
        [result addObject:dict];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:@INSTALL_PREFIX @"/Applications/Installer.app/Installer"]) {
        NSDictionary *dict = @{@"type" : @"transfer",
                               @"name" : @"Installer",
                               @"label": [NSString stringWithFormat:NSLocalizedString(@"Transfer sources from %@ to Zebra", @""), @"Installer"],
                               @"url"  : @"file:///var/mobile/Library/Application%20Support/Installer/APT/sources.list",
                               @"ext"  : @"list",
                               @"icon" : @"file://" @INSTALL_PREFIX @"/Applications/Installer.app/AppIcon60x60@2x.png"};
        [result addObject:dict];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:@INSTALL_PREFIX @"/Applications/Sileo.app/Sileo"]) {
        NSDictionary *dict = @{@"type" : @"transfer",
                               @"name" : @"Sileo",
                               @"label": [NSString stringWithFormat:NSLocalizedString(@"Transfer sources from %@ to Zebra", @""), @"Sileo"],
                               @"url"  : [ZBDevice jailbreak] == ZBJailbreakCheckra1n ? @"file://" @INSTALL_PREFIX @"/etc/apt/sileo.list.d/" : @"file://" @INSTALL_PREFIX @"/etc/apt/sources.list.d/",
                               @"ext"  : @"sources",
                               @"icon" : @"file://" @INSTALL_PREFIX @"/Applications/Sileo.app/AppIcon60x60@2x.png"};
        [result addObject:dict];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:@INSTALL_PREFIX @"/Applications/Sileo-Nightly.app/Sileo"]) {
        NSDictionary *dict = @{@"type" : @"transfer",
                               @"name" : @"Sileo Nightly",
                               @"label": [NSString stringWithFormat:NSLocalizedString(@"Transfer sources from %@ to Zebra", @""), @"Sileo Nightly"],
                               @"url"  : [ZBDevice jailbreak] == ZBJailbreakCheckra1n ? @"file://" @INSTALL_PREFIX @"/etc/apt/sileo.list.d/" : @"file://" @INSTALL_PREFIX @"/etc/apt/sources.list.d/",
                               @"ext"  : @"sources",
                               @"icon" : @"file://" @INSTALL_PREFIX @"/Applications/Sileo-Nightly.app/AppIcon60x60@2x.png"};
        [result addObject:dict];
    }
    return [self sourcesFromDictionaries:result];
}

- (NSArray <ZBCommunitySource *> *)utilitySources {
    NSMutableArray *result = [NSMutableArray array];
    switch ([ZBDevice jailbreak]) {
    case ZBJailbreakTaurine:
        [result addObject:@{@"type": @"utility",
                            @"name": @"Procursus",
                            @"url" : @"https://apt.procurs.us/",
                            @"icon": @"https://apt.procurs.us/CydiaIcon.png"}];
        [result addObject:@{@"type": @"utility",
                            @"name": @"Odyssey Repo",
                            @"url" : @"https://repo.theodyssey.dev/",
                            @"icon": @"https://repo.theodyssey.dev/CydiaIcon.png"}];
        break;

    case ZBJailbreakUnc0ver:
        [result addObject:@{@"type": @"utility",
                            @"name": @"Bingner/Elucubratus",
                            @"url" : @"https://apt.bingner.com/",
                            @"icon": @"https://apt.bingner.com/CydiaIcon.png"}];
        break;

    case ZBJailbreakOdyssey:
        [result addObject:@{@"type": @"utility",
                            @"name": @"Procursus",
                            @"url" : @"https://apt.procurs.us/",
                            @"icon": @"https://apt.procurs.us/CydiaIcon.png"}];
        [result addObject:@{@"type": @"utility",
                            @"name": @"Odyssey Repo",
                            @"url" : @"https://repo.theodyssey.dev/",
                            @"icon": @"https://repo.theodyssey.dev/CydiaIcon.png"}];
        break;

    case ZBJailbreakChimera:
    case ZBJailbreakElectra:
        [result addObject:@{@"type": @"utility",
                            @"name": @"Chimera Repo",
                            @"url" : @"https://repo.chimera.sh/",
                            @"icon": @"https://repo.chimera.sh/CydiaIcon.png"}];
        break;

    case ZBJailbreakPalera1n:
        if ([ZBDevice isPrefixed]) {
            [result addObject:@{@"type": @"utility",
                                @"name": @"Procursus",
                                @"url" : @"https://apt.procurs.us/",
                                @"icon": @"https://apt.procurs.us/CydiaIcon.png"}];
            [result addObject:@{@"type": @"utility",
                                @"name": @"ElleKit",
                                @"url" : @"https://ellekit.space/",
                                @"icon": @"https://ellekit.space/CydiaIcon.png"}];
        } else {
            [result addObject:@{@"type": @"utility",
                                @"name": @"palera1n strap",
                                @"url" : @"https://strap.palera.in/",
                                @"icon": @"https://strap.palera.in/CydiaIcon.png"}];
        }
        [result addObject:@{@"type": @"utility",
                            @"name": @"palera1n",
                            @"url" : @"https://repo.palera.in/",
                            @"icon": @"https://repo.palera.in/CydiaIcon.png"}];
        break;

    case ZBJailbreakDopamine:
        [result addObject:@{@"type": @"utility",
                            @"name": @"Procursus",
                            @"url" : @"https://apt.procurs.us/",
                            @"icon": @"https://apt.procurs.us/CydiaIcon.png"}];
        [result addObject:@{@"type": @"utility",
                            @"name": @"ElleKit",
                            @"url" : @"https://ellekit.space/",
                            @"icon": @"https://ellekit.space/CydiaIcon.png"}];
        break;
            
    case ZBJailbreakAmethyst:
        [result addObject:@{@"type": @"utility",
                            @"name": @"Procursus",
                            @"url" : @"https://apt.procurs.us/",
                            @"icon": @"https://apt.procurs.us/CydiaIcon.png"}];
        break;
            
    case ZBJailbreakApex:
        [result addObject:@{@"type": @"utility",
                            @"name": @"Procursus",
                            @"url" : @"https://apt.procurs.us/",
                            @"icon": @"https://apt.procurs.us/CydiaIcon.png"}];
        [result addObject:@{@"type": @"utility",
                            @"name": @"Odyssey Repo",
                            @"url" : @"https://repo.theodyssey.dev/",
                            @"icon": @"https://repo.theodyssey.dev/CydiaIcon.png"}];
        break;


    default:
        switch ([ZBDevice bootstrap]) {
        case ZBBootstrapProcursus:
        case ZBBootstrapSimulated:
            [result addObject:@{@"type": @"utility",
                                @"name": @"Procursus",
                                @"url" : @"https://apt.procurs.us/",
                                @"icon": @"https://apt.procurs.us/CydiaIcon.png"}];
            break;

        case ZBBootstrapElucubratus:
            [result addObject:@{@"type": @"utility",
                                @"name": @"Bingner/Elucubratus",
                                @"url" : @"https://apt.bingner.com/",
                                @"icon": @"https://apt.bingner.com/CydiaIcon.png"}];
            break;

        case ZBBootstrapTelesphoreo:
            [result addObject:@{@"type": @"utility",
                                @"name": @"Cydia/Telesphoreo",
                                @"url" : @"http://apt.saurik.com/",
                                @"icon": @"http://apt.saurik.com/dists/ios/CydiaIcon.png"}];
            break;

        case ZBBootstrapUnknown:
            break;
        }
    }
    return [self sourcesFromDictionaries:result];
}

- (NSArray <ZBCommunitySource *> *)sourcesFromDictionaries:(NSArray <NSDictionary *> *)dictionaries {
    NSMutableArray <ZBCommunitySource *> *result = [NSMutableArray arrayWithCapacity:dictionaries.count];
    for (NSDictionary *dict in dictionaries) {
        [result addObject:[ZBCommunitySource fromJSONDictionary:dict]];
    }
    return result;
}

- (NSArray <ZBCommunitySource *> *)communitySources {
    if (!communitySourceCache) {
        [self fetchCommunitySources];

        return NULL;
    }
    else {
        // This is supposed to filter out sources that you already have added but since we're redoing this in 1.2 it can be disabled to reduce crashes
//        NSMutableArray *result = [NSMutableArray new];
//        for (NSDictionary *source in communitySourceCache) {
//            if (![ZBSource exists:source[@"url"]]) [result addObject:source];
//        }
//
//        return result;
        return communitySourceCache;
    }
}

- (void)fetchCommunitySources {
    communitySourceCache = [NSMutableArray new];

    NSURL *url = [NSURL URLWithString:@"https://api.getzbra.com/sources.json"];
    NSURLSessionDataTask *task = [[NSURLSession zbra_standardSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, __unused NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSMutableArray <ZBCommunitySource *> *sources = [NSMutableArray new];
        if (data && !error) {
            for (ZBCommunitySource *source in [ZBCommunitySources fromData:data error:nil].repos) {
                if (source.appVersion && [ZBDependencyResolver doesVersion:@PACKAGE_VERSION satisfyComparison:@">=" ofVersion:source.appVersion]) {
                    [sources addObject:source];
                }
            }
        }
        else {
            ZBLog(@"[Zebra] Error while trying to access community sources: %@", error);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (sources.count) {
                self->communitySourceCache = sources;
            }

            [self populateSources];

            self.navigationItem.titleView = nil;
            self.navigationItem.title = NSLocalizedString(@"Community Sources", @"");
        });
    }];

    [task resume];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return sources.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sources[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZBCommunitySource *info = sources[indexPath.section][indexPath.row];

    if ([info.type isEqualToString:@"none"]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"noneLeftCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noneLeftCell"];
        }

        cell.textLabel.text = NSLocalizedString(@"You’ve added all of the community sources", @"");
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor secondaryTextColor];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        return cell;
    }

    ZBSourceTableViewCell *cell = (ZBSourceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"sourceTableViewCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor cellBackgroundColor];

    cell.sourceLabel.text = info.name;
    cell.sourceLabel.textColor = [UIColor primaryTextColor];

    cell.urlLabel.text = info.label ?: info.url;
    cell.urlLabel.textColor = [UIColor secondaryTextColor];

    NSURL *iconURL = info.icon ? [NSURL URLWithString:info.icon] : nil;
    [cell.iconImageView setRetinaImageWithURL:iconURL placeholderImage:[UIImage imageNamed:@"Unknown"] completed:^(UIImage *image, __unused NSError *error, __unused SDImageCacheType cacheType, __unused NSURL *imageURL) {
        [cell.iconImageView setIconImage:image variant:MIIconVariantSettings];
    }];

    [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (sources.count) {
        NSString *type = sources[section][0].type;

        NSArray *options = @[@"transfer", @"utility", @"repo", @"none"];
        NSUInteger index = type ? [options indexOfObject:type] : NSNotFound;
        switch (index) {
            case 0:
                return NSLocalizedString(@"Transfer Sources", @"");
            case 1:
                return NSLocalizedString(@"Utilities", @"");
            case 2:
                return NSLocalizedString(@"Community Sources", @"");
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    ZBCommunitySource *info = sources[indexPath.section][indexPath.row];
    NSURL *url = info.url ? [NSURL URLWithString:info.url] : nil;
    if (!url) {
        return;
    }

    NSArray *options = @[@"transfer", @"utility", @"repo"];
    NSUInteger index = info.type ? [options indexOfObject:info.type] : NSNotFound;
    switch (index) {
        case 0: {
            dispatch_async(dispatch_get_main_queue(), ^{
                ZBSourceImportTableViewController *importController = [[ZBSourceImportTableViewController alloc] initWithPaths:@[url] extension:info.ext];

                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:importController];
                [self presentViewController:navController animated:YES completion:nil];
            });
            break;
        }
        case 1:
        case 2: {
            ZBBaseSource *source = [[ZBBaseSource alloc] initFromURL:url];
            if (source) {
                [sourceManager addBaseSources:[NSSet setWithObject:source]];
                ZBRefreshViewController *refresh = [[ZBRefreshViewController alloc] initWithDropTables:NO baseSources:[NSSet setWithObject:source]];

                [self presentViewController:refresh animated:YES completion:nil];
            }
            break;
        }
        default:
            break;
    }
}

- (void)presentConsole {
    ZBRefreshViewController *refreshController = [[ZBRefreshViewController alloc] init];
    [self presentViewController:refreshController animated:YES completion:nil];
}

@end
