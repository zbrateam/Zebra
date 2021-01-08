//
//  ZBFeaturedPackagesCollectionView.m
//  Zebra
//
//  Created by Andrew Abosh on 2021-01-06.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

#import "ZBFeaturedPackagesCollectionView.h"

#import <Managers/ZBSourceManager.h>
#import <Model/ZBSource.h>
#import <UI/Packages/Views/Cells/ZBFeaturedPackageCollectionViewCell.h>

#import <Extensions/NSArray+Random.h>

@import SDWebImage;

@implementation ZBFeaturedPackagesCollectionView

NSString *const ZBFeaturedCollectionViewCellReuseIdentifier = @"ZBFeaturedPackageCollectionViewCell"; // TODO: Move this to ZBFeaturedPackageCollectionViewCell?

- (instancetype)initWithFrame:(CGRect)frame {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize;
    layout.sectionInset = UIEdgeInsetsMake(16, 16, 16, 16);
    
    self = [super initWithFrame:frame collectionViewLayout:layout];
    
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        [self registerNib:[UINib nibWithNibName:@"ZBFeaturedPackageCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:ZBFeaturedCollectionViewCellReuseIdentifier];
        [self setBackgroundColor:[UIColor systemBackgroundColor]];
        [self setShowsHorizontalScrollIndicator:NO];
    }
    
    return self;
}

#pragma mark - Properties

- (void)setPosts:(NSArray *)posts {
    @synchronized (_posts) {
        _posts = posts;
        
        // hide spinner
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.numberOfSections == 1 && self->_posts.count) {
                [self reloadSections:[NSIndexSet indexSetWithIndex:0]];
            } else if (self.numberOfSections == 0 && self->_posts.count) {
                [self insertSections:[NSIndexSet indexSetWithIndex:0]];
            } else {
                [self deleteSections:[NSIndexSet indexSetWithIndex:0]];
            }
        });
    }
}

#pragma mark - Fetching Data

- (void)fetch {
    [self fetchFromSource:NULL];
}

- (void)fetchFromSource:(ZBSource *)source {
    NSMutableArray *sourcesToFetch = [NSMutableArray new];
    if (source) {
        [sourcesToFetch addObject:source];
    } else { // If sources is NULL, load from all sources
        [sourcesToFetch addObjectsFromArray:[[ZBSourceManager sharedInstance] sources]];
    }
    
    for (ZBSource *source in sourcesToFetch) {
        if (!source.supportsFeaturedPackages) continue;
        
        NSURL *featuredPackagesURL = [[NSURL alloc] initWithString:@"sileo-featured.json" relativeToURL:source.mainDirectoryURL];
        if (!featuredPackagesURL) continue;
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:featuredPackagesURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSMutableArray *packages = [NSMutableArray new];
            NSError *parseError = NULL;
            NSDictionary *featuredPackages = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:&parseError];
            if (featuredPackages && !error && !parseError) {
                NSArray *banners = featuredPackages[@"banners"];
                if (banners && banners.count) [packages addObjectsFromArray:banners];
            }
            
            self.posts = source != NULL ? packages : [packages shuffleWithCount:10];
        }];
        
        [task resume];
    }
}

#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _posts.count > 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return MIN(_posts.count, 10);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZBFeaturedPackageCollectionViewCell *cell = [self dequeueReusableCellWithReuseIdentifier:ZBFeaturedCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    
    NSDictionary *package = _posts[indexPath.row];
    cell.repoLabel.text = @"AMDREW ABOSSH";
    cell.packageLabel.text = package[@"title"];
    cell.descriptionLabel.text = @"ARTWORKS";
    
    [cell.bannerImageView sd_setImageWithURL:[NSURL URLWithString:package[@"url"]]];
    
    return cell;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

@end
