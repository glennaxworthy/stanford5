//
//  HistoryTableViewController.m
//  Project5
//
//  Created by Glenn Axworthy on 11/2/15.
//  Copyright © 2015 Glenn Axworthy. All rights reserved.
//

#import "HistoryTableViewController.h"
#import "FlickrFetcher.h"
#import "ImageViewController.h"

@interface HistoryTableViewController ()

@end

@implementation HistoryTableViewController

+ (void)addPhotoHistory:(NSDictionary *)photo {
    NSMutableDictionary *photoEntry = [[NSMutableDictionary alloc] init];
    [photoEntry setObject:photo forKey:@"photo"];
    [photoEntry setObject:[photo objectForKey:FLICKR_PHOTO_TITLE] forKey:@"title"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *photoHistory = [defaults arrayForKey:@"photoHistory"];
    NSMutableArray *mutableHistory = [NSMutableArray arrayWithArray:photoHistory];
    [mutableHistory insertObject:photoEntry atIndex:0];
    while ([mutableHistory count] > 25)
        [mutableHistory removeLastObject];
    
    [defaults setObject:mutableHistory forKey:@"photoHistory"];
    [defaults synchronize];
}

+ (NSArray *)getPhotoHistory {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults arrayForKey:@"photoHistory"];
}

+ (void)resetPhotoHistory {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *photoHistory = [[NSArray alloc] init];
    [defaults setObject:photoHistory forKey:@"photoHistory"];
    [defaults synchronize];
}

- (IBAction)resetButtonTouched:(id)sender {
    [HistoryTableViewController resetPhotoHistory];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL) animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"HistoryTableViewCell" forIndexPath:indexPath];

    NSArray *photoHistory = [HistoryTableViewController getPhotoHistory];
    NSDictionary *photoEntry = photoHistory[indexPath.row];
    NSDictionary *photo = [photoEntry objectForKey:@"photo"];
    if ([photoHistory count] > indexPath.row) {
        cell.textLabel.text = [photo objectForKey:FLICKR_PHOTO_TITLE];
    }

    cell.detailTextLabel.text = [photo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *photoHistory = [HistoryTableViewController getPhotoHistory];
    return [photoHistory count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

#pragma mark - navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UITableViewCell *cell = sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSArray *photoHistory = [HistoryTableViewController getPhotoHistory];
    NSDictionary *photoEntry = photoHistory[indexPath.row];
    NSDictionary *photo = [photoEntry objectForKey:@"photo"];
    
    ImageViewController *controller = segue.destinationViewController;
    controller.photo = photo;
    controller.title = [photo objectForKey:FLICKR_PHOTO_TITLE];
}

@end
