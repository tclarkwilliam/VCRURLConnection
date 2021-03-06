//
// VCRRequest.m
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

#import "VCRRequestKey.h"

@interface VCRRequestKey ()

- (id)initWithRecording:(VCRRecording *)recording;
- (id)initWithRequest:(NSURLRequest *)request;

@property (nonatomic, strong, readwrite) NSString *URI;
@property (nonatomic, strong, readwrite) NSString *method;
@property (nonatomic, strong, readwrite) NSData *requestBody;

@end

@implementation VCRRequestKey

+ (VCRRequestKey *)keyForObject:(id)object {
    if ([object isKindOfClass:[VCRRecording class]]) {
        return [[VCRRequestKey alloc] initWithRecording:object];
    } else if ([object isKindOfClass:[NSURLRequest class]])  {
        return [[VCRRequestKey alloc] initWithRequest:object];
    } else {
        NSAssert(false, @"Attempted to create VCRRequestKey with invalid object: %@", object);
        return nil;
    }
}

+ (VCRRequestKey *)keyForObject:(id)object
                    compareBody:(BOOL)compareBody
{
  VCRRequestKey *key = [self keyForObject:object];
  key.compareBody = compareBody;
  return key;
}

- (id)initWithRecording:(VCRRecording *)recording {
    if ((self = [super init])) {
        self.URI = recording.URI;
        self.method = [recording.method uppercaseString];
        self.requestBody = recording.requestBody;
    }
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request {
    if ((self = [super init])) {
        self.URI = [request.URL absoluteString];
        self.method = [request.HTTPMethod uppercaseString];
        self.requestBody = request.HTTPBody;
    }
    return self;
}

- (id)JSON {
    return @{ @"uri": self.URI };
}

- (BOOL)isEqual:(VCRRequestKey *)key {
    BOOL isDataEqual = TRUE;
    if (self.compareBody) {
        isDataEqual = (!self.requestBody && !key.requestBody) ||
                      [self.requestBody isEqualToData:key.requestBody];
    }
    return [self.method isEqual:key.method] &&
           [self.URI isEqual:key.URI] &&
           isDataEqual;
}

- (NSUInteger)hash {
    NSUInteger bodyHash = 0;
    if (self.compareBody) {
      bodyHash = [self.requestBody hash];
    }
    return [self.method hash] ^ [self.URI hash] ^ bodyHash;
}

- (id)copyWithZone:(NSZone *)zone {
    VCRRequestKey *key = [[[self class] alloc] init];
    if (key) {
        key.URI = [self.URI copyWithZone:zone];
        key.method = [self.method copyWithZone:zone];
        key.requestBody = [self.requestBody copyWithZone:zone];
        key.compareBody = self.compareBody;
    }
    return key;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<VCRRequestKey %@ %@>", self.method, self.URI];
}

@end
