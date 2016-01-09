//
//  MainVC.m
//  BrainActivity
//
//  Created by Nero Wolfe on 12/04/15.
//  Copyright (c) 2015 Sergey Dikarev. All rights reserved.
//

#import "MainVC.h"
#import "ViewController.h"
#import <AFNetworking/AFNetworking.h>

@interface MainVC ()
{
    NSTimer *batterTimer;
}
@property (strong, nonatomic) IBOutlet UIButton *btnStart;


@end

@implementation MainVC
{
    CBManager *cbManager;
    ViewController *vc;
    float selectedFreq;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    cbManager = [[CBManager alloc] init];
    cbManager.delegate = self;
    
    selectedFreq = 3;
    _btnShowPlot.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _btnShowPlot.layer.borderWidth = 2.0;
    _btnStart.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _btnStart.layer.borderWidth = 2.0;
    _btnShowPlot.layer.cornerRadius = 15.0;
    _btnStart.layer.cornerRadius = 15.0;
    
    _btnTest.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _btnTest.layer.borderWidth = 2.0;
    _btnTest.layer.cornerRadius = 15.0;
    
    
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


-(void)CB_indicatorsStateWithDictionary:(NSDictionary *)data
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"indicators_data_received" object:nil userInfo:data];

    //NSLog(@"indicators: %@", data);
}

-(void)CB_dataUpdatedWithDictionary:(NSDictionary *)data
{

    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"data_received" object:nil userInfo:data];
    
    
}

- (IBAction)sendDataAction:(id)sender {
    
    if(cbManager.hasStarted)
    {
        //[self sendData];
    }
}

- (IBAction)stepperChanged:(id)sender {
    
    UIStepper *step = (UIStepper *)sender;
    
    selectedFreq = step.value;
    
    _lblFreq.text = [NSString stringWithFormat:@"%li", (long)selectedFreq];
}

- (IBAction)startTest:(id)sender {
    if(cbManager.hasStarted)
    {
        if(vc)
        {
            [vc defaultValues];
        }
        
        [cbManager stop];
        
        cbManager = [[CBManager alloc] init];
        cbManager.delegate = self;
        
        [_btnTest setTitle:@"Start test" forState:UIControlStateNormal];
        
    }
    else
    {
        [cbManager startTestSequenceWithDominantFrequence:selectedFreq];
        [_btnTest setTitle:@"Stop" forState:UIControlStateNormal];
        
    }
}

- (IBAction)connectToDevice:(id)sender {
    

    
    if(cbManager.hasStarted)
    {
        [batterTimer invalidate];
        batterTimer = nil;
        
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
        [self batteryShow];
        batterTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(batteryShow) userInfo:nil repeats:YES];

        
    }
    
    
    
}


-(void)batteryShow
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _lblBattery.text = [NSString stringWithFormat:@"Battery: %li%", (long)cbManager.batteryLevel];
        
    });
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
        [_btnTest setTitle:@"Start test" forState:UIControlStateNormal];

    }
    else
    {
        [_btnStart setTitle:@"Stop" forState:UIControlStateNormal];
        [_btnTest setTitle:@"Stop" forState:UIControlStateNormal];

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

#pragma mark -
#pragma mark Networking

/*- (void)sendData {
    
    AFHTTPRequestOperationManager *nManager = [AFHTTPRequestOperationManager manager];
    nManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    nManager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    [nManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //nManager.securityPolicy.allowInvalidCertificates = YES;
    
    
    NSString *URLString = [NSString stringWithFormat:@"http://potbot.elasticbeanstalk.com/api/eegSamples"];
    NSDictionary *params = @{@"deviceId": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                             @"eegIndexes": cbManager.rawvalues, @"eegSpectrums" : cbManager.fftData};
    
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    
    NSLog(@"%@", jsonString);
    
    
    [nManager POST:URLString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
}*/



@end
