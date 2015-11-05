//
//  NEHTTPEye.m
//  NetworkEye
//
//  Created by coderyi on 15/11/3.
//  Copyright © 2015年 coderyi. All rights reserved.
//

#import "NEHTTPEye.h"

#import "NEHTTPModel.h"
#import "NEHTTPModelManager.h"

@interface NEHTTPEye ()<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;

@property (nonatomic, strong) NSURLResponse *response;

@property (nonatomic, strong) NSMutableData *data;

@property (nonatomic, strong) NSDate *startDate;

@property (nonatomic,strong) NEHTTPModel *ne_HTTPModel;
@end
@implementation NEHTTPEye
@synthesize ne_HTTPModel;

+ (void)load {
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    if ([NSURLProtocol propertyForKey:@"NEHTTPEye" inRequest:request] ) {
        return NO;
    }

    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    [NSURLProtocol setProperty:@YES
                        forKey:@"NEHTTPEye"
                     inRequest:mutableReqeust];

    return [mutableReqeust copy];
}

- (void)startLoading {
    self.startDate = [NSDate date];
    
    
    
   
  
    self.data = [NSMutableData data];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.connection = [[NSURLConnection alloc] initWithRequest:[[self class] canonicalRequestForRequest:self.request] delegate:self startImmediately:YES];
#pragma clang diagnostic pop
   
    ne_HTTPModel=[[NEHTTPModel alloc] init];
    ne_HTTPModel.ne_request=self.request;
    ne_HTTPModel.startDateString=[self stringWithDate:[NSDate date]];

    NSTimeInterval myID=[[NSDate date] timeIntervalSince1970];
    srand((unsigned)time(0));  //不加这句每次产生的随机数不变
    double i =  arc4random() % 100;
    double i1=i/10000;
    ne_HTTPModel.myID=myID+i1;
    
}

- (void)stopLoading {
    [self.connection cancel];
    ne_HTTPModel.ne_response=(NSHTTPURLResponse *)self.response;
    
    ne_HTTPModel.endDateString=[self stringWithDate:[NSDate date]];
    
    
    if ([self.response.MIMEType isEqualToString:@"application/json"]) {
        ne_HTTPModel.receiveJSONData=[self responseJSON];
    }
    [[NEHTTPModelManager defaultManager] addModel:ne_HTTPModel error:nil];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    [[self client] URLProtocol:self didFailWithError:error];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    return YES;
}

- (void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [[self client] URLProtocol:self didReceiveAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection
didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [[self client] URLProtocol:self didCancelAuthenticationChallenge:challenge];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    self.response = response;
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
    [self.data appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
 
    [[self client] URLProtocolDidFinishLoading:self];
   
}

#pragma mark - Utils

-(id) responseJSON {
    
    if(self.data == nil) return nil;
    NSError *error = nil;
    id returnValue = [NSJSONSerialization JSONObjectWithData:[self data] options:0 error:&error];
    if(error) NSLog(@"JSON Parsing Error: %@", error);
    
    return returnValue;
}
- (NSString *)stringWithDate:(NSDate *)date{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

    //zzz表示时区，zzz可以删除，这样返回的日期字符将不包含时区信息。
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];

    NSString *destDateString = [dateFormatter stringFromDate:date];

    return destDateString;
    
}


@end