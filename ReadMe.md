# CBManager Class Reference
## Overview
The CBManager class handles connections and data transfer between Braniac (alpha title) accessory and iOS device.
## Tasks
#### Getting the CBManager Accessory Manager
    CBManager *cbManager = [[CBManager alloc] init];
    cbManager.delegate = self;

#### Setting Up CBManager
* yellowFlagLow (float)
* yellowFlagHigh (float)
* red1Flag (float)
* red2Flag (float)

#### Starting and Stopping Connection and Data Stream
* start
* stop

#### Getting Information about CBManager state
* hasStarted *property*
* rawdata (NSMutableData *)
* raw values (NSMutableArray *)
* fftData (NSMutableArray *)

#### Accessing the Delegate
* delegate *property*

## Properties
**hasStarted**
A BOOL value indicating if the current CBManager instance object working: connected to hardware Braniac accessory and receiving data. Read-only
		@property (nonatomic, assign, readonly) BOOL hasStarted;
**rawdata**
A NSMutableData object containing the unprocessed raw data bytes received from hardware Braniac accessory. Read-only
		@property (strong, nonatomic, readonly) NSMutableData *rawdata;
**rawvalues**
A NSMutableArray object containing processed data values received from hardware Brainiac accessory including hardware order number, double values from each 4 channels, time tick order number. Read-only
		@property (strong, nonatomic, readonly) NSMutableArray *rawvalues;
**fftData**
A NSMutableArray object containing processed fast-FFT values made form each 256 raw data values for each channel. Includes FFT double values for each channel, serial order number and time tick value. Read-only
		@property (strong, nonatomic, readonly) NSMutableArray *fftData;
**delegate**
The object that acts as the delegate (CBManagerDelegate) of the accessory. All data receiving and status reporting goes through it. 
		@property (nonatomic,strong) id <CBManagerDelegate> delegate;
**yellowFlagLow**
Bool property used to set the low limit of dominant frequency signal changing to detect relaxation of brain activity. The default value is 0.2
		@property (nonatomic, assign) double yellowFlagLow;
**yellowFlagHigh**
Bool property used to set the high limit of dominant frequency signal changing to detect relaxation of brain activity. The default value is 0.3
		@property (nonatomic, assign) double yellowFlagHigh;
**red1Flag**
Bool property used to set the minimum limit of dominant frequency signal changing to detect overexcitement of brain activity. The default value is 0.2
		@property (nonatomic, assign) double red1Flag;
**red2Flag**
Bool property used to set the minimum limit of dominant frequency signal changing to detect damping of brain activity. The default value is 0.3
		@property (nonatomic, assign) double red2Flag;

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
# CBManagerDelegate Protocol Reference
