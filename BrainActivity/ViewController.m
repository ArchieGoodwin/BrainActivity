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
#import <AFNetworking/AFNetworking.h>
#import "SDiPhoneVersion.h"
#define RAW_SCOPE 200000

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

    NSMutableArray *dataFFT;

    NSInteger currentIndex;
    NSInteger currentFFTIndex;

    NSInteger currentRange;
    
    NSInteger currentView;
    
    NSInteger scopeRaw;
    NSInteger scopeSpectrum;
    
    NSArray *zoomValues;
    NSArray *scopeValues;
    NSInteger limit;
}
@property (strong, nonatomic) IBOutlet UIButton *btnBack;
@property (strong, nonatomic) IBOutlet UILabel *scopeLabel;
@property (strong, nonatomic) IBOutlet UILabel *zoomLabel;

@property (nonatomic, strong) NSTimer *samplingTimer;
@property (nonatomic, strong) NSTimer *yellowTimer;
@property (strong, nonatomic) IBOutlet UIStepper *scopeStepper;

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

-(void)defaultValues
{
    scopeRaw = RAW_SCOPE;
    
    scopeValues = @[@250, @500, @1000, @1250];

    zoomValues = @[@20000, @40000, @100000, @200000, @400000];
    
    currentView = 1;
    
    currentRange = 5 * 250;
    
    currentIndex = 0;
    currentFFTIndex = 0;
    
    [self fillLabels];

}

-(void)fillLabels
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _zoomLabel.text = [NSString stringWithFormat:@"%li mV", scopeRaw / 1000];
        _scopeLabel.text = [NSString stringWithFormat:@"%li sec", currentRange / 250];

    });
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //currentIndex = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    limit = 100;
    
    if ([SDiPhoneVersion deviceVersion] == iPhone6 || [SDiPhoneVersion deviceVersion] == iPhone6Plus)
    {
        limit = 8;
    }
    
    [self defaultValues];
    
    _btnBack.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _btnBack.layer.borderWidth = 2.0;
    _btnBack.layer.cornerRadius = 15.0;

    _lblGreen.clipsToBounds = YES;
    _lblGreen.layer.borderWidth = 2.0;
    _lblGreen.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _lblGreen.layer.cornerRadius = 15.0;
    
    _lblYellow.layer.borderWidth = 2.0;
    _lblYellow.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _lblYellow.layer.cornerRadius = 15.0;

    _lblRed1.layer.borderWidth = 2.0;
    _lblRed1.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _lblRed1.layer.cornerRadius = 15.0;
    
    _lblRed2.layer.borderWidth = 2.0;
    _lblRed2.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _lblRed2.layer.cornerRadius = 15.0;
    
    _greenView.layer.borderWidth = 2.0;
    _greenView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _greenView.layer.cornerRadius = 15.0;
    
    _yellowView.layer.borderWidth = 2.0;
    _yellowView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _yellowView.layer.cornerRadius = 15.0;
    
    _red1View.layer.borderWidth = 2.0;
    _red1View.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _red1View.layer.cornerRadius = 15.0;
    
    _red2View.layer.borderWidth = 2.0;
    _red2View.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _red2View.layer.cornerRadius = 15.0;
    
    
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
    _yellowTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(yellowTimerFire) userInfo:nil repeats:YES];


    
    
}

-(void)masterTimer {
    
    if(currentView == 3)
    {
        NSLog(@"timer fired");

        if(_manager.hasStarted)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if([_manager processGreenForChannel:1])
                {
                    _greenView.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:128.0/255.0 blue:0.0/255.0 alpha:1.0];
                }
                else
                {
                    _greenView.backgroundColor = [UIColor lightGrayColor];
                }
                
                if([_manager processYellowForChannel:1])
                {
                    _yellowView.backgroundColor = [UIColor colorWithRed:242.0/255.0 green:239.0/255.0 blue:54.0/255.0 alpha:1.0];
                }
                else
                {
                    _yellowView.backgroundColor = [UIColor lightGrayColor];
                }
                
            });
        }
        
       
    }
   
    
    
}

-(void)yellowTimerFire {
    
    if(currentView == 3)
    {
        NSLog(@"yellow timer fired");
        
        if(_manager.hasStarted)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if([_manager processYellowForChannel:1])
                {
                    _yellowView.backgroundColor = [UIColor colorWithRed:242.0/255.0 green:239.0/255.0 blue:54.0/255.0 alpha:1.0];
                }
                else
                {
                    _yellowView.backgroundColor = [UIColor lightGrayColor];
                }
                
            });
        }
        
        
    }
    
    
    
}

- (IBAction)scopeChange:(id)sender {
    
    UIStepper *stepp = (UIStepper *)sender;
    
    /*if([scopeValues[(NSInteger)stepp.value] integerValue] > 1250)
    {
        currentIndex = 0;
        
        [self createGraphs];
        
        [data1 removeAllObjects];
        [data2 removeAllObjects];
        [data3 removeAllObjects];
        [data4 removeAllObjects];
        
    }*/
    
    currentRange = [scopeValues[(NSInteger)stepp.value] integerValue];
    
    NSLog(@"%f  %li", stepp.value, currentRange);
    
    //[self createGraphs];
    
    
    [self fillLabels];
}


- (IBAction)zoomChange:(id)sender {
    
    UIStepper *stepp = (UIStepper *)sender;
    
    scopeRaw = [zoomValues[(NSInteger)stepp.value] integerValue];

    NSLog(@"%f  %ld", stepp.value, (long)scopeRaw);
    
    [self fillLabels];
}

- (IBAction)changedView:(id)sender {
    
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    
    currentView = seg.selectedSegmentIndex + 1;
    
    if(currentView == 1)
    {
        _zoom.hidden = NO;
        _scopeStepper.hidden = NO;

    }
    else
    {
        _zoom.hidden = YES;
        _scopeStepper.hidden = YES;
    }
    
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
        [self createCorePlot:_view1 withColor:[UIColor lightGrayColor]];
        [self createCorePlot:_view2 withColor:[UIColor lightGrayColor]];
        [self createCorePlot:_view3 withColor:[UIColor lightGrayColor]];
        [self createCorePlot:_view4 withColor:[UIColor lightGrayColor]];
        

        if([self.view viewWithTag:101])
        {
            [[self.view viewWithTag:101] removeFromSuperview];
            [[self.view viewWithTag:102] removeFromSuperview];
            [[self.view viewWithTag:103] removeFromSuperview];
            [[self.view viewWithTag:104] removeFromSuperview];
            
        }
        else
        {
            UIView *viewLine1 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 5, 90, 1, self.view.frame.size.height - 130)];
            viewLine1.backgroundColor = [UIColor lightGrayColor];
            viewLine1.tag = 101;
            
            UIView *viewLine2 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 5 * 2, 90, 1, self.view.frame.size.height - 130)];
            viewLine2.backgroundColor = [UIColor lightGrayColor];
            viewLine2.tag = 102;
            
            UIView *viewLine3 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 5 * 3, 90 , 1, self.view.frame.size.height - 130)];
            viewLine3.backgroundColor = [UIColor lightGrayColor];
            viewLine3.tag = 103;
            
            UIView *viewLine4 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 5 * 4, 90, 1, self.view.frame.size.height - 130)];
            viewLine4.backgroundColor = [UIColor lightGrayColor];
            viewLine4.tag = 104;
            
            [self.view addSubview:viewLine1];
            [self.view addSubview:viewLine2];
            [self.view addSubview:viewLine3];
            [self.view addSubview:viewLine4];

        }
        
    }
    if(currentView == 2)
    {
        if([self.view viewWithTag:101])
        {
            [[self.view viewWithTag:101] removeFromSuperview];
            [[self.view viewWithTag:102] removeFromSuperview];
            [[self.view viewWithTag:103] removeFromSuperview];
            [[self.view viewWithTag:104] removeFromSuperview];
            
        }
        
        [self create3CorePlot:_view1 withColor:[UIColor darkGrayColor]];
        [self create3CorePlot:_view2 withColor:[UIColor darkGrayColor]];
        [self create3CorePlot:_view3 withColor:[UIColor darkGrayColor]];
        [self create3CorePlot:_view4 withColor:[UIColor darkGrayColor]];

    }
    if( currentView == 3)
    {
        if([self.view viewWithTag:101])
        {
            [[self.view viewWithTag:101] removeFromSuperview];
            [[self.view viewWithTag:102] removeFromSuperview];
            [[self.view viewWithTag:103] removeFromSuperview];
            [[self.view viewWithTag:104] removeFromSuperview];
            
        }
    }
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.plotH.constant = ([UIScreen mainScreen].bounds.size.height - 160) / 4;
    [self.view layoutSubviews];
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_yellowTimer invalidate];
    _yellowTimer = nil;
    
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
    
    //currentIndex = [data[@"counter"] integerValue];
    
    [data1 addObject:@{@"index": @(currentIndex), @"data" : data[@"ch1"]}];
    
    [data2 addObject:@{@"index": @(currentIndex), @"data" : data[@"ch2"]}];
    
    [data3 addObject:@{@"index": @(currentIndex), @"data" : data[@"ch3"]}];
    
    [data4 addObject:@{@"index": @(currentIndex), @"data" : data[@"ch4"]}];
    
    
    if(currentIndex > currentRange)
    {
        [data1 removeObjectAtIndex:0];
        [data2 removeObjectAtIndex:0];
        [data3 removeObjectAtIndex:0];
        [data4 removeObjectAtIndex:0];
        
    }
    
    if(currentView == 1)
    {
       
        
        if(currentIndex % limit == 0)
        {
           
            CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph1.defaultPlotSpace;
            if(currentIndex > currentRange)
            {
                plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(currentIndex - currentRange) length:CPTDecimalFromInteger(currentRange)];
                plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(-(scopeRaw/2)) length:CPTDecimalFromInteger(scopeRaw)];
            }
            
            
            CPTXYPlotSpace *plotSpace2 = (CPTXYPlotSpace *)self.graph2.defaultPlotSpace;
            if(currentIndex > currentRange)
            {
                plotSpace2.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(currentIndex - currentRange) length:CPTDecimalFromInteger(currentRange)];
                plotSpace2.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(-(scopeRaw/2)) length:CPTDecimalFromInteger(scopeRaw)];
            }
            
            
            CPTXYPlotSpace *plotSpace3 = (CPTXYPlotSpace *)self.graph3.defaultPlotSpace;
            if(currentIndex > currentRange)
            {
                plotSpace3.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(currentIndex - currentRange) length:CPTDecimalFromInteger(currentRange)];
                plotSpace3.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(-(scopeRaw/2)) length:CPTDecimalFromInteger(scopeRaw)];
            }
            
            
            CPTXYPlotSpace *plotSpace4 = (CPTXYPlotSpace *)self.graph4.defaultPlotSpace;
            if(currentIndex > currentRange)
            {
                plotSpace4.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(currentIndex - currentRange) length:CPTDecimalFromInteger(currentRange)];
                plotSpace4.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(-(scopeRaw/2)) length:CPTDecimalFromInteger(scopeRaw)];
            }
            
            [self.graph1 reloadData];
            [self.graph2 reloadData];
            [self.graph3 reloadData];
            [self.graph4 reloadData];
        }
    }

    currentIndex++;
    
}



-(void)fftDataReceived:(NSNotification *)notification
{

    
    
    
    NSDictionary *data = notification.userInfo;
    
    
    [dataFFT1 addObject:@{@"index": @(currentFFTIndex), @"data" : data[@"ch1"]}];
    
    [dataFFT2 addObject:@{@"index": @(currentFFTIndex), @"data" : data[@"ch2"]}];
    
    [dataFFT3 addObject:@{@"index": @(currentFFTIndex), @"data" : data[@"ch3"]}];
    
    [dataFFT4 addObject:@{@"index": @(currentFFTIndex), @"data" : data[@"ch4"]}];
    
    
    
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
    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0) length:CPTDecimalFromDouble(currentRange)];
    plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(-(scopeRaw/2)) length:CPTDecimalFromInteger(scopeRaw)];
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)newGraph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    //x.majorIntervalLength         = CPTDecimalFromDouble(125);
    //x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(10.0);
    //x.minorTicksPerInterval       = 0;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    
    //[[newGraph plotAreaFrame] setPaddingLeft:30.0f];

    
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
    
    newGraph.plotAreaFrame.borderLineStyle = nil;
    
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
    textStyle.color = [CPTColor lightGrayColor];
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
 
    newGraph.plotAreaFrame.borderLineStyle = nil;

    
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
        if( currentView == 2)
        {
            if ( [tickLocation isGreaterThanOrEqualTo:zero] ) {
                dispatch_once(&positiveOnce, ^{
                    CPTMutableTextStyle *newStyle = [axis.labelTextStyle mutableCopy];
                    newStyle.color = [CPTColor lightGrayColor];
                    positiveStyle = newStyle;
                });
                
                theLabelTextStyle = positiveStyle;
            }
            else {
                dispatch_once(&negativeOnce, ^{
                    CPTMutableTextStyle *newStyle = [axis.labelTextStyle mutableCopy];
                    newStyle.color = [CPTColor lightGrayColor];
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
       
    }
    
    axis.axisLabels = newLabels;
    
    return NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Networking

- (void)sendData {
    
    AFHTTPRequestOperationManager *nManager = [AFHTTPRequestOperationManager manager];
    nManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    nManager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    [nManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //nManager.securityPolicy.allowInvalidCertificates = YES;

    
    NSString *URLString = [NSString stringWithFormat:@"http://potbot.elasticbeanstalk.com/api/eegSamples"];
    NSDictionary *params = @{@"deviceId": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                             @"eegIndexes": _manager.rawvalues, @"eegSpectrums" : @[]};
    
    
    //NSData *data = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];

    //NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    
    //NSLog(@"%@", jsonString);
    
    
    [nManager POST:URLString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
}


@end
