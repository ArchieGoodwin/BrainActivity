//
//  CBCentralManagerViewController.m
//  CBTutorial
//
//  Created by Orlando Pereira on 10/8/13.
//  Copyright (c) 2013 Mobiletuts. All rights reserved.
//

#import "CBManager.h"
#import <CoreBluetooth/CoreBluetooth.h>

#import "SERVICES.h"

@interface CBManager() < CBCentralManagerDelegate, CBPeripheralDelegate>


@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;

@end

@implementation CBManager

-(id)init
{
    if ((self = [super init])) {
        
    }
    
    return self;

}

-(void)start
{
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _rawdata = [[NSMutableData alloc] init];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    // You should test all scenarios
    if (central.state != CBCentralManagerStatePoweredOn) {
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
    
    [_centralManager cancelPeripheralConnection:_discoveredPeripheral];
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
        [self cleanup];
        return;
    }
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
    // Discover other characteristics
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        [self cleanup];
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
            int orderNumber = 0;
            [subdata getBytes:&orderNumber length:2];
            orderNumber = CFSwapInt16LittleToHost(orderNumber);
            
            
            /* NSData *orderNumaberData2 = [data subdataWithRange:NSMakeRange(2, 2)];
             int orderNumber2 = 0;
             [orderNumaberData2 getBytes:&orderNumber2 length:2];
             orderNumber2 = CFSwapInt16LittleToHost(orderNumber2);
             */
            //first 4 channels
            subdata = [data subdataWithRange:NSMakeRange(3, 2)];
            
            signed char *n = [subdata bytes];
            short channel1 = *(short *)n;
            //int channel1 = [self intFromData:subdata];
            
            subdata = [data subdataWithRange:NSMakeRange(5, 2)];
            short channel2 = 0;
            [subdata getBytes:&channel2 length:2];
            channel2 = CFSwapInt16LittleToHost(channel2);
            
            subdata = [data subdataWithRange:NSMakeRange(7, 2)];
            short channel3 = 0;
            [subdata getBytes:&channel3 length:2];
            channel3 = CFSwapInt16LittleToHost(channel3);
            
            subdata = [data subdataWithRange:NSMakeRange(9, 2)];
            short channel4 = 0;
            [subdata getBytes:&channel4 length:2];
            channel4 = CFSwapInt16LittleToHost(channel4);
            
            
            
            NSDictionary *ret = @{@"counter" : [NSNumber numberWithFloat:([NSDate timeIntervalSinceReferenceDate] * 1000000)], @"hardware_order_number" : [NSNumber numberWithFloat:orderNumber], @"channel_1" : [NSNumber numberWithShort:channel1], @"channel_2" : [NSNumber numberWithShort:channel2], @"channel_3" : [NSNumber numberWithShort:channel3], @"channel_4" : [NSNumber numberWithShort:channel4]};
            
            return ret;

        }
        
        
        if(channel == 2)
        {
            
            NSData *subdata = [data subdataWithRange:NSMakeRange(0, 2)];
            int orderNumber = 0;
            [subdata getBytes:&orderNumber length:2];
            orderNumber = CFSwapInt16LittleToHost(orderNumber);
            
            
            
            //another 4 channels
            subdata = [data subdataWithRange:NSMakeRange(12, 2)];
            short channel1_ = 0;
            [subdata getBytes:&channel1_ length:2];
            channel1_ = CFSwapInt16LittleToHost(channel1_);
            
            subdata = [data subdataWithRange:NSMakeRange(14, 2)];
            short channel2_ = 0;
            [subdata getBytes:&channel2_ length:2];
            channel2_ = CFSwapInt16LittleToHost(channel2_);
            
            subdata = [data subdataWithRange:NSMakeRange(16, 2)];
            short channel3_ = 0;
            [subdata getBytes:&channel3_ length:2];
            channel3_ = CFSwapInt16LittleToHost(channel3_);
            
            subdata = [data subdataWithRange:NSMakeRange(18, 2)];
            short channel4_ = 0;
            [subdata getBytes:&channel4_ length:2];
            channel4_ = CFSwapInt16LittleToHost(channel4_);
            
            NSDictionary *ret = @{@"counter" : [NSNumber numberWithFloat:([NSDate timeIntervalSinceReferenceDate] * 1000000)], @"hardware_order_number" : [NSNumber numberWithInt:orderNumber + 1], @"channel_1" : [NSNumber numberWithShort:channel1_], @"channel_2" : [NSNumber numberWithShort:channel2_], @"channel_3" : [NSNumber numberWithShort:channel3_], @"channel_4" : [NSNumber numberWithShort:channel4_]};
            
            return ret;
            
        }
       
        
    return nil;
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error");
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
            
            
            [_delegate CB_dataUpdatedWithDictionary:[self makeReturnDictionary:characteristic.value channel:2]];

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
    
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

-(void)stop
{

    [_centralManager stopScan];
    [_rawdata setLength:0];

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


@end
