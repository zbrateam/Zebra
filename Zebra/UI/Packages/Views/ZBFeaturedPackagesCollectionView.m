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
    
    NSMutableArray *packages = [NSMutableArray new];
    for (ZBSource *source in sourcesToFetch) {
        if (!source.supportsFeaturedPackages) continue;
        NSLog(@"%@", source.label);
        
        NSURL *featuredPackagesURL = [[NSURL alloc] initWithString:@"sileo-featured.json" relativeToURL:source.mainDirectoryURL];
        if (!featuredPackagesURL) continue;
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:featuredPackagesURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSDictionary *featuredPackages = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:nil];
            NSLog(@"pack: %@", featuredPackages);
        }];
        
        [task resume];
    }
}

#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 6;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [self dequeueReusableCellWithReuseIdentifier:ZBFeaturedCollectionViewCellReuseIdentifier forIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

@end
