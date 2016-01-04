//
//  CBCentralManagerViewController.h
//  CBTutorial
//
//  Created by Orlando Pereira on 10/8/13.
//  Copyright (c) 2013 Mobiletuts. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CBManagerDelegate;

typedef enum CBManagerMessage {
    CBManagerMessage_ScanningStarted = 0,
    CBManagerMessage_ScanningStopped = 1,
    CBManagerMessage_ConnectingToPeripheral = 2,
    CBManagerMessage_ConnectToPeripheralFailed = 3,
    CBManagerMessage_ConnectToPeripheralSuccessful = 4,
    CBManagerMessage_ConnectingToService = 5,
    CBManagerMessage_ConnectToServiceFailed = 6,
    CBManagerMessage_ConnectToServiceSuccessful = 7,
    CBManagerMessage_DataTransferStarted = 8,
    CBManagerMessage_DataTransferAborted = 9,
    CBManagerMessage_DataTransferError = 10,
    CBManagerMessage_CharacteristicDiscovered = 11,
    CBManagerMessage_CharacteristicDiscoveringFailed = 12,
    CBManagerMessage_Ready = 13,
    CBManagerMessage_UnknownError = 14,
    CBManagerMessage_PeripheralDisconnected = 15,

}
CBManagerMessage;


typedef enum CBManagerActivityZone {
    CBManagerActivityZone_Relaxation = 0,
    CBManagerActivityZone_HighRelaxation = 1,
    CBManagerActivityZone_Dream = 2,
    CBManagerActivityZone_NormalActivity = 3,
    CBManagerActivityZone_Agitation = 4,
    CBManagerActivityZone_HighAgitation = 5
}
CBManagerActivityZone;

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
@property (nonatomic, assign, readonly) BOOL hasStartedIndicators;
@property (nonatomic, assign, readonly) BOOL hasStartedProcessBasicValues;

-(void)start;
-(void)stop;
-(void)startTestSequenceWithDominantFrequence:(float)frequence;

-(NSInteger)batteryLevel;
@end

@protocol CBManagerDelegate <NSObject>


-(void)CB_dataUpdatedWithDictionary:(NSDictionary *)data;

@optional

-(void)CB_fftDataUpdatedWithDictionary:(NSDictionary *)data;
-(void)CB_changedStatus:(CBManagerMessage)status message:(NSString *)statusMessage;
-(void)CB_indicatorsStateWithDictionary:(NSDictionary *)data;

@end
