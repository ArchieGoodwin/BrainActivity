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

    NSMutableArray *data1;
    NSMutableArray *data2;
    NSMutableArray *data3;
    NSMutableArray *data4;
    
    NSMutableArray *dataFFT1;
    NSMutableArray *dataFFT2;
    NSMutableArray *dataFFT3;
    NSMutableArray *dataFFT4;


    NSInteger currentIndex;
    NSInteger currentFFTIndex;

    NSInteger currentRange;
    
    NSInteger currentView;
    
    
}

@property (nonatomic, strong) NSTimer *samplingTimer;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *plotH;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftSpace;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *rightSpace;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segment;
@property (nonatomic, readwrite, strong) CPTXYGraph *graph1;
@property (nonatomic, readwrite, strong) CPTXYGraph *graph2;
@property (nonatomic, readwrite, strong) CPTXYGraph *graph3;
@property (nonatomic, readwrite, strong) CPTXYGraph *graph4;


@property (strong, nonatomic) IBOutlet UIView *greenView;
@property (strong, nonatomic) IBOutlet UIView *yellowView;
@property (strong, nonatomic) IBOutlet UIView *red1View;
@property (strong, nonatomic) IBOutlet UIView *red2View;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    currentView = 1;
   
    currentRange = 600;
    
    currentIndex = 0;
    currentFFTIndex = 0;
    
    data1 = [NSMutableArray new];
    data2 = [NSMutableArray new];
    data3 = [NSMutableArray new];
    data4 = [NSMutableArray new];

    dataFFT1 = [NSMutableArray new];
    dataFFT2 = [NSMutableArray new];
    dataFFT3 = [NSMutableArray new];
    dataFFT4 = [NSMutableArray new];
    
    [self createGraphs];


    _leftSpace.constant = 400;
    _rightSpace.constant = -400;
    //[self showChart];
    //[self showChart2];
    
    //timer = [NSTimer scheduledTimerWithTimeInterval:1.0/125.0 target:self selector:@selector(randomData) userInfo:nil repeats:YES];
    //[timer fire];
    // Do any additional setup after loading the view, typically from a nib.
     //[self fillFFTData:NSMakeRange(0, 8000)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataReceived:) name:@"data_received" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fftDataReceived:) name:@"fft_data_received" object:nil];

    
    _samplingTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(masterTimer) userInfo:nil repeats:YES];

}

-(void)masterTimer {
    
    if(currentView == 3)
    {
        NSLog(@"timer fired");

        dispatch_async(dispatch_get_main_queue(), ^{
            
            if([_manager processGreenForChannel:1])
            {
                _greenView.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:128.0/255.0 blue:0.0/255.0 alpha:1.0];
            }
            else
            {
                _greenView.backgroundColor = [UIColor lightGrayColor];
            }

        });
    }
   
    
    
}

- (IBAction)changedView:(id)sender {
    
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    
    currentView = seg.selectedSegmentIndex + 1;
    if(currentView < 3)
    {
        _leftSpace.constant = self.view.frame.size.width;
        _rightSpace.constant = -self.view.frame.size.width;
        [self createGraphs];

    }
    else
    {
        _leftSpace.constant = -16.0;
        _rightSpace.constant = -16.0;
    }
}

-(void)createGraphs
{
    if(currentView == 1)
    {
        [self createCorePlot:_view1 withColor:[UIColor blueColor]];
        [self createCorePlot:_view2 withColor:[UIColor redColor]];
        [self createCorePlot:_view3 withColor:[UIColor orangeColor]];
        [self createCorePlot:_view4 withColor:[UIColor blackColor]];
    }
    if(currentView == 2)
    {
        [self create3CorePlot:_view1 withColor:[UIColor darkGrayColor]];
        [self create3CorePlot:_view2 withColor:[UIColor darkGrayColor]];
        [self create3CorePlot:_view3 withColor:[UIColor darkGrayColor]];
        [self create3CorePlot:_view4 withColor:[UIColor darkGrayColor]];

    }
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    

    self.plotH.constant = ([UIScreen mainScreen].bounds.size.height - 130) / 4;
    [self.view layoutSubviews];
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    
    [_samplingTimer invalidate];
    _samplingTimer = nil;
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
    
    
    [data1 addObject:@{@"index": @(currentIndex), @"data" : data[@"channel_1"]}];
    
    [data2 addObject:@{@"index": @(currentIndex), @"data" : data[@"channel_2"]}];
    
    [data3 addObject:@{@"index": @(currentIndex), @"data" : data[@"channel_3"]}];
    
    [data4 addObject:@{@"index": @(currentIndex), @"data" : data[@"channel_4"]}];
    
    
    
    if(currentIndex > 625)
    {
        [data1 removeObjectAtIndex:0];
        [data2 removeObjectAtIndex:0];
        [data3 removeObjectAtIndex:0];
        [data4 removeObjectAtIndex:0];
        
    }
    
    if(currentView == 1)
    {
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
    }
    
    
    
    
    currentIndex++;
    
}



-(void)fftDataReceived:(NSNotification *)notification
{

    
    
    
    NSDictionary *data = notification.userInfo;
    
    
    [dataFFT1 addObject:@{@"index": @(currentFFTIndex), @"data" : data[@"fft_channel_1"]}];
    
    [dataFFT2 addObject:@{@"index": @(currentFFTIndex), @"data" : data[@"fft_channel_2"]}];
    
    [dataFFT3 addObject:@{@"index": @(currentFFTIndex), @"data" : data[@"fft_channel_3"]}];
    
    [dataFFT4 addObject:@{@"index": @(currentFFTIndex), @"data" : data[@"fft_channel_4"]}];
    
    
    
    if(currentFFTIndex > 119)
    {
        [dataFFT1 removeObjectAtIndex:0];
        [dataFFT2 removeObjectAtIndex:0];
        [dataFFT3 removeObjectAtIndex:0];
        [dataFFT4 removeObjectAtIndex:0];

    }

    
    if(currentView == 2)
    {
        [self.graph1 reloadData];
        [self.graph2 reloadData];
        [self.graph3 reloadData];
        [self.graph4 reloadData];
        
        CPTXYPlotSpace *plotSpace1 = (CPTXYPlotSpace *)self.graph1.defaultPlotSpace;
        if(currentFFTIndex > 119)
        {
            plotSpace1.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(currentFFTIndex - 120) length:CPTDecimalFromInt(130)];
        }
        
        CPTXYPlotSpace *plotSpace2 = (CPTXYPlotSpace *)self.graph2.defaultPlotSpace;
        if(currentFFTIndex > 119)
        {
            plotSpace2.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(currentFFTIndex - 120) length:CPTDecimalFromDouble(130)];
        }
        
        
        CPTXYPlotSpace *plotSpace3 = (CPTXYPlotSpace *)self.graph3.defaultPlotSpace;
        if(currentFFTIndex > 119)
        {
            plotSpace3.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(currentFFTIndex - 120) length:CPTDecimalFromDouble(130)];
        }
        
        
        CPTXYPlotSpace *plotSpace4 = (CPTXYPlotSpace *)self.graph4.defaultPlotSpace;
        if(currentFFTIndex > 119)
        {
            plotSpace4.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(currentFFTIndex - 120) length:CPTDecimalFromDouble(130)];
        }

    }
    
    

    currentFFTIndex++;

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
    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0) length:CPTDecimalFromDouble(130)];
    plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-3.0) length:CPTDecimalFromDouble(23.0)];
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)newGraph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromDouble(10);
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



#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    if(currentView == 2)
    {
        return dataFFT1.count;
    }
    if(currentView == 1)
    {
        return data1.count;
    }
    return 0;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{

    if(plot.graph == self.graph1)
    {
        if(currentView == 1)
        {
            NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
            NSNumber *num = data1[index][key];
            
            return num;
        }
        if(currentView == 2)
        {
            if([plot.identifier  isEqual: @"Blue Plot"])
            {
                NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
                NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT1[index][key] : dataFFT1[index][key][@"data1"];
                return num;
                
            }
            if([plot.identifier  isEqual: @"Yellow Plot"])
            {
                NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
                NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT1[index][key] : dataFFT1[index][key][@"data2"];
                return num;
                
            }
            if([plot.identifier  isEqual: @"Grey Plot"])
            {
                NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
                NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT1[index][key] : dataFFT1[index][key][@"data3"];
                return num;
                
            }
        }
        
    }
    if(plot.graph == self.graph2)
    {
        if(currentView == 1)
        {
            NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
            NSNumber *num = data2[index][key];
            
            return num;
        }
        if(currentView == 2)
        {
            if([plot.identifier  isEqual: @"Blue Plot"])
            {
                NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
                NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT2[index][key] : dataFFT2[index][key][@"data1"];
                return num;
                
            }
            if([plot.identifier  isEqual: @"Yellow Plot"])
            {
                NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
                NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT2[index][key] : dataFFT2[index][key][@"data2"];
                return num;
                
            }
            if([plot.identifier  isEqual: @"Grey Plot"])
            {
                NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
                NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT2[index][key] : dataFFT2[index][key][@"data3"];
                return num;
                
            }
        }
    }
    if(plot.graph == self.graph3)
    {
        if(currentView == 1)
        {
            NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
            NSNumber *num = data3[index][key];
            
            return num;
        }
        if(currentView == 2)
        {
            if([plot.identifier  isEqual: @"Blue Plot"])
            {
                NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
                NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT3[index][key] : dataFFT3[index][key][@"data1"];
                return num;
                
            }
            if([plot.identifier  isEqual: @"Yellow Plot"])
            {
                NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
                NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT3[index][key] : dataFFT3[index][key][@"data2"];
                return num;
                
            }
            if([plot.identifier  isEqual: @"Grey Plot"])
            {
                NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
                NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT3[index][key] : dataFFT3[index][key][@"data3"];
                return num;
                
            }
        }
    }
    if(plot.graph == self.graph4)
    {
        if(currentView == 1)
        {
            NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
            NSNumber *num = data4[index][key];
            
            return num;
        }
        if(currentView == 2)
        {
            if([plot.identifier  isEqual: @"Blue Plot"])
            {
                NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
                NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT4[index][key] : dataFFT4[index][key][@"data1"];
                return num;
                
            }
            if([plot.identifier  isEqual: @"Yellow Plot"])
            {
                NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
                NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT4[index][key] : dataFFT4[index][key][@"data2"];
                return num;
                
            }
            if([plot.identifier  isEqual: @"Grey Plot"])
            {
                NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"index" : @"data");
                NSNumber *num = fieldEnum == CPTScatterPlotFieldX ? dataFFT4[index][key] : dataFFT4[index][key][@"data3"];
                return num;
                
            }
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
