# CBManager Class Reference 
###### (SDK version 2.0 - 01/16/15)

## Overview
The CBManager class handles connections and data transfer between Braniac hardware accessory and iOS device (iPhone 4s and higher).

## List of development tools and frameworks used
#### Development tools and language: 
* Xcode 6.1+ 
* Objective-C
Frameworks for SDK:
* CoreBluetooth
* Accelerate
#### Frameworks for test project:
* CoreText
* Fabric
* Security
* OpenGLES
* QuartzCore
* Cocoapods

## Instructions on how to build and install for development CBManager Accessory Manager
First, copy to your project files CBManager.h, CBManager.m, SERVICES.h. Add next frameworks libraries to project: 

* CoreBluetooth
* Accelerate

Make your view controller which you want to use to receive data from CBManager inherited from CBManagerDelegate. Create instance variable of CBManager class and assign delegate property to self.
 
		CBManager *cbManager = [[CBManager alloc] init];
		cbManager.delegate = self;
		[cbManager start]; // 

or 

		[cbManager startTestSequenceWithDominantFrequence:selectedFreq]; where selectedFreq - float variable with test dominant frequency. 

Next you should implement required CB_dataUpdatedWithDictionary method to receive data from Brainiac accessory device. Example: 

		-(void)CB_dataUpdatedWithDictionary:(NSDictionary *)data
		{

		    		//process data
       
		}

Also you may implement two optional methods (to receive FFT data, indicators state and status messages from device) 

		-(void)CB_fftDataUpdatedWithDictionary:(NSDictionary *)data
		{
    		//process fft data
    
		}

		-(void)CB_indicatorsStateWithDictionary:(NSDictionary *)data
		{		
    		//process indicators data
		}

		-(void)CB_changedStatus:(CBManagerMessage)status message:(NSString *)statusMessage
		{
    		dispatch_async(dispatch_get_main_queue(), ^{
        
        		self.lblStatus.text = statusMessage;
    		});
		}

## Tasks

#### Getting the CBManager Accessory Manager
    CBManager *cbManager = [[CBManager alloc] init];
    cbManager.delegate = self;

#### Starting and Stopping Connection and Data Streams
* start
* stop
* startTestSequenceWithDominantFrequence:
* startProcessAverageValues

#### Getting Information about CBManager state
* hasStarted *property*
* rawdata (NSMutableData *)
* raw values (NSMutableArray *)
* fftData (NSMutableArray *)
* batteryLevel (NSInteger)
* hasStartedIndicators *property*
* hasStartedProcessBasicValues *property*

#### Accessing the Delegate
* delegate *property*

## Properties

**hasStarted**

A BOOL value indicating if the current CBManager instance object working: connected to hardware Braniac accessory and receiving data. Read-only

		@property (nonatomic, assign, readonly) BOOL hasStarted;

**hasStartedProcessBasicValues**

A BOOL value indicating if the current CBManager instance object started to measure average values for current examinee indicators state. This state is needed before starting receiving real indicators state. Read-only

		@property (nonatomic, assign, readonly) BOOL hasStartedProcessBasicValues;

**hasStartedIndicators**

A BOOL value indicating if the current CBManager instance object started to measure indicators values for current examinee brain state. This property becomes true after some time (1 min) after starting measuring average basic values. When this property becomes true then delegate CB_indicatorsStateWithDictionary starts firing. Read-only

		@property (nonatomic, assign, readonly) BOOL hasStartedIndicators;

**rawdata**

A NSMutableData object containing the unprocessed raw data bytes received from hardware Braniac accessory. Read-only

		@property (strong, nonatomic, readonly) NSMutableData *rawdata;

**rawvalues**

A NSMutableArray object containing processed data values received from hardware Brainiac accessory including hardware order number, double values from each 4 channels, time tick order number. Read-only

		@property (strong, nonatomic, readonly) NSMutableArray *rawvalues;

**fftData**

A NSMutableArray object containing processed fast-FFT values made form each 256 raw data values for each channel. Includes FFT double values for each channel, serial order number and time tick value. Read-only

		@property (strong, nonatomic, readonly) NSMutableArray *fftData;

**batteryLevel**

A NSInteger value containing number from 0 to 100 indicating battery level of hardware accessory. Read-only

		-(NSInteger)batteryLevel;

**delegate**

The object that acts as the delegate (CBManagerDelegate) of the accessory. All data receiving and status reporting goes through it. 

		@property (nonatomic,strong) id <CBManagerDelegate> delegate;


## Initialisation and Creating CBManager object

**init**

Returns CBManager object which is ready to start connecting. Should always be used to start working with hardware Braniac accessory. 

		CBManager *cbManager = [[CBManager alloc] init];
		cbManager.delegate = self;

**start**

Starts connecting to hardware Braniac accessory and receiving data and processing data if connect is successful. Starts dispatching data via delegate methods immediately. Set hasStarted property to true.

		-(void)start;

**stop**
 
Stops sending data via delegate methods, disconnecting from hardware Braniac accessory. Set hasStarted property to false.

		-(void)stop;

**startTestSequenceWithDominantFrequence:**

Starts sending test data values via delegate methods (without using hardware accessory). Starts dispatching data via delegate methods immediately. Use this method to test correct data receiving sequences and draw sample data plots. Set hasStarted property to true.

		-(void)startTestSequenceWithDominantFrequence:(float)fréquence;

**startProcessAverageValues:**

Starts to measure basic average values needed to set start level before measuring brain activity and show state indicator. After 1 min after firing this method the delegate CB_indicatorsStateWithDictionary becomes firing (each 10 sec). 

		-(void)startProcessAverageValues;


# CBManagerDelegate Protocol Reference
## Overview

The CBManagerDelegate protocol defines the methods for handling accessory data flow and status messages dispatched from CBManager object.

## Tasks

**CB_dataUpdatedWithDictionary:**

Required method which returns brain activity data values for each of 4 channels. 

		-(void)CB_dataUpdatedWithDictionary:(NSDictionary *)data;

*Parameters*

* **data** - NSDictionary objects with returned data values with NSStrings as keys. See below the contents of data structure. 

*Description*

* *hardware_order_number* - hardware order number identifying number of data packet - *Short*

* *timeframe* - number of milliseconds passed from 1970 year for each packet - *NSString*

* *counter* - serial internal order number identifying number of data packet - *NSInteger*

* *ch1* - brain activity measure for channel 1 (T3) - *double*

* *ch2* - brain activity measure for channel 2 (O1) - *double*

* *ch3* - brain activity measure for channel 3 (T4) - *double*

* *ch4* - brain activity measure for channel 4 (O2) - *double*

**CB_fftDataUpdatedWithDictionary**

Optional method returning FFT data processed each 1 sec (so for 250 data packets). Each FFT processes packet contains dominant frequencies values for each channel and each range (total 3 range for each channel)

		-(void)CB_fftDataUpdatedWithDictionary:(NSDictionary *)data;

*Parameters*

* **data** - NSDictionary objects with returned data values with NSStrings as keys. See below the contents of data structure.

*Description*

* *timeframe* - number of milliseconds passed from 1970 year for each packet - *NSString*

* *counter* - serial internal order number identifying number of data packet - *NSInteger*

* *ch1* - brain activity FFT dictionary processed for channel 1 - *NSDictionary*

* *ch2* - brain activity FFT dictionary processed for channel 2 - *NSDictionary*

* *ch3* - brain activity FFT dictionary processed for channel 3 - *NSDictionary*

* *ch4* - brain activity FFT dictionary processed for channel 4 - *NSDictionary*

*FFT dictionary structure*

* *data1* - dominant frequency value for current time range and frequencies range 3-7 Hz - *double*

* *data2* - dominant frequency value for current time range and frequencies range 7-13 Hz - *double*

* *data3* - dominant frequency value for current time range and frequencies range 14-24 Hz - *double*

**CB_indicatorsStateWithDictionary**

Optional method returning indicators state for examinee (each 10 sec). Each indicators state dictionary contains values for colour indicators and activity zone for current brain state.

		-(void)CB_indicatorsStateWithDictionary:(NSDictionary *)data;

*Parameters*

* **data** - NSDictionary objects with returned data values with NSStrings as keys. See below the contents of data structure.

*Description*

* *activities* - contains dictionary with two values: activity zone indicator and level percent of current activity - *NSDictionary*

*Activities dictionary structure*

* *zone* - activity zone indicator of type CBManagerActivityZone (possible values see below) - *int*

* *percent* - percent level for current activity (possible values 0.25, 0.5, 0.75, 1) - *float*


* *colors* - contains array colour values dictionaries for each channel - *NSArray*

*Colours dictionary structure*

* *zone* - activity zone indicator of type CBManagerActivityZone (possible values see below) - *int*

* *percent* - percent level for current activity (possible values 0.25, 0.5, 0.75, 1) - *float*


**CB_changedStatus**

Optional method returning status messages from CBManager object instance alongside with status code (see CBManagerMessage enum for possible values)

		-(void)CB_changedStatus:(CBManagerMessage)status message:(NSString *)statusMessage;

*Parameters*

* **statusMessage** - NSString object with text message describing current state of CBManager object instance. 
* **status** - CBManagerMessage NSInteger code describing the current status of CBManager object instance.


#CBManagerMessage enum

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

#CBManagerActivityZone enum

    CBManagerActivityZone_Relaxation = 0,
    CBManagerActivityZone_HighRelaxation = 1,
    CBManagerActivityZone_Dream = 2,
    CBManagerActivityZone_NormalActivity = 3,
    CBManagerActivityZone_Agitation = 4,
    CBManagerActivityZone_HighAgitation = 5

## Test procedure for Acceptance

Compile project using instructions in previous sections of this reference. Start project on your iPhone. Switch on Brainiac hardware accessory. Tap on Connect to device button on first screen to connect to accessory. After successful connect tap on Show plot with data button to see at plot data graphs. Switch between Raw data and Spectrum tabs to see if data is populated

## Test procedure for Quality Assurance

You may test SDK features using special test regime of SDK and test application. 
Compile project using instructions in previous sections of this reference. Start project on your iPhone. Choose any value for dominant frequency using stepper right of the button Start test. Tap on Start test button on first screen to generate permanent test data sequences. Tap on Show plot with data button to see at plot data graphs. Switch between Raw data and Spectrum tabs to see if data is populated and plot draws correct pure sinusoid and green line at set dominant frequency. 