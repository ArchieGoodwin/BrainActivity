//
//  CBCentralManagerViewController.h
//  CBTutorial
//
//  Created by Orlando Pereira on 10/8/13.
//  Copyright (c) 2013 Mobiletuts. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CBManagerDelegate;



@interface CBManager : NSObject

@property (nonatomic,strong) id <CBManagerDelegate> delegate;

@property (strong, nonatomic) NSMutableData *rawdata;
@property (strong, nonatomic) NSMutableArray *rawvalues;
@property (strong, nonatomic) NSMutableArray *fftData;
@property (strong, nonatomic) NSMutableArray *green;
@property (strong, nonatomic) NSMutableArray *yellow;
@property (strong, nonatomic) NSMutableArray *red1;
@property (strong, nonatomic) NSMutableArray *red2;

-(void)start;
-(void)stop;

@end

@protocol CBManagerDelegate <NSObject>


-(void)CB_dataUpdatedWithDictionary:(NSDictionary *)data;

@optional

-(void)CB_fftDataUpdatedWithDictionary:(NSDictionary *)data;
-(void)CB_changedStatus:(NSString *)statusMessage;

@end
