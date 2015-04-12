//
//  ViewController.m
//  BrainActivity
//
//  Created by Nero Wolfe on 08/02/15.
//  Copyright (c) 2015 Sergey Dikarev. All rights reserved.
//

#import "ViewController.h"
#include <stdio.h>
#include <stdlib.h>
#include <Accelerate/Accelerate.h>

@interface ViewController ()
{
    NSTimer *timer;
    NSMutableArray *array1;
    NSArray *array2;
    NSMutableArray *data1;
    NSMutableArray *data2;
    NSMutableArray *data3;
    NSMutableArray *data4;

    NSMutableArray *dataFFT;
    NSInteger currentIndex;
    
    NSInteger currentRange;
    
}
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *plotH;

@property (nonatomic, readwrite, strong) CPTXYGraph *graph1;
@property (nonatomic, readwrite, strong) CPTXYGraph *graph2;
@property (nonatomic, readwrite, strong) CPTXYGraph *graph3;
@property (nonatomic, readwrite, strong) CPTXYGraph *graph4;

@property (nonatomic, readwrite, strong) CPTXYGraph *fftGraph;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataReceived:) name:@"data_received" object:nil];
    
    currentRange = 600;
    
    currentIndex = 0;
    
    data1 = [NSMutableArray new];
    data2 = [NSMutableArray new];
    data3 = [NSMutableArray new];
    data4 = [NSMutableArray new];
    array1 = [NSMutableArray new];

    dataFFT = [NSMutableArray new];
    
    [self createCorePlot:_view1 withColor:[UIColor blueColor]];
    [self createCorePlot:_view2 withColor:[UIColor redColor]];
    [self createCorePlot:_view3 withColor:[UIColor orangeColor]];
    [self createCorePlot:_view4 withColor:[UIColor blackColor]];

    [self create3CorePlot:_fftView withColor:[UIColor darkGrayColor]];

    //[self showChart];
    //[self showChart2];
    
    //timer = [NSTimer scheduledTimerWithTimeInterval:1.0/125.0 target:self selector:@selector(randomData) userInfo:nil repeats:YES];
    //[timer fire];
    // Do any additional setup after loading the view, typically from a nib.
     //[self fillFFTData:NSMakeRange(0, 8000)];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    
    if([UIScreen mainScreen].bounds.size.height < 568)
    {
        self.plotH.constant = 60;
        [self.view layoutSubviews];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
   

}

- (IBAction)back:(id)sender {
}

-(void)dataReceived:(NSNotification *)notification
{

    
    NSDictionary *data = notification.userInfo;
    
    
    
   // NSLog(@"data: %@  number %i", data[@"channel_1"], [data[@"hardware_order_number"] integerValue]);
    
    [array1 addObject:[NSString stringWithFormat:@"%@", data[@"channel_1"]]];
    
    
    [data1 addObject:@{@"index": @(currentIndex), @"data" : data[@"channel_1"]}];
    
    [data2 addObject:@{@"index": @(currentIndex), @"data" : data[@"channel_2"]}];
    
    [data3 addObject:@{@"index": @(currentIndex), @"data" : data[@"channel_3"]}];
    
    [data4 addObject:@{@"index": @(currentIndex), @"data" : data[@"channel_4"]}];
    
    
    //NSLog(@"data1: %@", data1);

    
    if(currentIndex % 128 == 0 && currentIndex > 126)
    {
        
        [self fillFFTData:NSMakeRange(currentIndex - 128, 128)];
        
    }
    
    if(currentIndex > 625)
    {
        [data1 removeObjectAtIndex:0];
        [data2 removeObjectAtIndex:0];
        [data3 removeObjectAtIndex:0];
        [data4 removeObjectAtIndex:0];

    }
    
    if(currentIndex % 8 == 0)
    {
        [self.graph1 reloadData];
        [self.graph2 reloadData];
        [self.graph3 reloadData];
        [self.graph4 reloadData];

        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph1.defaultPlotSpace;
        if(currentIndex > 625)
        {
            plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(currentIndex - 625) length:CPTDecimalFromInt(625)];
            plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(-33000) length:CPTDecimalFromInt(66000)];
        }
        
        CPTXYPlotSpace *plotSpace2 = (CPTXYPlotSpace *)self.graph2.defaultPlotSpace;
        if(currentIndex > 625)
        {
            plotSpace2.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(currentIndex - 625) length:CPTDecimalFromDouble(625)];
            plotSpace2.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(-33000) length:CPTDecimalFromInt(66000)];
        }

        
        CPTXYPlotSpace *plotSpace3 = (CPTXYPlotSpace *)self.graph3.defaultPlotSpace;
        if(currentIndex > 625)
        {
            plotSpace3.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(currentIndex - 625) length:CPTDecimalFromDouble(625)];
            plotSpace3.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(-33000) length:CPTDecimalFromInt(66000)];
        }

        
        CPTXYPlotSpace *plotSpace4 = (CPTXYPlotSpace *)self.graph4.defaultPlotSpace;
        if(currentIndex > 625)
        {
            plotSpace4.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(currentIndex - 625) length:CPTDecimalFromDouble(625)];
            plotSpace4.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(-33000) length:CPTDecimalFromInt(66000)];
        }

    }
    
    
    currentIndex++;

}

-(void)createCorePlot:(UIView *)view2addGraph withColor:(UIColor *)color
{
    // Create graph from theme
    CPTXYGraph *newGraph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    CPTTheme *theme      = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [newGraph applyTheme:theme];
    if(view2addGraph == _view1)
    {
        self.graph1 = newGraph;

    }
    if(view2addGraph == _view2)
    {
        self.graph2 = newGraph;
        
    }
    if(view2addGraph == _view3)
    {
        self.graph3 = newGraph;
        
    }
    if(view2addGraph == _view4)
    {
        self.graph4 = newGraph;
        
    }
    
    CPTGraphHostingView *hostingView = (CPTGraphHostingView *)view2addGraph;
    hostingView.collapsesLayers = NO; // Setting to YES reduces GPU memory usage, but can slow drawing/scrolling
    hostingView.hostedGraph     = newGraph;
    // Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)newGraph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0) length:CPTDecimalFromDouble(625.0)];
    plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-33000) length:CPTDecimalFromDouble(66000)];
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)newGraph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromDouble(125);
    //x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(10.0);
    x.minorTicksPerInterval       = 0;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    
    
    CPTXYAxis *y = axisSet.yAxis;

    y.majorIntervalLength         = CPTDecimalFromDouble(10000);
    y.minorTicksPerInterval       = 0;

    y.delegate             = self;
    
    // Create a blue plot area
    CPTScatterPlot *boundLinePlot  = [[CPTScatterPlot alloc] init];
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.miterLimit        = 1.0;
    lineStyle.lineWidth         = 1.0;
    lineStyle.lineColor         = [CPTColor colorWithCGColor:color.CGColor];
    boundLinePlot.dataLineStyle = lineStyle;
    boundLinePlot.identifier    = @"Blue Plot";
    boundLinePlot.dataSource    = self;
    [newGraph addPlot:boundLinePlot];
    
    newGraph.paddingLeft = 0.0;
    newGraph.paddingTop = 0.0;
    newGraph.paddingRight = 0.0;
    newGraph.paddingBottom = 0.0;

}


-(void)create3CorePlot:(UIView *)view2addGraph withColor:(UIColor *)color
{
    // Create graph from theme
    CPTXYGraph *newGraph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    CPTTheme *theme      = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [newGraph applyTheme:theme];
    
    if(view2addGraph == _fftView)
    {
        self.fftGraph = newGraph;
        
    }
    
    CPTGraphHostingView *hostingView = (CPTGraphHostingView *)view2addGraph;
    hostingView.collapsesLayers = NO; // Setting to YES reduces GPU memory usage, but can slow drawing/scrolling
    hostingView.hostedGraph     = newGraph;
    // Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)newGraph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0) length:CPTDecimalFromDouble(50)];
    plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-3.0) length:CPTDecimalFromDouble(23.0)];
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)newGraph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromDouble(125);
    //x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(10.0);
    x.minorTicksPerInterval       = 0;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    
    [[newGraph plotAreaFrame] setPaddingLeft:30.0f];

    CPTXYAxis *y = axisSet.yAxis;
    
  
    
    y.delegate             = self;
    
    NSNumberFormatter *axisFormatter = [[NSNumberFormatter alloc] init];
    [axisFormatter setMinimumIntegerDigits:2];
    [axisFormatter setMaximumFractionDigits:0];
    
    
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    [textStyle setFontSize:12.0f];
    
    [y setMajorIntervalLength:CPTDecimalFromInt(5)];
    [y setMinorTickLineStyle:nil];
    [y setLabelingPolicy:CPTAxisLabelingPolicyFixedInterval];
    [y setLabelTextStyle:textStyle];
    [y setLabelFormatter:axisFormatter];
    


    
    
    
    
    
    
    // Create a blue plot area
    CPTScatterPlot *boundLinePlot  = [[CPTScatterPlot alloc] init];
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.miterLimit        = 1.0;
    lineStyle.lineWidth         = 2.0;
    lineStyle.lineColor         = [CPTColor colorWithCGColor:[UIColor greenColor].CGColor];
    boundLinePlot.dataLineStyle = lineStyle;
    boundLinePlot.identifier    = @"Blue Plot";
    boundLinePlot.dataSource    = self;
    boundLinePlot.delegate = self;
    [newGraph addPlot:boundLinePlot];
    
    
    // Create a yellow plot area
    CPTScatterPlot *boundLinePlot2  = [[CPTScatterPlot alloc] init];
    CPTMutableLineStyle *lineStyle2 = [CPTMutableLineStyle lineStyle];
    lineStyle2.miterLimit        = 1.0;
    lineStyle2.lineWidth         = 2.0;
    lineStyle2.lineColor         = [CPTColor colorWithCGColor:[UIColor orangeColor].CGColor];
    boundLinePlot2.dataLineStyle = lineStyle2;
    boundLinePlot2.identifier    = @"Yellow Plot";
    boundLinePlot2.delegate = self;
    boundLinePlot2.dataSource    = self;
    [newGraph addPlot:boundLinePlot2];
    
    // Create a grey plot area
    CPTScatterPlot *boundLinePlot3  = [[CPTScatterPlot alloc] init];
    CPTMutableLineStyle *lineStyle3 = [CPTMutableLineStyle lineStyle];
    lineStyle3.miterLimit        = 1.0;
    lineStyle3.lineWidth         = 2.0;
    lineStyle3.lineColor         = [CPTColor colorWithCGColor:[UIColor darkGrayColor].CGColor];
    boundLinePlot3.dataLineStyle = lineStyle3;
    boundLinePlot3.identifier    = @"Grey Plot";
    boundLinePlot3.dataSource    = self;
    boundLinePlot3.delegate = self;
    [newGraph addPlot:boundLinePlot3];
 
    newGraph.paddingLeft = 0.0;
    newGraph.paddingTop = 2.0;
    newGraph.paddingRight = 0.0;
    newGraph.paddingBottom = 2.0;
}

/*-(void)changePlotRange
{
    // Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    if(currentIndex > 125)
    {
        plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(currentIndex - 125) length:CPTDecimalFromDouble(currentIndex)];
        plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0) length:CPTDecimalFromDouble(300.0)];
    }
    
}*/



-(void)loadFiles
{
    NSError *error = nil;
    NSString *filepath1 = [[NSBundle mainBundle] pathForResource:@"O1_125" ofType:@"txt" inDirectory:nil];
    NSString *filepath2 = [[NSBundle mainBundle] pathForResource:@"T5_125" ofType:@"txt" inDirectory:nil];
    
    NSString *string1 = [NSString stringWithContentsOfFile:filepath1 encoding:NSASCIIStringEncoding error:&error];
    NSString *string2 = [NSString stringWithContentsOfFile:filepath2 encoding:NSASCIIStringEncoding error:&error];
    
    //array1 = [string1 componentsSeparatedByString:@"\n"];
    array2 = [string2 componentsSeparatedByString:@"\n"];
    
    array1 = [NSMutableArray new];
    for(int i = 0; i < 8000; i++)
    {
        [array1 addObject:[NSString stringWithFormat:@"%f", (100 * sin(2*3.14159265*3*i/125))]];

    }

    
    
    NSLog(@"ampl 1 = %f", [self findAmplitude:array1]);
    NSLog(@"ampl 2 = %f", [self findAmplitude:array2]);
    
    
    
   
}

-(double)findMax:array arrayKey:obj {
    
    double max = [[[array objectAtIndex:0] objectForKey:obj] doubleValue];
    for ( NSDictionary *dict in array ) {
        if(max<[[dict objectForKey:obj] doubleValue])
            max=[[dict objectForKey:obj] doubleValue];
    }
    return max;
}


-(int)findMaxIndex:(double *)array  range:(NSRange)range{
    int returnI = (int)range.location;
    
    double *subArray = (double *)malloc(range.length * sizeof(double));

    for(int i = 0; i<range.length; i++)
    {
        subArray[i] = array[range.location + i];
        //NSLog(@"%f", subArray[i]);
    }
    
    double max = subArray[0];
    for (int i = 1; i < range.length; i++) {
        //NSLog(@"%f", subArray[i]);
        if(max<subArray[i])
        {
            max=subArray[i];
            returnI = (int)range.location + i;
        }
    }
    return returnI;
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

-(NSDictionary *)fft:(double *)inp
{
    
    //const int log2n = log2f(8000);
    const int log2n = log2f(128);
    const int n = 1 << log2n;
    //const int n = 128;
    const int nOver2 = n / 2;
    
    FFTSetupD fftSetup = vDSP_create_fftsetupD (log2n, kFFTRadix2);
    
    
    DSPDoubleSplitComplex fft_data;
    
    //int i;
    
    //input = malloc(n * sizeof(float));
    fft_data.realp = malloc(nOver2 * sizeof(double));
    fft_data.imagp = malloc(nOver2 * sizeof(double));
    
    
    /*printf("Input\n");
    
    for (i = 0; i < n; ++i)
    {
        printf("%d: %8g\n", i, inp[i]);
    }*/
    
    vDSP_ctozD((DSPDoubleComplex *)inp, 2, &fft_data, 1, nOver2);
    
    /*printf("FFT Input\n");
    
    for (i = 0; i < nOver2; ++i)
    {
        printf("%d: %8g%8g\n", i, fft_data.realp[i], fft_data.imagp[i]);
    }*/
    
    vDSP_fft_zripD (fftSetup, &fft_data, 1, log2n, kFFTDirection_Forward);
    
    /*printf("FFT output\n");
    
    for (i = 0; i < nOver2; ++i)
    {
        printf("%d: %8g%8g\n", i, fft_data.realp[i], fft_data.imagp[i]);
    }*/
    
    /*for (i = 0; i < nOver2; ++i)
    {
        fft_data.realp[i] *= 0.5;
        fft_data.imagp[i] *= 0.5;
    }
    
    printf("Scaled FFT output\n");*/
    
    /*for (i = 0; i < nOver2; ++i)
    {
        printf("%d: %8g%8g\n", i, fft_data.realp[i], fft_data.imagp[i]);
    }
    
    printf("Unpacked output\n");*/
    
    
    double *output = (double *)malloc(nOver2 * sizeof(double));
    for (int i = 0; i < nOver2; ++i)
    {
        output[i] = sqrt(fft_data.realp[i]*fft_data.realp[i] + fft_data.imagp[i]*fft_data.imagp[i]);
    }
    /*printf("FFT output\n");
    for (i = 0; i < nOver2; ++i)
    {
        printf("%d:  %f\n", i, output[i]);
    }*/
    
    //printf("DC  %d: %8g%8g\n", 0, fft_data.realp[0], 0.0); // DC
    double *frequences = (double *)malloc(nOver2 * sizeof(double));
    for (int i = 0; i < nOver2; ++i)
    {

        double freq = i * 25.0 / nOver2;
        frequences[i] = freq;
        //printf("%d: %8g\n", i, freq);
    }
    
    int val1 = [self findMaxIndex:output range:NSMakeRange(8, 8)];
    printf("max in 3-6: %8g  %f  max index: %d \n", frequences[val1], output[val1], val1);
    
    
    int val2 = [self findMaxIndex:output range:NSMakeRange(18, 16)];
    printf("max in 7-13: %8g  %f  max index: %d \n", frequences[val2], output[val2], val2);
    
    
    int val3 = [self findMaxIndex:output range:NSMakeRange(36, 11)];
    printf("max in 14-18: %8g  %f  max index: %d \n", frequences[val3], output[val3], val3);
    //3-24, 25-46, 47-63
    
    //printf("%d: %8g%8g\n", nOver2, fft_data.imagp[0], 0.0); // Nyquist*/
    
    
    return @{@"data1" : [NSNumber numberWithDouble:frequences[val1]], @"data2" : [NSNumber numberWithDouble:frequences[val2]], @"data3" : [NSNumber numberWithDouble:frequences[val3]]};
    
    
   // return fft_data;
}

-(void)fillFFTData:(NSRange)range
{
    
    double *farray2 = malloc(sizeof(double) * range.length);
    
    
    for(NSInteger i = 0; i < range.length; i++)
    {
        farray2[i] = [array1[i + range.location] doubleValue];

        //NSLog(@"%f", farray2[i]);
    }
   
    //DSPDoubleSplitComplex fftData = [self fft:farray2];
    NSDictionary *fftData = [self fft:farray2];
    ///[data3 removeAllObjects];
    
    NSInteger i = [((NSDictionary *)dataFFT.lastObject)[@"index"] integerValue] + 1;
    
        [dataFFT addObject:@{@"index": @(i), @"data" : fftData}];
    //}
    
    
    //double mx = [self findMax:data3 arrayKey:@"data"];
    
    /*if(isnan(mx) || mx == 0 || mx == INFINITY || mx > 10000000000)
    {
        mx = 100000000;
        
    }*/
    
    [self.fftGraph reloadData];
    
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.fftGraph.defaultPlotSpace;
    
  
    if((currentIndex / 128) > 100)
    {
       
        [dataFFT removeObjectAtIndex:0];
        
    }
    /*if(currentIndex > 50 * 128)
    {
     
        if(currentIndex % 128 == 0)
        {
            NSDecimalNumber *myNSDecimalNumber = [NSDecimalNumber decimalNumberWithDecimal:plotSpace.xRange.location];
            
            double ii = [myNSDecimalNumber doubleValue] + 1.0;
            plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(ii) length:CPTDecimalFromDouble(50)];
        }
        

    }
    else
    {*/
    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble((currentIndex / 128) > 100 ? (currentIndex / 128 - 100) : 0) length:CPTDecimalFromDouble(100)];

    //}
    
    //plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-mx) length:CPTDecimalFromDouble(mx * 2)];
    plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-3) length:CPTDecimalFromDouble(23)];
}

-(void)randomData
{
    
    if(currentIndex < (array1.count - 1))
    {
        //float *farray = (float *)malloc(sizeof(float) * 1);
        //NSLog(@"%f", ((NSString  *)array1[currentIndex]).floatValue / 1000 );
        //farray[0] = ((NSString  *)array1[currentIndex]).floatValue / 1000.0 / 100.0;
        //for(int i = 0; i < 16; i++)
        //{
        
        
        //NSInteger index  = [((NSDictionary *)data3.lastObject)[@"index"] integerValue];
        
        //[((NSDictionary *)data3.lastObject)[@"data"][@"data3"] doubleValue]
        
        
        
        
        
            [data1 addObject:@{@"index": @(currentIndex), @"data" : [NSNumber numberWithFloat:(((NSString  *)array1[currentIndex]).floatValue ) ]}];
            
            [data2 addObject:@{@"index": @(currentIndex), @"data" : [NSNumber numberWithFloat:(((NSString  *)array2[currentIndex]).floatValue / 1000.0) ]}];
            
            currentIndex++;
        //}
        
        
        if(currentIndex % 128 == 0)
        {
            
            [self fillFFTData:NSMakeRange(currentIndex - 128, 128)];

        }
        
        if(currentIndex > 625)
        {
            [data1 removeObjectAtIndex:0];
            [data2 removeObjectAtIndex:0];

        }
        
       
        
        
       /* if(currentIndex % 125 == 0)
        {
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                float ampl1 = [self findAmplitude:[array1 objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(currentIndex - 125, 125)]]];

                _ampl1.text = [NSString stringWithFormat:@"Amplitude: %f", ampl1/1000];
                
                float ampl2 = [self findAmplitude:[array2 objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(currentIndex - 125, 125)]]];
                
                _ampl2.text = [NSString stringWithFormat:@"Amplitude: %f", ampl2/1000];
            });
            
            
            
            
        }*/
        

        //float *farray2 = (float *)malloc(sizeof(float) * 1);
        //NSLog(@"%f", ((NSString  *)array1[currentIndex]).floatValue);
        //farray2[0] = ((NSString  *)array2[currentIndex]).floatValue / 1000.0 / 100.0;
        //[self sendData2:farray2];
        
        if(currentIndex % 8 == 0)
        {
            [self.graph1 reloadData];
            [self.graph2 reloadData];
            
            CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph1.defaultPlotSpace;
            if(currentIndex > 625)
            {
                plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(currentIndex - 625) length:CPTDecimalFromDouble(625)];
                plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-150.0) length:CPTDecimalFromDouble(300.0)];
            }
            
            CPTXYPlotSpace *plotSpace2 = (CPTXYPlotSpace *)self.graph2.defaultPlotSpace;
            if(currentIndex > 625)
            {
                plotSpace2.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(currentIndex - 625) length:CPTDecimalFromDouble(625)];
                plotSpace2.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-150.0) length:CPTDecimalFromDouble(300.0)];
            }

        }
        
               //[self redrawChart:_chart];
        //[self redrawChart:_chart2];
        

    }
    else
    {
        currentIndex = 0;
        
        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph1.defaultPlotSpace;

        plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0) length:CPTDecimalFromDouble(625.0)];
        plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-150.0) length:CPTDecimalFromDouble(300.0)];
        
        CPTXYPlotSpace *plotSpace2 = (CPTXYPlotSpace *)self.graph2.defaultPlotSpace;
        plotSpace2.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0) length:CPTDecimalFromDouble(625.0)];
        plotSpace2.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-150.0) length:CPTDecimalFromDouble(300.0)];
        
        [data1 removeAllObjects];
        [data2 removeAllObjects];
        [dataFFT removeAllObjects];
        
        [self loadFiles];

        
        [self.graph1 reloadData];
        [self.graph2 reloadData];
    }
   
    
    
    
}


#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    if(plot.graph == self.fftGraph)
    {
        return dataFFT.count;
    }
    return data1.count;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{

    if(plot.graph == self.graph1)
    {
        
        NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
        NSNumber *num = data1[index][key];
        
        return num;
    }
    if(plot.graph == self.graph2)
    {
        
        NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
        NSNumber *num = data2[index][key];
        
        return num;
    }
    if(plot.graph == self.graph3)
    {
        
        NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
        NSNumber *num = data3[index][key];
        
        return num;
    }
    if(plot.graph == self.graph4)
    {
        
        NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
        NSNumber *num = data4[index][key];
        
        return num;
    }
    if(plot.graph == self.fftGraph)
    {
        if([plot.identifier  isEqual: @"Blue Plot"])
        {
            NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
            NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT[index][key] : dataFFT[index][key][@"data1"];
            return num;

        }
        if([plot.identifier  isEqual: @"Yellow Plot"])
        {
            NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
            NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT[index][key] : dataFFT[index][key][@"data2"];
            return num;

        }
        if([plot.identifier  isEqual: @"Grey Plot"])
        {
            NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
            NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT[index][key] : dataFFT[index][key][@"data3"];
            return num;
            
        }
    }
    

    return [NSNumber numberWithDouble:0.0];
}

#pragma mark -
#pragma mark Axis Delegate Methods

-(BOOL)axis:(CPTAxis *)axis shouldUpdateAxisLabelsAtLocations:(NSSet *)locations
{
    static CPTTextStyle *positiveStyle  = nil;
    static CPTTextStyle *negativeStyle  = nil;
    static dispatch_once_t positiveOnce = 0;
    static dispatch_once_t negativeOnce = 0;
    
    NSFormatter *formatter = axis.labelFormatter;
    CGFloat labelOffset    = axis.labelOffset;
    NSDecimalNumber *zero  = [NSDecimalNumber zero];
    
    NSMutableSet *newLabels = [NSMutableSet set];
    
    for ( NSDecimalNumber *tickLocation in locations ) {
        CPTTextStyle *theLabelTextStyle;
        
        if ( [tickLocation isGreaterThanOrEqualTo:zero] ) {
            dispatch_once(&positiveOnce, ^{
                CPTMutableTextStyle *newStyle = [axis.labelTextStyle mutableCopy];
                newStyle.color = [CPTColor greenColor];
                positiveStyle = newStyle;
            });
            
            theLabelTextStyle = positiveStyle;
        }
        else {
            dispatch_once(&negativeOnce, ^{
                CPTMutableTextStyle *newStyle = [axis.labelTextStyle mutableCopy];
                newStyle.color = [CPTColor redColor];
                negativeStyle = newStyle;
            });
            
            theLabelTextStyle = negativeStyle;
        }
        
        NSString *labelString       = [formatter stringForObjectValue:tickLocation];
        CPTTextLayer *newLabelLayer = [[CPTTextLayer alloc] initWithText:labelString style:theLabelTextStyle];
        
        CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithContentLayer:newLabelLayer];
        newLabel.tickLocation = tickLocation.decimalValue;
        newLabel.offset       = labelOffset;
        
        [newLabels addObject:newLabel];
    }
    
    axis.axisLabels = newLabels;
    
    return NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
