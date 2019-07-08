//
//  ZBNewsTableViewCell.m
//  Zebra
//
//  Created by midnightchips on 7/8/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBNewsTableViewCell.h"
#import "ZBNewsCollectionViewCell.h"
@import SDWebImage;

@implementation ZBNewsTableViewCell
static BOOL hasSetSize = FALSE;
- (void)awakeFromNib {
    [super awakeFromNib];
    self.redditPosts = [NSMutableArray new];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"ZBNewsCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"newsCell"];
    UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    flow.estimatedItemSize = CGSizeMake(1,1);
    UICollectionViewFlowLayout *collectionLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    collectionLayout.itemSize = CGSizeMake(263, 148);
    collectionLayout.estimatedItemSize = CGSizeMake(263, 148);
    // Initialization code
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
    if (!hasSetSize) {
        self.collectionView.frame = CGRectMake(0,0, targetSize.width,MAXFLOAT);
        [self.collectionView layoutIfNeeded];
        hasSetSize = TRUE;
    }
    
    return [self.collectionView.collectionViewLayout collectionViewContentSize];
 }

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupCollectionView:(NSArray *)posts {
    [self.redditPosts removeAllObjects];
    [self.redditPosts addObjectsFromArray:posts];
    [self.collectionView reloadData];
}

- (UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ZBNewsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"newsCell" forIndexPath:indexPath];
    NSDictionary *dict = [self.redditPosts objectAtIndex:indexPath.row];
    cell.postTitle.text = [dict valueForKey:@"title"];
    cell.postTag.text = [dict valueForKey:@"link_flair_css_class"];
    cell.postTag.text = [cell.postTag.text capitalizedString];
    [cell setRedditLink:[NSURL URLWithString:[dict objectForKey:@"url"]]];
    if ([[dict valueForKey:@"thumbnail"] isEqualToString:@"self"] || [[dict valueForKey:@"thumbnail"] isEqualToString:@"default"] || [[dict valueForKey:@"thumbnail"] isEqualToString:@"nsfw"]) {
        [cell.backgroundImage setImage:[UIImage imageNamed:@"banner"]];
    } else {
        [cell.backgroundImage sd_setImageWithURL:[NSURL URLWithString:[dict valueForKey:@"thumbnail"]] placeholderImage:[UIImage imageNamed:@"Unknown"]];
    }
    
    //[cell layoutIfNeeded]
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.redditPosts.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ZBNewsCollectionViewCell *cell = (ZBNewsCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    SFSafariViewController *safariVC = [[SFSafariViewController alloc]initWithURL:cell.redditLink entersReaderIfAvailable:NO];
    safariVC.delegate = self;
    [safariVC.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    [safariVC.navigationController.navigationBar setBackgroundColor:[UIColor whiteColor]];
    [safariVC.navigationController.navigationBar setTintColor:[UIColor blueColor]];
    [self.parentVC presentViewController:safariVC animated:YES completion:nil];
}

#pragma mark - SFSafariViewController delegate methods
-(void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
    // Load finished
}

-(void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    // Done button pressed
    [controller dismissViewControllerAnimated:TRUE completion:nil];
}

@end
