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
const double K = 1000000 * VRef / 0x7FFF;

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
            if([_delegate respondsToSelector:@selector(CB_changedStatus:)])
            {
                [_delegate CB_changedStatus:@"Scanning started"];
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
            if([_delegate respondsToSelector:@selector(CB_changedStatus:)])
            {
                [_delegate CB_changedStatus:[NSString stringWithFormat:@"Connecting to peripheral %@", peripheral]];
            }
        }
        
        [_centralManager connectPeripheral:peripheral options:nil];

    }
}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect");
    
    if(_delegate)
    {
        if([_delegate respondsToSelector:@selector(CB_changedStatus:)])
        {
            [_delegate CB_changedStatus:[NSString stringWithFormat:@"Failed to connect: %@", error.localizedDescription]];
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
                            return;
                        }
                    }
                }
            }
        }
    }
    if( _discoveredPeripheral)
    {
        [_centralManager cancelPeripheralConnection:_discoveredPeripheral];

    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected");
    
    if(_delegate)
    {
        if([_delegate respondsToSelector:@selector(CB_changedStatus:)])
        {
            [_delegate CB_changedStatus:[NSString stringWithFormat:@"Peripheral connected"]];
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
            if([_delegate respondsToSelector:@selector(CB_changedStatus:)])
            {
                [_delegate CB_changedStatus:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
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
            if([_delegate respondsToSelector:@selector(CB_changedStatus:)])
            {
                [_delegate CB_changedStatus:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
            }
        }
        
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        NSLog(@"characteristic.UUID %@",characteristic.UUID);

        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
            
            if(_delegate)
            {
                if([_delegate respondsToSelector:@selector(CB_changedStatus:)])
                {
                    [_delegate CB_changedStatus:[NSString stringWithFormat:@"Data transfer started"]];
                }
            }
            
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
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

        
        if(channel == 1)
        {
            NSData *subdata = [data subdataWithRange:NSMakeRange(0, 2)];
            short orderNumber = 0;
            [subdata getBytes:&orderNumber length:2];
            orderNumber = CFSwapInt16LittleToHost(orderNumber);

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
            
            
            
            NSDictionary *ret = @{@"counter" : [NSNumber numberWithInteger:_counter],@"timeframe" : [NSString stringWithFormat:@"%li", (long)([NSDate timeIntervalSinceReferenceDate] * 1000000)], @"hardware_order_number" : [NSNumber numberWithFloat:orderNumber], @"ch1" : [NSNumber numberWithDouble:(channel1 * K)], @"ch2" : [NSNumber numberWithDouble:(channel2 * K)], @"ch3" : [NSNumber numberWithDouble:(channel3 * K)], @"ch4" : [NSNumber numberWithDouble:(channel4 * K)]};
            
            
            //NSLog(@"%@", ret);
            
            [_rawvalues addObject:ret];
            
            return ret;

        }
        
        
        if(channel == 2)
        {
            
            NSData *subdata = [data subdataWithRange:NSMakeRange(0, 2)];
            short orderNumber = 0;
            [subdata getBytes:&orderNumber length:2];
            orderNumber = CFSwapInt16LittleToHost(orderNumber);
            
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

            
            NSDictionary *ret = @{@"counter" : [NSNumber numberWithInteger:_counter], @"timeframe" : [NSString stringWithFormat:@"%li", (long)([NSDate timeIntervalSinceReferenceDate] * 1000000)], @"hardware_order_number" : [NSNumber numberWithInt:orderNumber + 1], @"ch1" : [NSNumber numberWithDouble:(channel1_ * K)], @"ch2" : [NSNumber numberWithDouble:(channel2_ * K)], @"ch3" : [NSNumber numberWithDouble:(channel3_ * K)], @"ch4" : [NSNumber numberWithDouble:(channel4_ * K)]};
            
            //NSLog(@"%@", ret);

            [_rawvalues addObject:ret];

            return ret;
            
        }
       
        
    return nil;
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error");
        
        if(_delegate)
        {
            if([_delegate respondsToSelector:@selector(CB_changedStatus:)])
            {
                [_delegate CB_changedStatus:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
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

        }
       
    }
    
    
    [_rawdata appendData:characteristic.value];
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
        if([_delegate respondsToSelector:@selector(CB_changedStatus:)])
        {
            [_delegate CB_changedStatus:@"Device disconnected!"];
        }
    }

    [self stop];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning!" message:@"App lost connection to device!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    
   // [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

-(void)stop
{

    [_centralManager stopScan];
    [_rawdata setLength:0];
    _hasStarted = NO;
    _rawvalues = [NSMutableArray new];
    _fftData = [NSMutableArray new];
    _counter = 0;
    [self cleanup];
    
    _centralManager = nil;
    
    if(_delegate)
    {
        if([_delegate respondsToSelector:@selector(CB_changedStatus:)])
        {
            [_delegate CB_changedStatus:@"Ready to scan"];
        }
    }

}

#pragma mark -
#pragma mark FFT

-(NSDictionary *)fft:(double *)inp
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
        //NSLog(@"%f", output[i]);
    }
  
    /*double *frequences = (double *)malloc(nOver2 * sizeof(double));
    for (int i = 0; i < nOver2; ++i)
    {
        
        double freq = i * 25.0 / nOver2;
        frequences[i] = freq;
        
        //NSLog(@"%f", frequences[i]);
        
    }*/
    
    int val1 = [self findMaxIndex:output range:NSMakeRange(3, 4)];
    //printf("max in 3-6: %8g  %f  max index: %d \n", frequences[val1], output[val1], val1);
    
    
    int val2 = [self findMaxIndex:output range:NSMakeRange(7, 7)];
    //printf("max in 7-13: %8g  %f  max index: %d \n", frequences[val2], output[val2], val2);
    
    
    int val3 = [self findMaxIndex:output range:NSMakeRange(14, 11)];
    //printf("max in 14-18: %8g  %f  max index: %d \n", frequences[val3], output[val3], val3);
   
    
    
    
    return @{@"data1" : [NSNumber numberWithDouble:val1], @"data2" : [NSNumber numberWithDouble:val2], @"data3" : [NSNumber numberWithDouble:val3]};
    
    
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
    
    NSDictionary *fftData1 = [self fft:farray1];
    NSDictionary *fftData2 = [self fft:farray2];
    NSDictionary *fftData3 = [self fft:farray3];
    NSDictionary *fftData4 = [self fft:farray4];

    
    NSDictionary *ret = @{@"counter" : [NSNumber numberWithInteger:_fftCounter], @"ch1" : fftData1, @"ch2" : fftData2, @"ch3" : fftData3, @"ch4" : fftData4, @"timeframe" : [NSString stringWithFormat:@"%li", (long)([NSDate timeIntervalSinceReferenceDate] * 1000000)]};
    
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

-(BOOL)processGreenForChannel:(NSInteger)channel
{
    NSInteger len = _fftData.count;
    
    
    NSMutableArray *greens = [NSMutableArray new];
    
    for(NSInteger i = lastGreenValue; i < len; i++)
    {
        NSString *key = [NSString stringWithFormat:@"ch%li", ((long)channel)];
        NSDictionary *dict = _fftData[i][key];
        [greens addObject:dict[@"data2"]];
    }
    
    NSExpression *expression = [NSExpression expressionForFunction:@"average:" arguments:@[[NSExpression expressionForConstantValue:greens]]];
    double average = [[expression expressionValueWithObject:nil context:nil] doubleValue];


    for(NSInteger i = 0; i < (len - lastGreenValue); i++)
    {
        double val = [greens[i] doubleValue];
        
        if(fabs(lastGreenAverage - val) > (lastGreenAverage * 0.2))
        {
            lastGreenAverage = (lastGreenAverage + average)/2.0;
            lastGreenValue = len;
            
            NSLog(@"%f  %f   %li", average, lastGreenAverage, lastGreenValue);

            return NO;
        }
    }
    
    lastGreenAverage = (lastGreenAverage + average)/2.0;
    lastGreenValue = len;
    
    NSLog(@"%f  %f   %li", average, lastGreenAverage, lastGreenValue);

    return YES;
    
    
}



-(BOOL)processYellowForChannel:(NSInteger)channel
{
    NSInteger len = _fftData.count;
    
    NSMutableArray *yellows = [NSMutableArray new];
    
    for(NSInteger i = 0; i < len; i++)
    {
        NSString *key = [NSString stringWithFormat:@"ch%li", ((long)channel)];
        NSDictionary *dict = _fftData[i][key];
        [yellows addObject:dict[@"data2"]];
    }
    
    BOOL result = NO;
    
    if(len >= 10)
    {
        for(NSInteger i = 4; i < len; i++)
        {
            if(i % 4 == 0)
            {
                double val1 = [yellows[i-4] doubleValue];
                double val2 = [yellows[i] doubleValue];
                if((val2 - val1) > 0)
                {
                    if(((val2 - val1)/val1) > 0.2 && ((val2 - val1)/val1) < 0.3)
                    {
                        result = YES;
                    }
                    else
                    {
                        result = NO;
                    }

                }
                else
                {
                    result = NO;
                }
                
            }
            
        }
    }
   
    return result;
    
    
}





@end
