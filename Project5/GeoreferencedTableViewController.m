//
//  GeoreferenceTableViewController.m
//  Project5
//
//  Created by Glenn Axworthy on 10/26/15.
//  Copyright © 2015 Glenn Axworthy. All rights reserved.
//

#import "GeoreferencedTableViewController.h"
#import "HistoryTableViewController.h"
#import "ImageViewController.h"

@interface GeoreferencedTableViewController ()

@property (strong, nonatomic) NSArray *photos;

@end

@implementation GeoreferencedTableViewController

- (void)awakeFromNib {
    self.splitViewController.delegate = self; // must be done here
}

- (void) fetchPhotos:(BOOL)reloading {
    [self.refreshControl beginRefreshing];
    dispatch_queue_t fetchQueue = dispatch_queue_create("fetchPhotos", 0);
    dispatch_async(fetchQueue, ^{
        NSError *error = nil;
        NSURL *url = [FlickrFetcher URLforRecentGeoreferencedPhotos];
        NSData *json = [NSData dataWithContentsOfURL:url options:0 error:&error];
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:json options:0 error:&error];
        NSArray *photos = [dictionary valueForKeyPath:FLICKR_RESULTS_PHOTOS];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.photos = photos;
            [self.refreshControl endRefreshing];
            if (!reloading)
                [self.tableView reloadData];
        });
    });
}

- (IBAction)reloadData:(id)sender {
    [self fetchPhotos:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // sometimes can't trust IB
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(reloadData:)
                  forControlEvents:UIControlEventValueChanged];

    [self fetchPhotos:NO];
}

#pragma mark - split view controller delegate

- (BOOL)splitViewController:(UISplitViewController *)sender
    shouldHideViewController:(UIViewController *)master
    inOrientation:(UIInterfaceOrientation)orientation {

    BOOL portrait = UIInterfaceOrientationIsPortrait(orientation);
    if (!portrait) {
        // remove left bar button item from detail
        UINavigationController *navigation = sender.viewControllers[1];
        UIViewController *detail = navigation.topViewController;
        detail.navigationItem.leftBarButtonItem = nil;
    }

    return portrait;
}

- (void)splitViewController:(UISplitViewController *)sender
     willHideViewController:(UIViewController *)master
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc {

    UINavigationController *navigation = sender.viewControllers[1];
    if ([navigation isKindOfClass:[UINavigationController class]]) {
        UIViewController *detail = navigation.topViewController;
        detail.navigationItem.leftBarButtonItem = barButtonItem;
        barButtonItem.title = master.title;
    }
}

- (void)splitViewController:(UISplitViewController *)sender
     willShowViewController:(UIViewController *)master
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {

    UINavigationController *navigation = sender.viewControllers[1];
    UIViewController *detail = navigation.topViewController;
    detail.navigationItem.leftBarButtonItem = nil;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id detailViewController = self.splitViewController.viewControllers[1];
    if (detailViewController) { // iPad only
        NSDictionary *photo = self.photos[indexPath.row];
        NSString *title = [photo objectForKey:FLICKR_PHOTO_TITLE];

        // image controller lives inside navigation controller in storyboard
        UINavigationController *navigationController = detailViewController;
        ImageViewController *imageController = (id) navigationController.topViewController;
        imageController.photo = photo;
        imageController.title = title;
        
        [HistoryTableViewController addPhotoHistory:photo];
    }
}

#pragma mark - table view data source delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"GeoreferencedTableViewCell" forIndexPath:indexPath];
    NSDictionary *photo = self.photos[indexPath.row];
    cell.textLabel.text = [photo objectForKey:FLICKR_PHOTO_TITLE];
    cell.detailTextLabel.text = [photo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.photos count];
}

#pragma mark - navigation
 
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UITableViewCell *cell = sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *photo = self.photos[indexPath.row];
    NSString *title = [photo objectForKey:FLICKR_PHOTO_TITLE];

    ImageViewController *controller = segue.destinationViewController;
    controller.photo = photo;
    controller.title = title;

    [HistoryTableViewController addPhotoHistory:photo];
}

@end
