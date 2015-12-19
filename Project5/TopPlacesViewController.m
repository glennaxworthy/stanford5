//
//  TopPlacesViewController.m
//  Project5
//
//  Created by Glenn Axworthy on 11/1/15.
//  Copyright © 2015 Glenn Axworthy. All rights reserved.
//

#import "TopPlacesViewController.h"
#import "FlickrFetcher.h"
#import "HistoryTableViewController.h"
#import "ImageViewController.h"

@interface TopPlacesViewController ()

@property (strong, nonatomic) NSArray *topPlaces;

@end

@implementation TopPlacesViewController

- (void)fetchTopPlaces {
    [self.refreshControl beginRefreshing];
    dispatch_queue_t fetchQueue = dispatch_queue_create("fetchPhotos", 0);
    dispatch_async(fetchQueue, ^{
        NSURL *url = [FlickrFetcher URLforTopPlaces];
        NSData *json = [NSData dataWithContentsOfURL:url options:0 error:nil];
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
        
        NSMutableArray *topPlaces = [[NSMutableArray alloc] init];
        NSArray *places = [dictionary valueForKeyPath:FLICKR_RESULTS_PLACES];
        for (NSDictionary *place in places) {
            NSString *placeName = [place objectForKey:FLICKR_PLACE_NAME];
            NSArray *placeNames = [placeName componentsSeparatedByString:@", "];
            NSString *countryName = [placeNames lastObject];
            
            // find country in array of top places
            NSUInteger index = [topPlaces indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                NSMutableArray *placeArray = obj; // placeArray[0] is place name
                if ([placeArray[0] caseInsensitiveCompare:countryName] == NSOrderedSame) {
                    // add place to existing array
                    [placeArray addObject:place];
                    return YES;
                }
                
                return NO;
            }];
            
            if (index == NSNotFound) {
                // add new place array to top places
                NSMutableArray *placeArray = [NSMutableArray arrayWithObjects: countryName, place, nil];
                [topPlaces addObject:placeArray];
            }
        }
        
        // sort array of top places
        [topPlaces sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *country1 = ((NSArray *) obj1)[0];
            NSString *country2 = ((NSArray *) obj2)[0];
            return [country1 caseInsensitiveCompare:country2];
        }];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.topPlaces = topPlaces;
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
        });
    });
}

- (IBAction)reloadData:(id)sender {
    [self fetchTopPlaces];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    // sometimes can't trust IB
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(reloadData:)
                  forControlEvents:UIControlEventValueChanged];

    [self fetchTopPlaces];
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id detailViewController = self.splitViewController.viewControllers[1];
    if (detailViewController) { // iPad only
        UINavigationController *navigationController = detailViewController;
        ImageViewController *imageController = (id) navigationController.topViewController;
        [self prepareImageController:imageController indexPath:indexPath];
    }
}

#pragma mark - table view data source delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TopPlacesTableViewCell" forIndexPath:indexPath];

    NSArray *topPlaces = self.topPlaces[indexPath.section];
    NSDictionary *topPlace = topPlaces[indexPath.row + 1];
    NSString *placeName = [topPlace objectForKey:FLICKR_PLACE_NAME];
    NSArray *placeNames = [placeName componentsSeparatedByString:@", "];
    NSString *title = placeNames[0];
    for (int index = 1; index < [placeNames count]; index++)
        [title stringByAppendingFormat:@", %@", placeNames[index]];

    cell.textLabel.text = title;
    cell.detailTextLabel.text = [topPlace valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *placeArray = self.topPlaces[section];
    return [placeArray count] - 1; // placeArray[0] is country name
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.topPlaces count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *place = self.topPlaces[section];
    return place[0];
}

#pragma mark - navigation

- (void)prepareImageController:(ImageViewController *)controller indexPath:(NSIndexPath *)indexPath {
    NSArray *places = self.topPlaces[indexPath.section];
    NSDictionary *place = places[indexPath.row + 1];
    
    NSString *placeId = [place valueForKey:FLICKR_PLACE_ID];
    NSURL *placeURL = [FlickrFetcher URLforPhotosInPlace:placeId maxResults:1];
    NSData *json = [NSData dataWithContentsOfURL:placeURL options:0 error:nil];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    NSArray *photos = [dictionary valueForKeyPath:FLICKR_RESULTS_PHOTOS];
    NSDictionary *photo = photos[0]; // first photo only - waste of time
    controller.photo = photo;
    controller.title = [photo objectForKey:FLICKR_PHOTO_TITLE];

    [HistoryTableViewController addPhotoHistory:photo];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UITableViewCell *cell = sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ImageViewController *controller = segue.destinationViewController;
    [self prepareImageController:controller indexPath:indexPath];
}

@end
