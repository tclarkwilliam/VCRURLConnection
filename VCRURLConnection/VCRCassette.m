//
// VCRCassette.m
//
// Copyright (c) 2012 Dustin Barker
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "VCRCassette.h"
#import "VCRCassette_Private.h"
#import "VCRRequestKey.h"
#import "VCR.h"

@implementation VCRCassette

+ (VCRCassette *)cassette {
    return [[VCRCassette alloc] init];
}

+ (VCRCassette *)cassetteWithURL:(NSURL *)url {
    NSData *data = [NSData dataWithContentsOfURL:url];
    return [[VCRCassette alloc] initWithData:data];
}

- (id)init {
    if ((self = [super init])) {
        self.responseDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)initWithJSON:(id)json {
    NSAssert(json != nil, @"Attempted to intialize VCRCassette with nil JSON");
    if ((self = [self init])) {
        for (id recordingJSON in json) {
            VCRRecording *recording = [[VCRRecording alloc] initWithJSON:recordingJSON];
            [self addRecording:recording];
        }
    }
    return self;
}

- (id)initWithData:(NSData *)data {
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSAssert([error code] == 0, @"Attempted to initialize VCRCassette with invalid JSON");
    return [self initWithJSON:json];
    
}

- (id)initWithData:(NSData *)data compareBody:(BOOL)compareBody {
  NSError *error = nil;
  id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  self.compareBody = compareBody;
  NSAssert([error code] == 0, @"Attempted to initialize VCRCassette with invalid JSON");
  return [self initWithJSON:json];
}

- (void)addRecording:(VCRRecording *)recording {
    VCRRequestKey *key = [VCRRequestKey keyForObject:recording
                                         compareBody:self.compareBody];
    NSArray *recordings = self.responseDictionary[key];
    if (!recordings) {
        recordings = @[];
    }
    
    BOOL isIngoreMultipleType = FALSE;
    for (NSString *type in [VCR ignoreMultipleTypes]) {
        if ([recording.URI hasSuffix:type]) {
            isIngoreMultipleType = true;
            break;
        }
    }
    
    NSArray *updatedRecords = [recordings arrayByAddingObject:recording];
    if (isIngoreMultipleType) {
        updatedRecords = @[recording];
    }
    [self.responseDictionary setObject:updatedRecords forKey:key];
}


- (VCRRecording *)recordingForRequestKey:(VCRRequestKey *)key {
    NSArray *recordings = self.responseDictionary[key];
    VCRRecording *recording = recordings.firstObject;
    NSMutableArray *updatedRecords = [NSMutableArray arrayWithArray:recordings];
    if (updatedRecords.count > 1) {
        [updatedRecords removeObjectAtIndex:0];
    }
    self.responseDictionary[key] = updatedRecords;
    return recording;
}

- (BOOL)recordExistsForRequest:(NSURLRequest *)request {
    VCRRequestKey *key = [VCRRequestKey keyForObject:request
                                         compareBody:self.compareBody];
    NSArray *recordings = self.responseDictionary[key];
    return recordings.count > 0;
}

- (VCRRecording *)recordingForRequest:(NSURLRequest *)request {
    VCRRequestKey *key = [VCRRequestKey keyForObject:request
                                         compareBody:self.compareBody];
    return [self recordingForRequestKey:key];
}

- (id)JSON {
    NSMutableArray *jsonRecordings = [NSMutableArray array];
    for (NSArray *recordings in self.responseDictionary.allValues) {
        for (VCRRecording *recording in recordings) {
            [jsonRecordings addObject:[recording JSON]];
        }
    }
    return jsonRecordings;
}

- (NSData *)data {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self JSON]
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    if ([error code] != 0) {
        NSLog(@"Error serializing json data %@", error);
    }
    return data;
}

- (BOOL)isEqual:(VCRCassette *)cassette {
    return [self.responseDictionary isEqual:cassette.responseDictionary];
}

- (NSArray *)allKeys {
    return [self.responseDictionary allKeys];
}

@end
