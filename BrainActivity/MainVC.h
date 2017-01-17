//
//  MainVC.h
//  BrainActivity
//
//  Created by Nero Wolfe on 12/04/15.
//  Copyright (c) 2015 Sergey Dikarev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CBBManager.h"
@interface MainVC : UIViewController <CBBManagerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *lblStatus;
@property (strong, nonatomic) IBOutlet UIButton *btnShowPlot;
@property (strong, nonatomic) IBOutlet UILabel *lblFreq;
@property (strong, nonatomic) IBOutlet UIButton *btnTest;
@property (strong, nonatomic) IBOutlet UILabel *lblBattery;

@end
