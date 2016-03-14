//
//  CBCentralManagerViewController.m
//  CBTutorial
//
//  Created by Orlando Pereira on 10/8/13.
//  Copyright (c) 2013 Mobiletuts. All rights reserved.
//

#import "CBManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#include <stdio.h>
#include <stdlib.h>
#include <Accelerate/Accelerate.h>
#import "SERVICES.h"

const double VRef = 2.4 / 6.0 / 32.0;
const double K = 1000000000 * VRef / 0x7FFF;

const double GROUP_2_LOW_LEVEL = 22000;
const double GROUP_2_HIGH_LEVEL = 6000;

const double timeSpan = 180.0;
const NSInteger step = 10;

const NSInteger INDICATOR_PERIOD = 5;
const NSInteger BASIC_VALUES_PERIOD = 10;

@interface CBManager() < CBCentralManagerDelegate, CBPeripheralDelegate>


@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;

//raw data counter
@property (nonatomic, assign) NSInteger counter;

//fft data counter
@property (nonatomic, assign) NSInteger fftCounter;

@end

@implementation CBManager
{
    NSInteger lastGreenValue;
    double lastGreenAverage;
    double yellowDiffLow;
    double yellowDiffHigh;
    double red1DiffHigh;
    double red2DiffHigh;
    float testDominantFreq;
    CBCharacteristic *currentCharacteristic;
    CBCharacteristic *currentbatteryCharacteristic;

    NSTimer *timer;
    NSTimer *indicatorTimer;
    
    NSArray *averageBasicTeta;
    NSArray *averageBasicAlpha;
    NSArray *averageBasicBeta;
    
   
    NSMutableArray *basicValues;

}

#pragma mark -
#pragma mark Core Bluetooth methods

-(id)init
{
    if ((self = [super init])) {
        _counter = 0;
        _fftCounter = 0;
        _hasStarted = NO;
        lastGreenValue = 0;
        lastGreenAverage = 0.0;
        _hasStartedIndicators = NO;
        _hasStartedProcessBasicValues = NO;
        basicValues = [NSMutableArray new];
    }
    
    return self;

}

//start connect and proceccing data from device
-(void)start
{
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _rawdata = [[NSMutableData alloc] init];
    _rawvalues = [NSMutableArray new];
    _fftData = [NSMutableArray new];
    _counter = 0;
    _fftCounter = 0;
    _hasStarted = YES;
    _hasStartedProcessBasicValues = NO;

}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    // You should test all scenarios
    if (central.state != CBCentralManagerStatePoweredOn) {
        [self stop];
        return;
    }
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        // Scan for devices
        [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
        NSLog(@"Scanning started");
        
        if(_delegate)
        {
            if([_delegate respondsToSelector:@selector(CB_changedStatus:message:)])
            {
                [_delegate CB_changedStatus:CBManagerMessage_ScanningStarted message:@"Scanning started"];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    if (_discoveredPeripheral != peripheral) {
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        _discoveredPeripheral = peripheral;
        
        
               
        // And connect
        NSLog(@"Connecting to peripheral %@", peripheral);
        
        if(_delegate)
        {
            if([_delegate respondsToSelector:@selector(CB_changedStatus:message:)])
            {
                [_delegate CB_changedStatus:CBManagerMessage_ConnectingToPeripheral message:[NSString stringWithFormat:@"Connecting to peripheral %@", peripheral]];
            }
        }
        
        [_centralManager connectPeripheral:peripheral options:nil];

    }
}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect");
    
    if(_delegate)
    {
        if([_delegate respondsToSelector:@selector(CB_changedStatus:message:)])
        {
            [_delegate CB_changedStatus:CBManagerMessage_CharacteristicDiscoveringFailed message:[NSString stringWithFormat:@"Failed to connect: %@", error.localizedDescription]];
        }
    }
    [self stop];
    [self cleanup];
}

- (void)cleanup {
    
    // See if we are subscribed to a characteristic on the peripheral
    if (_discoveredPeripheral.services != nil) {
        for (CBService *service in _discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
                        if (characteristic.isNotifying) {
                            [_discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            if( _discoveredPeripheral)
                            {
                                [_centralManager cancelPeripheralConnection:_discoveredPeripheral];
                                
                            }
                            return;
                        }
                    }
                }
            }
        }
    }
   
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected");
    
    if(_delegate)
    {
        if([_delegate respondsToSelector:@selector(CB_changedStatus:message:)])
        {
            [_delegate CB_changedStatus:CBManagerMessage_ConnectToPeripheralSuccessful message:[NSString stringWithFormat:@"Peripheral connected"]];
        }
    }
    
    [_centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    
    [_rawdata setLength:0];
    
    peripheral.delegate = self;
    
    
    
    [peripheral discoverServices:nil];//@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        [self stop];
        if(_delegate)
        {
            if([_delegate respondsToSelector:@selector(CB_changedStatus:message:)])
            {
                [_delegate CB_changedStatus:CBManagerMessage_ConnectToServiceFailed message:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
            }
        }
        return;
    }
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
    // Discover other characteristics
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        [self stop];
        
        if(_delegate)
        {
            if([_delegate respondsToSelector:@selector(CB_changedStatus:message:)])
            {
                [_delegate CB_changedStatus:CBManagerMessage_CharacteristicDiscoveringFailed message:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
            }
        }
        
        
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        NSLog(@"characteristic.UUID %@",characteristic.UUID);

        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
            
            if(_delegate)
            {
                if([_delegate respondsToSelector:@selector(CB_changedStatus:message:)])
                {
                    [_delegate CB_changedStatus:CBManagerMessage_DataTransferStarted message:[NSString stringWithFormat:@"Data transfer started"]];
                }
            }
            
            currentCharacteristic = characteristic;
            
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        if ([[NSString stringWithFormat:@"%@", characteristic.UUID] isEqualToString:@"Battery Level"]) {
            
            
            currentbatteryCharacteristic = characteristic;
            [peripheral readValueForCharacteristic:currentbatteryCharacteristic];
            
            [self batteryLevel];

            [peripheral setNotifyValue:YES forCharacteristic:currentbatteryCharacteristic];
        }
    }
}

- (int) intFromData:(NSData *)data
{
    int intSize = sizeof(2); // change it to fixe length
    unsigned char * buffer = malloc(intSize * sizeof(signed char));
    [data getBytes:buffer length:intSize];
    int num = 0;
    for (int i = 0; i < intSize; i++) {
        num =  buffer[i] + (num << 8);
    }
    free(buffer);
    return num;
}


- (int) intFromDataReverse:(NSData *)data
{
    int intSize = sizeof(2);// change it to fixe length
    unsigned char * buffer = malloc(intSize * sizeof(unsigned char));
    [data getBytes:buffer length:intSize];
    int num = 0;
    for (int i = intSize - 1; i >= 0; i--) {
        num = (num << 8) + buffer[i];
    }
    free(buffer);
    return num;
}


-(NSDictionary *)makeReturnDictionary:(NSData *)data channel:(NSInteger)channel
{

    if(data)
    {
        if(channel == 1)
        {
            NSData *subdata = [data subdataWithRange:NSMakeRange(0, 2)];
            short orderNumber = 0;
            [subdata getBytes:&orderNumber length:2];
            orderNumber = CFSwapInt16BigToHost(orderNumber);
            
            //double d = 100000*sin(2*M_PI*10*_counter/250);
            
            //first 4 channels
            subdata = [data subdataWithRange:NSMakeRange(3, 2)];
            short channel1 = 0;
            [subdata getBytes:&channel1 length:2];
            channel1 = CFSwapInt16BigToHost(channel1);
            
            subdata = [data subdataWithRange:NSMakeRange(5, 2)];
            short channel2 = 0;
            [subdata getBytes:&channel2 length:2];
            channel2 = CFSwapInt16BigToHost(channel2);
            
            subdata = [data subdataWithRange:NSMakeRange(7, 2)];
            short channel3 = 0;
            [subdata getBytes:&channel3 length:2];
            channel3 = CFSwapInt16BigToHost(channel3);
            
            subdata = [data subdataWithRange:NSMakeRange(9, 2)];
            short channel4 = 0;
            [subdata getBytes:&channel4 length:2];
            channel4 = CFSwapInt16BigToHost(channel4);
            
            
            
            NSDictionary *ret = @{@"counter" : [NSNumber numberWithInteger:_counter],@"timeframe" : [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000000], @"hardware_order_number" : [NSNumber numberWithShort:orderNumber], @"ch1" : [NSNumber numberWithDouble:floor(channel1 * K)], @"ch2" : [NSNumber numberWithDouble:floor(channel2 * K)], @"ch3" : [NSNumber numberWithDouble:floor(channel3 * K)], @"ch4" : [NSNumber numberWithDouble:floor(channel4 * K)]};
            
            
            NSLog(@"%@", ret);
            
            [_rawvalues addObject:ret];
            
            return ret;
            
        }
        
        
        if(channel == 2)
        {
            
            NSData *subdata = [data subdataWithRange:NSMakeRange(0, 2)];
            short orderNumber = 0;
            [subdata getBytes:&orderNumber length:2];
            orderNumber = CFSwapInt16BigToHost(orderNumber);
            
            //double d = 100000*sin(2*M_PI*10*(_counter + 1)/250);
            
            //another 4 channels
            subdata = [data subdataWithRange:NSMakeRange(12, 2)];
            short channel1_ = 0;
            [subdata getBytes:&channel1_ length:2];
            channel1_ = CFSwapInt16BigToHost(channel1_);
            
            subdata = [data subdataWithRange:NSMakeRange(14, 2)];
            short channel2_ = 0;
            [subdata getBytes:&channel2_ length:2];
            channel2_ = CFSwapInt16BigToHost(channel2_);
            
            subdata = [data subdataWithRange:NSMakeRange(16, 2)];
            short channel3_ = 0;
            [subdata getBytes:&channel3_ length:2];
            channel3_ = CFSwapInt16BigToHost(channel3_);
            
            subdata = [data subdataWithRange:NSMakeRange(18, 2)];
            short channel4_ = 0;
            [subdata getBytes:&channel4_ length:2];
            channel4_ = CFSwapInt16BigToHost(channel4_);
            
            
            NSDictionary *ret = @{@"counter" : [NSNumber numberWithInteger:_counter], @"timeframe" : [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000000], @"hardware_order_number" : [NSNumber numberWithShort:orderNumber + 1], @"ch1" : [NSNumber numberWithDouble:floor(channel1_ * K)], @"ch2" : [NSNumber numberWithDouble:floor(channel2_ * K)], @"ch3" : [NSNumber numberWithDouble:floor(channel3_ * K)], @"ch4" : [NSNumber numberWithDouble:floor(channel4_ * K)]};
            
            NSLog(@"%@", ret);
            
            [_rawvalues addObject:ret];
            
            return ret;
            
        }
    }
    else
    {
        if(channel == 1)
        {

            short orderNumber = _counter;
            
            double d = 100000*sin(2*M_PI*testDominantFreq*_counter/250);
            //double channel1 = d * ([self randomFloatBetween:0.6 and:1.5]);
            //double channel2 = d* ([self randomFloatBetween:0.6 and:1.5]);
            //double channel3 = d* ([self randomFloatBetween:0.7 and:1.5]);
            //double channel4 = d* ([self randomFloatBetween:0.7 and:1.5]);
            
            if(!_hasStartedIndicators)
            {
                d = 1000 * (50 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 20 * sin(2*M_PI*18*_counter/250));
                
            }
            else
            {
                //d = 1000 * (36 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 19 * sin(2*M_PI*18*_counter/250)); //green 1
                //d = 1000 * (64 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 21 * sin(2*M_PI*18*_counter/250)); //green 2
                //d = 1000 * (75 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 23 * sin(2*M_PI*18*_counter/250)); //green 3
                //d = 95 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 30 * sin(2*M_PI*18*_counter/250); //green 4
                
                //d = 1000 * (75 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 16 * sin(2*M_PI*18*_counter/250)); //yellow 1
                //d = 1000 * (40 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 16 * sin(2*M_PI*18*_counter/250)); //yellow 2
                
                d = 1000 * (25 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 21 * sin(2*M_PI*18*_counter/250)); //red

                //d = 1000 * (90 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 16 * sin(2*M_PI*18*_counter/250)); //orange

            }
            double channel1 = d;
            double channel2 = d;
            double channel3 = d;
            double channel4 = d;
            
            NSDictionary *ret = @{@"counter" : [NSNumber numberWithInteger:_counter],@"timeframe" : [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000000], @"hardware_order_number" : [NSNumber numberWithShort:orderNumber], @"ch1" : [NSNumber numberWithDouble:channel1], @"ch2" : [NSNumber numberWithDouble:channel2], @"ch3" : [NSNumber numberWithDouble:channel3], @"ch4" : [NSNumber numberWithDouble:channel4]};
            
            
            //NSLog(@"%@", ret);
            
            [_rawvalues addObject:ret];
            
            return ret;
            
        }
        
        
        if(channel == 2)
        {
            
            short orderNumber = _counter;
            
            double d = 100000*sin(2*M_PI*testDominantFreq*_counter/250);
            //double channel1_ = d* ([self randomFloatBetween:0.6 and:1.5]);
            //double channel2_ = d* ([self randomFloatBetween:0.6 and:1.5]);
            //double channel3_ = d* ([self randomFloatBetween:0.7 and:1.7]);
            //double channel4_ = d* ([self randomFloatBetween:0.7 and:1.7]);
            
            if(!_hasStartedIndicators)
            {
                d = 1000*(50 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 20 * sin(2*M_PI*18*_counter/250));
                
            }
            else
            {
                //d = 1000 * (36 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 19 * sin(2*M_PI*18*_counter/250)); //green 1
                //d = 1000 * (64 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 21 * sin(2*M_PI*18*_counter/250)); //green 2
                //d = 1000 * (75 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 23 * sin(2*M_PI*18*_counter/250)); //green 3
                //d = 95 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 30 * sin(2*M_PI*18*_counter/250); //green 4
                
                //d = 1000 * (75 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 16 * sin(2*M_PI*18*_counter/250)); //yellow 1
                //d = 1000 * (40 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 16 * sin(2*M_PI*18*_counter/250)); //yellow 2

                d = 1000 * (25 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 21 * sin(2*M_PI*18*_counter/250)); //red
                
                //d = 1000 * (90 * (sin(2*M_PI*5*_counter/250) + sin(2*M_PI*10*_counter/250)) + 16 * sin(2*M_PI*18*_counter/250)); //orange


            }
            double channel1_ = d;
            double channel2_ = d;
            double channel3_ = d;
            double channel4_ = d;
            
            NSDictionary *ret = @{@"counter" : [NSNumber numberWithInteger:_counter], @"timeframe" : [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000000], @"hardware_order_number" : [NSNumber numberWithShort:orderNumber + 1], @"ch1" : [NSNumber numberWithDouble:channel1_], @"ch2" : [NSNumber numberWithDouble:channel2_], @"ch3" : [NSNumber numberWithDouble:channel3_], @"ch4" : [NSNumber numberWithDouble:channel4_]};
            
            //NSLog(@"%@", ret);
            
            [_rawvalues addObject:ret];
            
            return ret;
            
        }
    }
    
    
    
    
    return nil;
    
}

- (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error");
        
        if(_delegate)
        {
            if([_delegate respondsToSelector:@selector(CB_changedStatus:message:)])
            {
                [_delegate CB_changedStatus:CBManagerMessage_DataTransferError message:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
            }
        }
        
        [self stop];
        
        return;
    }
    //NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    //NSLog(@"%@", characteristic.value);

    
   
    // Have we got everything we need?
    /*if ([stringFromData isEqualToString:@"EOM"]) {
        
        [_textview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
        
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        [_centralManager cancelPeripheralConnection:peripheral];
    }*/
    if(characteristic == currentCharacteristic)
    {
        if(_delegate)
        {
            
            if([_delegate respondsToSelector:@selector(CB_dataUpdatedWithDictionary:)])
            {
                
                [_delegate CB_dataUpdatedWithDictionary:[self makeReturnDictionary:characteristic.value channel:1]];
                
                _counter++;
                
                [_delegate CB_dataUpdatedWithDictionary:[self makeReturnDictionary:characteristic.value channel:2]];
                
                _counter++;
                
                if(_counter % 250 == 0)
                {
                    NSDictionary *ret = [self fillFFTData:NSMakeRange(_counter - 250, 256)];
                    if([_delegate respondsToSelector:@selector(CB_fftDataUpdatedWithDictionary:)])
                    {
                        [_delegate CB_fftDataUpdatedWithDictionary:ret];
                    }
                }
                
                if((_counter % (INDICATOR_PERIOD * 250)) == 0 && _fftCounter > 0)
                {
                    if(_hasStartedIndicators)
                    {
                        NSDictionary *ret = [self indicatorsState];
                        if([_delegate respondsToSelector:@selector(CB_indicatorsStateWithDictionary:)])
                        {
                            [_delegate CB_indicatorsStateWithDictionary:ret];
                        }
                    }
                }
            }
            
        }
        
        
        [_rawdata appendData:characteristic.value];
    }
    else if(characteristic == currentbatteryCharacteristic)
    {
        
        
        UInt8 batteryLevel;
        [currentbatteryCharacteristic.value getBytes:&batteryLevel length:1];
        NSLog(@"battery level %i", batteryLevel);
    }
   
}


-(void)startTestSequenceWithDominantFrequence:(float)frequence
{
    //yellowDiffLow = _yellowFlagLow / (timeSpan / step);
    //yellowDiffHigh = _yellowFlagHigh / (timeSpan / step);
    //red1DiffHigh = _red1Flag / (timeSpan / step);
    //red2DiffHigh = _red2Flag / (timeSpan / step);
    
    
    //_centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _rawdata = [[NSMutableData alloc] init];
    _rawvalues = [NSMutableArray new];
    _fftData = [NSMutableArray new];
    _counter = 0;
    _fftCounter = 0;
    _hasStarted = YES;
    testDominantFreq = frequence;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/250.0 target:self selector:@selector(randomData) userInfo:nil repeats:YES];
    [timer fire];
    
}

-(void)randomData
{
    if(_delegate)
    {
        
        if([_delegate respondsToSelector:@selector(CB_dataUpdatedWithDictionary:)])
        {
            
            [_delegate CB_dataUpdatedWithDictionary:[self makeReturnDictionary:nil channel:1]];
            
            _counter++;
            
            [_delegate CB_dataUpdatedWithDictionary:[self makeReturnDictionary:nil channel:2]];
            
            _counter++;
            
            if(_counter % 250 == 0)
            {
                
                NSDictionary *ret = [self fillFFTData:NSMakeRange(_counter - 250, 256)];
                if([_delegate respondsToSelector:@selector(CB_fftDataUpdatedWithDictionary:)])
                {
                    [_delegate CB_fftDataUpdatedWithDictionary:ret];
                }
                
            }
            if(_counter % (INDICATOR_PERIOD * 250) == 0 && _fftCounter > 0)
            {
                if(_hasStartedIndicators)
                {

                    NSDictionary *ret = [self indicatorsState];
                    if([_delegate respondsToSelector:@selector(CB_indicatorsStateWithDictionary:)])
                    {
                        [_delegate CB_indicatorsStateWithDictionary:ret];
                    }
                }
            }
            
        }
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
        return;
    }
    
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    } else {
        // Notification has stopped
        [_centralManager cancelPeripheralConnection:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    _discoveredPeripheral = nil;
    
    if(_delegate)
    {
        if([_delegate respondsToSelector:@selector(CB_changedStatus:message:)])
        {
            [_delegate CB_changedStatus:CBManagerMessage_PeripheralDisconnected message:@"Device disconnected!"];
        }
    }

    [self stop];
    
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning!" message:@"App lost connection to device!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    //[alert show];
    
   // [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

-(void)stop
{

    [_rawdata setLength:0];
    _hasStarted = NO;
    _rawvalues = [NSMutableArray new];
    _fftData = [NSMutableArray new];
    _counter = 0;
    _fftCounter = 0;
    
    if( _discoveredPeripheral && currentCharacteristic)
    {
        
        [_discoveredPeripheral setNotifyValue:NO forCharacteristic:currentCharacteristic];

        [_centralManager cancelPeripheralConnection:_discoveredPeripheral];
        
    }
    
    if(_centralManager)
    {
        [_centralManager stopScan];

    }
    
    
    [self cleanup];
    
    
    if(timer)
    {
        [timer invalidate];
        timer = nil;
    }
    
    if(indicatorTimer)
    {
        [indicatorTimer invalidate];
        indicatorTimer = nil;
    }
    
    _centralManager = nil;
    
    if(_delegate)
    {
        if([_delegate respondsToSelector:@selector(CB_changedStatus:message:)])
        {
            [_delegate CB_changedStatus:CBManagerMessage_Ready message:@"Ready to scan"];
        }
    }

}

#pragma mark -
#pragma mark FFT

-(NSDictionary *)fft:(double *)inp channel:(NSInteger)channel
{
    //[self testFFT];
    
    const int log2n = log2f(256);
    //const int n = 1 << log2n;
    const int nOver2 = 128;
    
    FFTSetupD fftSetup = vDSP_create_fftsetupD (log2n, kFFTRadix2);
    
    DSPDoubleSplitComplex fft_data;
    
    fft_data.realp = malloc(nOver2 * sizeof(double));
    fft_data.imagp = malloc(nOver2 * sizeof(double));
    
    
    vDSP_ctozD((DSPDoubleComplex *)inp, 2, &fft_data, 1, nOver2);
    
    
    vDSP_fft_zripD (fftSetup, &fft_data, 1, log2n, kFFTDirection_Forward);
    
    
    double *output = (double *)malloc(nOver2 * sizeof(double));
    for (int i = 0; i < nOver2; ++i)
    {
        output[i] = sqrt(fft_data.realp[i]*fft_data.realp[i] + fft_data.imagp[i]*fft_data.imagp[i]);
        //NSLog(@"%i %f",i, output[i]);
    }
  
    /*double *frequences = (double *)malloc(nOver2 * sizeof(double));
    for (int i = 0; i < nOver2; ++i)
    {
        
        double freq = i * 25.0 / nOver2;
        frequences[i] = freq;
        
        //NSLog(@"%f", frequences[i]);
        
    }*/
    
    int val1 = [self findMaxIndex:output range:NSMakeRange(3, 4)];
    double val1_ = [self findMaxValue:output range:NSMakeRange(3, 4)];
    //printf("max in 3-6: %8g  %f  max index: %d \n", frequences[val1], output[val1], val1);
    
    
    int val2 = [self findMaxIndex:output range:NSMakeRange(7, 7)];
    double val2_ = [self findMaxValue:output range:NSMakeRange(7, 7)];
    //printf("max in 7-13: %8g  %f  max index: %d \n", frequences[val2], output[val2], val2);
    
    
    int val3 = [self findMaxIndex:output range:NSMakeRange(14, 11)];
    double val3_ = [self findMaxValue:output range:NSMakeRange(14, 11)];
    //printf("max in 14-18: %8g  %f  max index: %d \n", frequences[val3], output[val3], val3);
   
    BOOL signalClear = [self checkIfSignalIsClear:channel averageLow:val1_/1000.0 averageAlpha:val2_/1000.0 averageHigh:val3_/1000.0];
    if(_hasStartedProcessBasicValues && !_hasStartedIndicators)
    {
        signalClear = YES;
    }
    NSLog(@"%d   %d", _hasStartedProcessBasicValues, _hasStartedIndicators);
    return signalClear ? @{@"data1" : [NSNumber numberWithDouble:val1], @"data2" : [NSNumber numberWithDouble:val2], @"data3" : [NSNumber numberWithDouble:val3], @"data1_" : [NSNumber numberWithDouble:val1_], @"data2_" : [NSNumber numberWithDouble:val2_], @"data3_" : [NSNumber numberWithDouble:val3_]} : @{@"signal" : @"low quality"};
    
    
}


-(NSDictionary *)fillFFTData:(NSRange)range
{
    
    double *farray1 = malloc(sizeof(double) * range.length);
    double *farray2 = malloc(sizeof(double) * range.length);
    double *farray3 = malloc(sizeof(double) * range.length);
    double *farray4 = malloc(sizeof(double) * range.length);
    
    for(NSInteger i = 0; i < range.length; i++)
    {
        
        if( i < 250)
        {
            NSDictionary *val = _rawvalues[i + range.location];
            
            farray1[i] = [val[@"ch1"] doubleValue];
            farray2[i] = [val[@"ch2"] doubleValue];
            farray3[i] = [val[@"ch3"] doubleValue];
            farray4[i] = [val[@"ch4"] doubleValue];
        }
        else
        {
            
            farray1[i] = 0.0;
            farray2[i] = 0.0;
            farray3[i] = 0.0;
            farray4[i] = 0.0;
        }
        
    }
    
    NSDictionary *fftData1 = [self fft:farray1 channel:1];
    NSDictionary *fftData2 = [self fft:farray2 channel:2];
    NSDictionary *fftData3 = [self fft:farray3 channel:3];
    NSDictionary *fftData4 = [self fft:farray4 channel:4];

    
    NSDictionary *ret = @{@"counter" : [NSNumber numberWithInteger:_fftCounter], @"ch1" : fftData1, @"ch2" : fftData2, @"ch3" : fftData3, @"ch4" : fftData4, @"timeframe" : [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000000]};
    
    [_fftData addObject:ret];
    
    _fftCounter++;

    return ret;
    
  
}

-(int)findMaxIndex:(double *)array  range:(NSRange)range{
    
    int returnI = (int)range.location;
    
    double *subArray = (double *)malloc(range.length * sizeof(double));
    
    for(int i = 0; i<range.length; i++)
    {
        subArray[i] = array[range.location + i];
        //NSLog(@"subarr %f", subArray[i]);
    }
    
    double max = subArray[0];
    for (int i = 1; i < range.length; i++) {
        if(max<subArray[i])
        {
            max=subArray[i];
            returnI = (int)range.location + i;
        }
    }
    return returnI;
}

-(double)findMaxValue:(double *)array range:(NSRange)range{
    
    double *subArray = (double *)malloc(range.length * sizeof(double));
    
    for(int i = 0; i<range.length; i++)
    {
        subArray[i] = array[range.location + i];
        //NSLog(@"subarr %f", subArray[i]);
    }
    
    double max = subArray[0];
    for (int i = 1; i < range.length; i++) {

        max= max + subArray[i];
        /*if(max<subArray[i])
        {
            max=subArray[i];
        }*/
    }
    
    return max / range.length;
}

-(BOOL)checkIfSignalIsClear:(NSInteger)channel averageLow:(double)averageLow  averageAlpha:(double)averageAlpha averageHigh:(double)averageHigh
{
    double lowLevel = GROUP_2_LOW_LEVEL;
    double highLevel = GROUP_2_HIGH_LEVEL;
    return (averageLow < lowLevel) && (averageHigh < highLevel && (averageHigh < averageLow || averageHigh < averageAlpha));
    
    
    return YES;
}


-(double)findMax:array arrayKey:obj {
    
    double max = [[[array objectAtIndex:0] objectForKey:obj] doubleValue];
    for ( NSDictionary *dict in array ) {
        if(max<[[dict objectForKey:obj] doubleValue])
            max=[[dict objectForKey:obj] doubleValue];
    }
    return max;
}



-(float)findMin:array arrayKey:obj {
    float min = [[[array objectAtIndex:0] objectForKey:obj] floatValue];
    for ( NSDictionary *dict in array ) {
        if (min > [[dict objectForKey:obj] floatValue])min = [[dict objectForKey:obj] floatValue];
    }
    return min;
}

-(float)findAmplitude:(NSArray *)arr
{
    float amplitude = 0;
    for (int j = 0; j < (arr.count -1); j = j +2 ){
        
        if (fabsf(((NSString *)arr[j]).floatValue) > fabsf(((NSString *)arr[j+1]).floatValue))
            amplitude = amplitude + fabsf(((NSString *)arr[j]).floatValue) - fabsf(((NSString *)arr[j+1]).floatValue);
        else amplitude = amplitude + fabsf(((NSString *)arr[j + 1]).floatValue) - fabsf(((NSString *)arr[j]).floatValue);
        
        
    }
    amplitude = fabsf(amplitude / arr.count * 2);
    
    return amplitude;
}



#pragma mark -
#pragma mark Indicators


-(void)startProcessAverageValues
{
    //NSLog(@"%li", _counter / 250);
    //NSLog(@"%li", BASIC_VALUES_PERIOD);
    if(BASIC_VALUES_PERIOD < (_counter / (timer == nil ? 250 : 250)))
    {
        
        [self performSelector:@selector(startIndicatorsProcessing) withObject:nil afterDelay:BASIC_VALUES_PERIOD];
        
        //indicatorTimer = [NSTimer scheduledTimerWithTimeInterval:BASIC_VALUES_PERIOD target:self selector:@selector(startIndicatorsProcessing) userInfo:nil repeats:NO];
        //[indicatorTimer fire];
        _hasStartedProcessBasicValues = YES;
    }
   
}

-(void)startIndicatorsProcessing
{
    NSArray *averages1 = [self defineBasicAverageValuesForRange:BASIC_VALUES_PERIOD channel:1];
    
    if(averages1.count == 0)
    {
        return;
    }

    averageBasicAlpha = @[averages1[0]];
    averageBasicBeta = @[averages1[1]];
    
    [self fillStartXYValues];
    
    _hasStartedIndicators = YES;
}

-(NSArray *)defineBasicAverageValuesForRange:(NSInteger)range channel:(NSInteger)channel
{
    if(_fftData.count > range)
    {
        /*NSMutableArray *teta = [NSMutableArray new];
        for(NSInteger i = (_fftData.count - range); i < _fftData.count; i++)
        {
            NSString *key = [NSString stringWithFormat:@"ch%li", ((long)channel)];
            NSDictionary *dict = _fftData[i][key];
            [teta addObject:@([dict[@"data1_"] doubleValue])];
            //NSLog(@"teta %@", dict[@"data1"]);
        }
        NSExpression *expression = [NSExpression expressionForFunction:@"average:" arguments:@[[NSExpression expressionForConstantValue:teta]]];
        double averageTeta = [[expression expressionValueWithObject:nil context:nil] doubleValue];
        */

        
        NSMutableArray *alpha2 = [NSMutableArray new];
        for(NSInteger i = (_fftData.count - range); i < _fftData.count; i++)
        {
            NSString *key = [NSString stringWithFormat:@"ch%i", 2];
            NSDictionary *dict = _fftData[i][key];
            if(dict[@"signal"] == nil)
            {
                [alpha2 addObject:@([dict[@"data2_"] doubleValue])];
            }
            
            //NSLog(@"alpha %@", dict[@"data2"]);
        }
        NSExpression *expression = nil;
        double averageAlpha2 = -1;
        if(alpha2.count > 0)
        {
            expression = [NSExpression expressionForFunction:@"average:" arguments:@[[NSExpression expressionForConstantValue:alpha2]]];
            averageAlpha2 = [[expression expressionValueWithObject:nil context:nil] doubleValue];
        }
        
        NSMutableArray *alpha4 = [NSMutableArray new];
        for(NSInteger i = (_fftData.count - range); i < _fftData.count; i++)
        {
            NSString *key = [NSString stringWithFormat:@"ch%i", 4];
            NSDictionary *dict = _fftData[i][key];
            if(dict[@"signal"] == nil)
            {
                [alpha4 addObject:@([dict[@"data2_"] doubleValue])];
            }
            //NSLog(@"alpha %@", dict[@"data2"]);
        }
        double averageAlpha4 = -1;
        if(alpha4.count > 0)
        {
            expression = [NSExpression expressionForFunction:@"average:" arguments:@[[NSExpression expressionForConstantValue:alpha4]]];
            averageAlpha4 = [[expression expressionValueWithObject:nil context:nil] doubleValue];
        }
       
        
        NSMutableArray *beta1 = [NSMutableArray new];
        for(NSInteger i = (_fftData.count - range); i < _fftData.count; i++)
        {
            NSString *key = [NSString stringWithFormat:@"ch%i", 1];
            NSDictionary *dict = _fftData[i][key];
            if(dict[@"signal"] == nil)
            {
                [beta1 addObject:@([dict[@"data3_"] doubleValue])];
            }
            //NSLog(@"beta %@", dict[@"data3"]);
        }
        double averageBeta1 = -1;
        if(beta1.count > 0)
        {
            expression = [NSExpression expressionForFunction:@"average:" arguments:@[[NSExpression expressionForConstantValue:beta1]]];
            averageBeta1 = [[expression expressionValueWithObject:nil context:nil] doubleValue];
        }
        
        
        NSMutableArray *beta3 = [NSMutableArray new];
        for(NSInteger i = (_fftData.count - range); i < _fftData.count; i++)
        {
            NSString *key = [NSString stringWithFormat:@"ch%i", 3];
            NSDictionary *dict = _fftData[i][key];
            if(dict[@"signal"] == nil)
            {
                [beta3 addObject:@([dict[@"data3_"] doubleValue])];
            }
            //NSLog(@"beta %@", dict[@"data3"]);
        }
        double averageBeta3 = -1;
        if(beta3.count > 0)
        {
            expression = [NSExpression expressionForFunction:@"average:" arguments:@[[NSExpression expressionForConstantValue:beta3]]];
            averageBeta3 = [[expression expressionValueWithObject:nil context:nil] doubleValue];
        }
       
        double alpharesult = 0;
        double betaresult = 0;
        
        if(averageAlpha2 == -1 && averageAlpha4 != -1)
        {
            alpharesult = averageAlpha4;
        }
        if(averageAlpha2 != -1 && averageAlpha4 == -1)
        {
            alpharesult = averageAlpha2;
        }
        if(averageAlpha2 != -1 && averageAlpha4 != -1)
        {
            alpharesult = (averageAlpha2 + averageAlpha4)/2;
        }
        if(averageAlpha2 == -1 && averageAlpha4 == -1)
        {
            return @[];
        }
        
        if(averageBeta1 == -1 && averageBeta3 != -1)
        {
            betaresult = averageBeta3;
        }
        if(averageBeta1 != -1 && averageBeta3 == -1)
        {
            betaresult = averageBeta1;
        }
        if(averageBeta1 != -1 && averageBeta3 != -1)
        {
            betaresult = (averageBeta1 + averageBeta3)/2;
        }
        if(averageBeta1 == -1 && averageBeta3 == -1)
        {
            return @[];
        }
        
        return @[@(alpharesult), @(betaresult)];
    }
    return nil;
}

-(NSDictionary *)indicatorsState
{
   
    NSArray *averages1 = [self defineBasicAverageValuesForRange:INDICATOR_PERIOD channel:1];
    NSDictionary *dict = nil;
    if(averages1.count == 0)
    {
        dict = @{@"activities" : @"none", @"colors" : @"none"};
        return dict;
    }
    dict = @{@"activities" : [self processXYValues:averages1 forChannel:1], @"colors" : [self processColorIndicators:averages1 forChannel:1]};

    return dict;
}

-(NSMutableArray *)processColorIndicators:(NSArray *)averages forChannel:(NSInteger)channel
{
    double X = [averages[0] doubleValue];
    double Y = [averages[1] doubleValue];

    NSDictionary *basics = basicValues[channel - 1];
    double X0 = [basics[@"data"][@"X0"] doubleValue];
    double Y0 = [basics[@"data"][@"Y0"] doubleValue];
    //NSLog(@"X = %f  Y = %f, X0 = %f  Y0 = %f", X, Y, X0, Y0);
    NSMutableArray *colors = [NSMutableArray new];
    
    if((0.7 * X0 <= X && X <= 1.3 * X0 && 0 <= Y && Y <= 1.25 * Y0) || (1.3 * X0 < X && X <= 1.6 * X0 && Y0 <= Y && Y < 1.25 * Y0) || ( X > 1.6 * X0 && Y > Y0) || (0 < X && X <= 0.7 * X0 && Y0 > Y && Y > 0.75 * Y0))
    {
        [colors addObject:@{@"color" : @"green"}];
    }
    if(((1.3 * X0) < X && X <= (1.6 * X0) && 0 < Y && Y <= Y0) || ( 0 < X && X <= (0.7 * X0) && 0 < Y && Y <= (0.75 * Y0)))
    {
        [colors addObject:@{@"color" : @"yellow"}];

    }
    if((0 < X && X <= 0.7 * X0 && Y0 < Y) || (1.3 * X0 < X && X <= 1.6 * X0 && Y >= 1.25 * Y0))
    {
        [colors addObject:@{@"color" : @"red"}];

    }
    if(X > 1.6 * X0 && 0.75 * 0 < Y && Y <= Y0)
    {
        [colors addObject:@{@"color" : @"orange"}];
        
    }

    return colors;
}


-(NSDictionary *)processXYValues:(NSArray *)averages forChannel:(NSInteger)channel
{
    
    double X = [averages[0] doubleValue];
    double Y = [averages[1] doubleValue];
    
    NSDictionary *basics = basicValues[channel - 1];
    double X0 = [basics[@"data"][@"X0"] doubleValue];
    double Y0 = [basics[@"data"][@"Y0"] doubleValue];
    double X1p = [basics[@"data"][@"X1p"] doubleValue];
    double X1m = [basics[@"data"][@"X1m"] doubleValue];
    double Y1p = [basics[@"data"][@"Y1p"] doubleValue];
    double Y1m = [basics[@"data"][@"Y1m"] doubleValue];
    double X2p = [basics[@"data"][@"X2p"] doubleValue];
    double X2m = [basics[@"data"][@"X2m"] doubleValue];
    double Y2p = [basics[@"data"][@"Y2p"] doubleValue];
    double Y2m = [basics[@"data"][@"Y2m"] doubleValue];
    double X3p = [basics[@"data"][@"X3p"] doubleValue];
    double X3m = [basics[@"data"][@"X3m"] doubleValue];
    double Y3p = [basics[@"data"][@"Y3p"] doubleValue];
    double Y3m = [basics[@"data"][@"Y3m"] doubleValue];
    double X4p = [basics[@"data"][@"X4p"] doubleValue];
    double X4m = [basics[@"data"][@"X4m"] doubleValue];
    double Y4p = [basics[@"data"][@"Y4p"] doubleValue];
    double Y4m = [basics[@"data"][@"Y4m"] doubleValue];
    
    
    CBManagerActivityZone activityZone = CBManagerActivityZone_NormalActivity;
    float percent = 1.0;
    if(X > X0)
    {
        //positive values
        if(X1p >= X && X > X0 && Y >= Y0)
        {
            activityZone = CBManagerActivityZone_Relaxation;
            percent = 0.25;
        }
        if(X1p >= X && X > X0 && Y >= Y1p && Y0 >= Y)
        {
            activityZone = CBManagerActivityZone_Relaxation;
            percent = 0.5;
        }
        if(X1p >= X && X > X0 && Y1p >= Y)
        {
            activityZone = CBManagerActivityZone_Relaxation;
            percent = 0.75;
        }
        if(X2p >= X && X > X1p && Y0 >= Y && Y >= Y2p)
        {
            activityZone = CBManagerActivityZone_Relaxation;
            percent = 1;
        }
        if(X3p >= X && X > X2p && Y >= Y0)
        {
            activityZone = CBManagerActivityZone_HighRelaxation;
            percent = 0.25;
        }
        if(X3p >= X && X > X2p && Y0 >= Y && Y >= Y3p)
        {
            activityZone = CBManagerActivityZone_HighRelaxation;
            percent = 0.5;
        }
        if(X3p >= X && X > X2p && Y3p >= Y)
        {
            activityZone = CBManagerActivityZone_HighRelaxation;
            percent = 0.75;
        }
        if(X4p >= X && X > X3p && Y0 >= Y && Y >= Y4p)
        {
            activityZone = CBManagerActivityZone_HighRelaxation;
            percent = 1;
        }
        if(X >= X4p)
        {
            activityZone = CBManagerActivityZone_Dream;
            percent = 0.5;
        }
        
    }
    else
    {
        //negative values
        if(X1m < X && X <= X0 && Y < Y0)
        {
            activityZone = CBManagerActivityZone_NormalActivity;
            percent = 0.25;
        }
        if(X1m < X && X <= X0 && Y0 <= Y && Y <= Y1m)
        {
            activityZone = CBManagerActivityZone_NormalActivity;
            percent = 0.5;
        }
        if(X1m < X && X <= X0 && Y1m < Y)
        {
            activityZone = CBManagerActivityZone_NormalActivity;
            percent = 0.75;
        }
        if(X2m < X && X <= X1m && Y0 < Y && Y <= Y2m)
        {
            activityZone = CBManagerActivityZone_NormalActivity;
            percent = 1;
        }
        if(X3m < X && X <= X2m && Y < Y0)
        {
            activityZone = CBManagerActivityZone_Agitation;
            percent = 0.25;
        }
        if(X3m < X && X <= X2m && Y0 < Y && Y <= Y3m)
        {
            activityZone = CBManagerActivityZone_Agitation;
            percent = 0.5;
        }
        if(X3m < X && X <= X2m && Y3m < Y)
        {
            activityZone = CBManagerActivityZone_Agitation;
            percent = 0.75;
        }
        if(X4m < X && X <= X3m && Y0 < Y && Y <= Y4m)
        {
            activityZone = CBManagerActivityZone_Agitation;
            percent = 1;
        }
        if(0 < X && X < 0.1 * X0)
        {
            activityZone = CBManagerActivityZone_HighAgitation;
            percent = 0.5;
        }
    }
    
    
    return @{@"zone" : @(activityZone), @"percents" : @(percent)};
}

-(void)fillStartXYValues
{
    for(int i = 0; i < 1; i++)
    {
        double X0 = [averageBasicAlpha[i] doubleValue];
        double Y0 = [averageBasicBeta[i] doubleValue];
        double X1p = 1.3 * X0;
        double X1m = 0.65 * (X0 - 0.1 * X0);
        double Y1p = 0.9 * Y0;
        double Y1m = 1.1 * Y0;
        double X2p = 1.45 * X0;
        double X2m = 0.45 * (X0 - 0.1 * X0);
        double Y2p = 0.85 * Y0;
        double Y2m = 1.15 * Y0;
        double X3p = 1.55 * X0;
        double X3m = 0.2 * (X0 - 0.1 * X0);
        double Y3p = 0.8 * Y0;
        double Y3m = 1.25 * Y0;
        double X4p = 1.7 * X0;
        double X4m = (X0 - 0.1 * X0);
        double Y4p = 0.7 * Y0;
        double Y4m = 1.3 * Y0;
        
        NSDictionary *values = @{@"channel" : @(i + 1), @"data" : @{@"X0" : @(X0), @"Y0" : @(Y0), @"X1p" : @(X1p), @"X1m" : @(X1m), @"Y1p" : @(Y1p), @"Y1m" : @(Y1m), @"X2p" : @(X2p), @"X2m" : @(X2m), @"Y2p" : @(Y2p), @"Y2m" : @(Y2m), @"X3p" : @(X3p), @"X3m" : @(X3m), @"Y3p" : @(Y3p), @"Y3m" : @(Y3m), @"X4p" : @(X4p), @"X4m" : @(X4m), @"Y4p" : @(Y4p), @"Y4m" : @(Y4m)}};
        [basicValues addObject:values];
    }
    
}




-(NSInteger)batteryLevel
{
    UInt8 batteryLevel;
    [currentbatteryCharacteristic.value getBytes:&batteryLevel length:1];
    NSLog(@"battery level %i", batteryLevel);
    
    return batteryLevel;
}


@end
