//
//  MainVC.m
//  BrainActivity
//
//  Created by Nero Wolfe on 12/04/15.
//  Copyright (c) 2015 Sergey Dikarev. All rights reserved.
//

#import "MainVC.h"

@interface MainVC ()

@end

@implementation MainVC
{
    CBManager *cbManager;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    cbManager = [[CBManager alloc] init];
    cbManager.delegate = self;
    // Do any additional setup after loading the view.
}

-(void)CB_changedStatus:(NSString *)statusMessage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.lblStatus.text = statusMessage;
    });
}


-(void)CB_fftDataUpdatedWithDictionary:(NSDictionary *)data
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fft_data_received" object:nil userInfo:data];
    
    if([data objectForKey:@"error"] != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lblStatus.text = [data objectForKey:@"error"];
        });
    }
    
}


-(void)CB_dataUpdatedWithDictionary:(NSDictionary *)data
{

    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"data_received" object:nil userInfo:data];
    
    if([data objectForKey:@"error"] != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lblStatus.text = [data objectForKey:@"error"];
        });
    }
    else
    {
        //process data
        
        
    }
    
}

- (IBAction)connectToDevice:(id)sender {
    
    [cbManager start];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)unwindBack:(UIStoryboardSegue *)unwindSegue
{
    
    [cbManager stop];
    
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
