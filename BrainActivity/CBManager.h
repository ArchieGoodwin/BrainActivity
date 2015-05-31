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

@property (strong, nonatomic, readonly) NSMutableData *rawdata;
@property (strong, nonatomic, readonly) NSMutableArray *rawvalues;
@property (strong, nonatomic, readonly) NSMutableArray *fftData;

@property (nonatomic, assign, readonly) BOOL hasStarted;
@property (nonatomic, assign) double yellowFlagLow;
@property (nonatomic, assign) double yellowFlagHigh;
@property (nonatomic, assign) double red1Flag;
@property (nonatomic, assign) double red2Flag;


-(void)start;
-(void)stop;


-(BOOL)processGreenForChannel:(NSInteger)channel;
-(BOOL)processYellowForChannel:(NSInteger)channel;
-(BOOL)processRed1ForChannel:(NSInteger)channel;
-(BOOL)processRed2ForChannel:(NSInteger)channel;
@end

@protocol CBManagerDelegate <NSObject>


-(void)CB_dataUpdatedWithDictionary:(NSDictionary *)data;

@optional

-(void)CB_fftDataUpdatedWithDictionary:(NSDictionary *)data;
-(void)CB_changedStatus:(NSString *)statusMessage;

@end
