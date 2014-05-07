//
//  CoffeeMemoV01DetailViewController.m
//  CoffeeMemoV01
//
//  Created by Takashi Ikeda on 2014/05/08.
//  Copyright (c) 2014年 TI. All rights reserved.
//

#import "CoffeeMemoV01DetailViewController.h"

@interface CoffeeMemoV01DetailViewController ()
- (void)configureView;
@end

@implementation CoffeeMemoV01DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        self.detailDescriptionLabel.text = [self.detailItem description];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
