//
//  MainVC.m
//  BrainActivity
//
//  Created by Nero Wolfe on 12/04/15.
//  Copyright (c) 2015 Sergey Dikarev. All rights reserved.
//

#import "MainVC.h"
#import "ViewController.h"
@interface MainVC ()
@property (strong, nonatomic) IBOutlet UIButton *btnStart;


@end

@implementation MainVC
{
    CBManager *cbManager;
    ViewController *vc;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    cbManager = [[CBManager alloc] init];
    cbManager.delegate = self;
    
    
    _btnShowPlot.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _btnShowPlot.layer.borderWidth = 2.0;
    _btnStart.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _btnStart.layer.borderWidth = 2.0;
    _btnShowPlot.layer.cornerRadius = 15.0;
    _btnStart.layer.cornerRadius = 15.0;
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    // Do any additional setup after loading the view.
}


-(void)CB_changedStatus:(CBManagerMessage)status message:(NSString *)statusMessage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.lblStatus.text = statusMessage;
    });
}



-(void)CB_fftDataUpdatedWithDictionary:(NSDictionary *)data
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fft_data_received" object:nil userInfo:data];
    
    
}


-(void)CB_dataUpdatedWithDictionary:(NSDictionary *)data
{

    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"data_received" object:nil userInfo:data];
    
    
}

- (IBAction)sendDataAction:(id)sender {
    
    if(vc && cbManager.hasStarted)
    {
        [vc sendData];
    }
}

- (IBAction)connectToDevice:(id)sender {
    

    
    if(cbManager.hasStarted)
    {
        if(vc)
        {
            [vc defaultValues];
        }
        
        [cbManager stop];
        
        cbManager = [[CBManager alloc] init];
        cbManager.delegate = self;
        
        [_btnStart setTitle:@"Connect to device" forState:UIControlStateNormal];
        
    }
    else
    {
        [cbManager start];
        [_btnStart setTitle:@"Stop" forState:UIControlStateNormal];
        
    }
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)unwindBack:(UIStoryboardSegue *)unwindSegue
{
    
    if(!cbManager.hasStarted)
    {
        [_btnStart setTitle:@"Connect to device" forState:UIControlStateNormal];
    }
    else
    {
        [_btnStart setTitle:@"Stop" forState:UIControlStateNormal];
        
    }

    //[cbManager stop];
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"showPlot"])
    {
        
        vc = (ViewController *)segue.destinationViewController;
        vc.manager = cbManager;
        
    }
    
}


@end
