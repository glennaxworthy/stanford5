//
//  HistoryTableViewController.h
//  Project5
//
//  Created by Glenn Axworthy on 11/2/15.
//  Copyright © 2015 Glenn Axworthy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HistoryTableViewController : UITableViewController

+ (void)addPhotoHistory:(NSDictionary *)photo;
+ (NSArray *)getPhotoHistory;
+ (void)resetPhotoHistory;

@end
