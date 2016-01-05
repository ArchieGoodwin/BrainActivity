//
//  ViewController.h
//  BrainActivity
//
//  Created by Nero Wolfe on 08/02/15.
//  Copyright (c) 2015 Sergey Dikarev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CorePlot/ios/CorePlot.h>
#import "CBManager.h"

@interface ViewController : UIViewController <CPTPlotDataSource, CPTAxisDelegate>
@property (strong, nonatomic) IBOutlet UILabel *ampl1;
@property (strong, nonatomic) IBOutlet UILabel *ampl2;
@property (strong, nonatomic) IBOutlet CPTGraphHostingView *view3;
@property (strong, nonatomic) IBOutlet CPTGraphHostingView *view4;

@property (strong, nonatomic) IBOutlet CPTGraphHostingView *view1;
@property (strong, nonatomic) IBOutlet CPTGraphHostingView *view2;
@property (strong, nonatomic) IBOutlet UILabel *chnlTitle1;
@property (strong, nonatomic) IBOutlet UILabel *chnlTitle2;
@property (strong, nonatomic) IBOutlet UILabel *chnlTitle3;
@property (strong, nonatomic) IBOutlet UILabel *chnlTitle4;

@property (strong, nonatomic) IBOutlet UILabel *lblGreen;
@property (strong, nonatomic) IBOutlet UILabel *lblYellow;
@property (strong, nonatomic) IBOutlet UILabel *lblRed1;
@property (strong, nonatomic) IBOutlet UILabel *lblRed2;
@property (strong, nonatomic) IBOutlet UIStepper *zoom;
@property (strong, nonatomic) IBOutlet UISegmentedControl *chooseCannelSegment;

@property (strong, nonatomic) CBManager *manager;

-(void)defaultValues;
//- (void)sendData ;
@end

