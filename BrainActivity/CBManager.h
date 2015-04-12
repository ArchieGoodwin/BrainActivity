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



-(void)start;
-(void)stop;

@end

@protocol CBManagerDelegate <NSObject>
@optional

-(void)CB_changedStatus:(NSString *)statusMessage;
-(void)CB_dataUpdatedWithDictionary:(NSDictionary *)data;

@end
