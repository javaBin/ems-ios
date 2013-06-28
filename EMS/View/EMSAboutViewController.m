//
//  EMSAboutViewController.m
//  EMS
//
//  Created by Chris Searle on 6/28/13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import "EMSAboutViewController.h"

@interface EMSAboutViewController ()

@end

@implementation EMSAboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];

    NSURL *docURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"]];

    [self.web loadData:[NSData dataWithContentsOfURL:docURL] MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:baseURL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
