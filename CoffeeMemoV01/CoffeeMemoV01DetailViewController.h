//
//  CoffeeMemoV01DetailViewController.h
//  CoffeeMemoV01
//
//  Created by Takashi Ikeda on 2014/05/08.
//  Copyright (c) 2014年 TI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CoffeeMemoV01DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
