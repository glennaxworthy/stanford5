//
//  ImageViewController.m
//  Project5
//
//  Created by Glenn Axworthy on 10/28/15.
//  Copyright © 2015 Glenn Axworthy. All rights reserved.
//

#import "ImageViewController.h"
#import "FlickrFetcher.h"

@interface ImageViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation ImageViewController

- (void)resetScroll {

#if 1

    [self.imageView sizeToFit];

#else

    self.imageView.frame = CGRectMake(0, 0, self.image.size.width, self.image.size.height);

#endif

    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;;
    self.scrollView.minimumZoomScale = 0.5;
    self.scrollView.maximumZoomScale = 2.0;
    self.scrollView.zoomScale = 1.0;
}

- (void)setImage:(UIImage *)image {
    _image = image;
    
    if (self.imageView) { // viewDidLoad?
        [self.spinner stopAnimating];
        self.imageView.image = _image;
    }

    [self resetScroll];
}

- (void)setPhoto:(NSDictionary *)photo {
    _photo = photo;
    self.image = nil;
    [self.spinner startAnimating];

    NSURL *photoURL = [FlickrFetcher URLforPhoto:photo format:FlickrPhotoFormatLarge];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:photoURL];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                    completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                        NSData *data = [NSData dataWithContentsOfURL:location];
                                                        UIImage *image = [UIImage imageWithData:data];
                                                        [self performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
                                                    }];
    [task resume];    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.backgroundColor = [UIColor blueColor];
    [self.scrollView addSubview:self.imageView];
    self.scrollView.delegate = self;
    
    if (self.image)
        [self setImage:self.image];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

@end
