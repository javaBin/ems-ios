//
//  EMSThumbDownloader.m
//  EMS
//
//  Created by Jobb on 24.08.14.
//  Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import "EMSThumbDownloader.h"

@interface EMSThumbDownloader ()<NSURLSessionDownloadDelegate, NSURLSessionDelegate>

@end

@implementation EMSThumbDownloader {
    NSURLSession *_thumbSession;
    
    NSOperationQueue *_serialQueue;
}

static NSString *const EMSThumbDownloaderBackgroundSessionIdentifier = @"EMSThumbDownloaderBackgroundSessionIdentifier";

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _serialQueue = [[NSOperationQueue alloc] init];
        _serialQueue.maxConcurrentOperationCount = 1;
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:EMSThumbDownloaderBackgroundSessionIdentifier];
        _thumbSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:_serialQueue];
       
    }
    return self;
}


- (NSURLSessionDownloadTask *) downloadTaskForURL:(NSURL *) url {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    return [_thumbSession downloadTaskWithRequest:request];
}

#pragma mark - NSURLSessionDownloadDelegate

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}

#pragma mark - NSURLSessionDelegate

@end
