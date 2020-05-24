//
//  ZBPackageViewController.m
//  Zebra
//
//  Created by Wilson Styres on 1/23/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#import "ZBPackageViewController.h"
#import <Packages/Helpers/ZBPackage.h>
#import <Packages/Helpers/ZBPackageActions.h>
#import <Packages/Helpers/ZBPackageInfoController.h>
#import "ZBActionButton.h"
#import "ZBBoldTableViewHeaderView.h"
#import "ZBInfoTableViewCell.h"
#import "ZBLinkTableViewCell.h"
#import <Sources/Helpers/ZBSource.h>
#import <Extensions/UIColor+GlobalColors.h>
#import <Extensions/UINavigationBar+Extensions.h>
#import <ZBDevice.h>
#import <Downloads/ZBDownloadManager.h>
#import <ZBPackageDepictionViewController.h>

@import SDWebImage;

@interface ZBPackageViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *tagLineLabel;
@property (strong, nonatomic) IBOutlet ZBActionButton *getButton;
@property (strong, nonatomic) IBOutlet ZBActionButton *moreButton;
@property (weak, nonatomic) IBOutlet UITableView *informationTableView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIStackView *headerView;
@property (weak, nonatomic) IBOutlet UIView *depictionContainerView;
@property (strong, nonatomic) IBOutlet UIImageView *headerImageView;
@property (weak, nonatomic) IBOutlet UIView *headerImageContainerView;
@property (weak, nonatomic) IBOutlet UIView *headerImageGradientView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *informationTableViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerImageContainerViewVerticalSpaceConstraint;

@property (strong, nonatomic) ZBPackage *package;
@property (strong, nonatomic) NSArray *packageInformation;
@property (strong, nonatomic) ZBActionButton *getBarButton;
@property (strong, nonatomic) CAGradientLayer *headerImageGradientLayer;
@end

@implementation ZBPackageViewController

#pragma mark - Initializers

- (id)initWithPackage:(ZBPackage *)package {
    self = [super init];
    
    if (self) {
        self.package = package;
    }
    
    return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setDelegates];
    [self applyCustomizations];
    [self setData];
    [self configureDepictionVC];
    [self registerTableViewCells];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateNavigationBarBackgroundOpacityForCurrentScrollOffset];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self updateTableViewHeightBasedOnContent];
    self.headerImageGradientLayer.frame = self.headerImageGradientView.bounds;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController.navigationBar _setBackgroundOpacity:1];
}

#pragma mark - View Setup

- (void)setDelegates {
    self.informationTableView.delegate = self;
    self.informationTableView.dataSource = self;
    
    self.scrollView.delegate = self;
}

- (void)applyCustomizations {
    // Navigation
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self configureNavigationItems];
    
    // Tagline label tapping
    if (self.package.tagline) { // Only enable the tap recognizer if there is a tagline
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAuthorName)];
        self.tagLineLabel.userInteractionEnabled = YES;
        [self.tagLineLabel addGestureRecognizer:gestureRecognizer];
    }
    
    // Package Icon
    self.iconImageView.layer.cornerRadius = 20;
    self.iconImageView.layer.borderWidth = 1;
    self.iconImageView.layer.borderColor = [[UIColor imageBorderColor] CGColor];

    // Buttons
    [self.moreButton setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)]; // We don't want this button to have the default contentEdgeInsets inherited by a ZBActionButton
    [self configureGetButtons];
    
    // Image Header
    self.headerImageGradientLayer = [CAGradientLayer layer];
    self.headerImageGradientLayer.frame = self.headerImageGradientView.bounds;
    self.headerImageGradientLayer.colors = @[(id)[[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor, (id)[UIColor clearColor].CGColor];
    [self.headerImageGradientView.layer insertSublayer:self.headerImageGradientLayer atIndex:0];
}

- (void)setData {
    self.nameLabel.text = self.package.name;
    self.tagLineLabel.text = self.package.tagline ?: self.package.authorName ?: self.package.maintainerName;
    [self.package setIconImageForImageView:self.iconImageView];
    self.packageInformation = [self.package information];
    
    if (self.package.headerURL) {
        [self.headerImageView sd_setImageWithURL:self.package.headerURL];
        [self.headerImageContainerViewVerticalSpaceConstraint setConstant:16];
    } else {
        self.headerImageContainerView.hidden = YES;
        [[self.headerImageContainerView.heightAnchor constraintEqualToConstant:0] setActive:YES];
    }
}

- (void)registerTableViewCells {
    [self.informationTableView registerNib:[UINib nibWithNibName:NSStringFromClass([ZBInfoTableViewCell class]) bundle:nil] forCellReuseIdentifier:@"InfoTableViewCell"];
    [self.informationTableView registerNib:[UINib nibWithNibName:NSStringFromClass([ZBLinkTableViewCell class]) bundle:nil] forCellReuseIdentifier:@"LinkTableViewCell"];
    [self.informationTableView registerNib:[UINib nibWithNibName:NSStringFromClass([ZBBoldTableViewHeaderView class]) bundle:nil] forHeaderFooterViewReuseIdentifier:@"BoldTableViewHeaderView"];
}

- (void)configureDepictionVC {
    ZBPackageDepictionViewController *packageDepictionVC = [[ZBPackageDepictionViewController alloc] initWithPackage:self.package];
    [self.depictionContainerView addSubview:packageDepictionVC.view];
    [self.depictionContainerView.topAnchor constraintEqualToAnchor: packageDepictionVC.view.topAnchor].active = YES;
    [self.depictionContainerView.bottomAnchor constraintEqualToAnchor: packageDepictionVC.view.bottomAnchor].active = YES;
    [self.depictionContainerView.leftAnchor constraintEqualToAnchor: packageDepictionVC.view.leftAnchor].active = YES;
    [self.depictionContainerView.rightAnchor constraintEqualToAnchor: packageDepictionVC.view.rightAnchor].active = YES;
    packageDepictionVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addChildViewController:packageDepictionVC];
    [packageDepictionVC didMoveToParentViewController:self];
}

#pragma mark - Helper Methods

- (void)updateTableViewHeightBasedOnContent {
    self.informationTableViewHeightConstraint.constant = self.informationTableView.contentSize.height;
}

- (void)showAuthorName {
    [UIView transitionWithView:self.tagLineLabel duration:0.25f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.tagLineLabel.text = self.package.authorName;
    } completion:nil];
}

- (void)configureGetButtons {
    [self.getButton showActivityLoader];
    [self.getBarButton showActivityLoader];
    
    [ZBPackageActions buttonTitleForPackage:self.package completion:^(NSString * _Nullable text) {
        if (text) {
            [self.getButton hideActivityLoader];
            [self.getBarButton hideActivityLoader];
            
            [self.getButton setTitle:[text uppercaseString] forState:UIControlStateNormal];
            [self.getBarButton setTitle:[text uppercaseString] forState:UIControlStateNormal];
        } else {
            [self.getButton showActivityLoader];
            [self.getBarButton showActivityLoader];
        }
    }];
}

- (IBAction)getButtonPressed:(id)sender {
    [ZBPackageActions buttonActionForPackage:self.package]();
}

- (IBAction)moreButtonPressed:(id)sender {
    UIAlertController *extraActions = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray <UIAlertAction *> *actions = [ZBPackageActions extraAlertActionsForPackage:self.package selectionCallback:^(ZBPackageExtraActionType action) {
        if (action == ZBPackageExtraActionShare) {
            UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:@[self.package] applicationActivities:nil];
            
            [self presentViewController:shareSheet animated:YES completion:nil];
        }
    }];
    for (UIAlertAction *action in actions) {
        [extraActions addAction:action];
    }
    
    [self presentViewController:extraActions animated:YES completion:nil];
}

- (void)configureNavigationItems {
    UIView *container = [[UIView alloc] initWithFrame:self.navigationItem.titleView.frame];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    imageView.center = self.navigationItem.titleView.center;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.layer.cornerRadius = 5;
    imageView.layer.masksToBounds = YES;
    imageView.alpha = 0.0;
    [self.package setIconImageForImageView:imageView];
    [container addSubview:imageView];
    self.navigationItem.titleView = container;
    
    self.getBarButton = [[ZBActionButton alloc] init];
    [self.getBarButton addTarget:self action:@selector(getButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.getBarButton];
    self.navigationItem.rightBarButtonItem.customView.alpha = 0.0;
}

- (void)setNavigationItemsHidden:(BOOL)hidden {
    [UIView animateWithDuration:0.25 animations:^{
        self.navigationItem.rightBarButtonItem.customView.alpha = hidden ? 0.0 : 1.0;
        self.navigationItem.titleView.subviews[0].alpha = hidden ? 0.0 : 1.0;
    }];
}

- (void)updateNavigationBarBackgroundOpacityForCurrentScrollOffset {
    if (self.package.headerURL) {
        CGFloat maximumVerticalOffsetForOpacity = self.headerImageContainerView.frame.size.height;
        CGFloat maximumVerticalOffsetForButtons = (self.headerImageContainerView.frame.size.height + self.headerView.frame.size.height) - (self.getButton.frame.size.height / 2) + self.headerImageContainerViewVerticalSpaceConstraint.constant;

        CGFloat currentVerticalOffset = self.scrollView.contentOffset.y + self.view.safeAreaInsets.top;
        CGFloat percentageVerticalOffset = currentVerticalOffset / maximumVerticalOffsetForOpacity;
        CGFloat opacity = MAX(0, MIN(1, percentageVerticalOffset));
        
        UIColor *blendedColor = [[UIColor whiteColor] blendWithColor:[UIColor accentColor] progress:opacity];
        
        self.navigationController.navigationBar.tintColor = blendedColor;
        
        [self setNavigationItemsHidden:currentVerticalOffset / maximumVerticalOffsetForButtons < 1];
        
        if (self.navigationController.navigationBar._backgroundOpacity == opacity) return; // Return if the opacity doesn't differ from what it is currently.
        [self.navigationController.navigationBar _setBackgroundOpacity:opacity]; // Ensure the opacity is not negative or greater than 1.
    } else {
        CGFloat maximumVerticalOffset = self.headerView.frame.size.height - (self.getButton.bounds.size.height / 2);
        CGFloat currentVerticalOffset = self.scrollView.contentOffset.y + self.view.safeAreaInsets.top;
        CGFloat percentageVerticalOffset = currentVerticalOffset / maximumVerticalOffset;
        CGFloat opacity = MAX(0, MIN(1, percentageVerticalOffset));

        if (self.navigationController.navigationBar._backgroundOpacity == opacity) return; // Return if the opacity doesn't differ from what it is currently.
        
        [self setNavigationItemsHidden:(opacity < 1)];
        [self.navigationController.navigationBar _setBackgroundOpacity:opacity]; // Ensure the opacity is not negative or greater than 1.
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.packageInformation count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ZBBoldTableViewHeaderView *cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"BoldTableViewHeaderView"];
    cell.titleLabel.text = NSLocalizedString(@"Information", @"");
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    return 50;
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *packageInformation = self.packageInformation[indexPath.row];
    NSString *cellType = packageInformation[@"cellType"];
    
    if ([cellType isEqualToString:@"link"]) {
        ZBLinkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LinkTableViewCell" forIndexPath:indexPath];
        
        cell.nameLabel.text = packageInformation[@"name"];
        if ([packageInformation objectForKey:@"image"]) {
            cell.iconImageView.image = [UIImage imageNamed:packageInformation[@"image"]];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        
        return cell;
    }
    else if ([cellType isEqualToString:@"info"]) {
        ZBInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InfoTableViewCell" forIndexPath:indexPath];
        
        cell.nameLabel.text = self.packageInformation[indexPath.row][@"name"];
        cell.valueLabel.text = self.packageInformation[indexPath.row][@"value"];
        
        if ([packageInformation objectForKey:@"class"]) {
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            [cell setChevronHidden:NO];
        }
        else {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell setChevronHidden:YES];
        }

        return cell;
    }
    else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UnknownCell"];
        
        cell.textLabel.text = @"Unknown cellType";
        cell.textLabel.text = cellType ?: @"NULL";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *packageInformation = self.packageInformation[indexPath.row];
    
    if ([packageInformation objectForKey:@"link"]) {
        [ZBDevice openURL:packageInformation[@"link"] sender:self];
    }
    else if ([packageInformation objectForKey:@"class"]) {
        Class infoControllerClass = NSClassFromString(packageInformation[@"class"]);
        if ([infoControllerClass conformsToProtocol:@protocol(ZBPackageInfoController)]) {
            UIViewController <ZBPackageInfoController> *infoController = [[infoControllerClass alloc] initWithPackage:self.package];
            if (infoController) {
                if ([packageInformation[@"cellType"] isEqualToString:@"link"]) {
                    [self presentViewController:infoController animated:YES completion:nil];
                }
                else {
                    [[self navigationController] pushViewController:infoController animated:YES];
                }
            }
        }
        else {
            UIAlertController *doesNotConform = [UIAlertController alertControllerWithTitle:@"ZBPackageInfoController" message:[NSString stringWithFormat:@"The class %@ does not conform to the ZBPackageInfoController protocol and therefore cannot be presented.", packageInformation[@"class"]] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
            [doesNotConform addAction:okAction];
            
            [self presentViewController:doesNotConform animated:YES completion:nil];
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.scrollView) return;
    [self updateNavigationBarBackgroundOpacityForCurrentScrollOffset];
}

@end
