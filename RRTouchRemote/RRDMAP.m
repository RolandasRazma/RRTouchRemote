//
//  RRDMAP.m
//  RRTouchRemote
//
//  Created by Rolandas Razma on 20/03/2015.
//  Copyright (c) 2015 Rolandas Razma. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "RRDMAP.h"
#include "dmap_parser.h"


static void on_dict_start(void *ctx, const char *code, const char *name) {
    NSMutableArray *stack = (__bridge NSMutableArray *)(ctx);
    
    id topObject = [stack lastObject];
    
    NSMutableDictionary *newDictionary = [NSMutableDictionary dictionary];
    NSString *key = [NSString stringWithUTF8String:name];

    id objectAtKey;
    if( (objectAtKey = [topObject objectForKey:key]) || [key isEqualToString:@"dmap.listingitem"] ){
        if( ![objectAtKey isKindOfClass: [NSArray class]] ){
            objectAtKey = (( objectAtKey )?[NSMutableArray arrayWithObject:objectAtKey]:[NSMutableArray array]);
            [topObject setObject:objectAtKey forKey:key];
        }
        
        [objectAtKey addObject: newDictionary];
    }else if( [topObject isKindOfClass:[NSDictionary class]] ){
        [topObject setObject:newDictionary forKey:key];
    }

    [stack addObject: newDictionary];
}

static void on_dict_end(void *ctx, const char *code, const char *name) {
    NSMutableArray *stack = (__bridge NSMutableArray *)(ctx);
    [stack removeObjectAtIndex: stack.count -1];
}

static void on_int32(void *ctx, const char *code, const char *name, int32_t value) {
    NSMutableArray *stack = (__bridge NSMutableArray *)(ctx);
    [[stack lastObject] setValue: @(value)
                          forKey: [NSString stringWithUTF8String:name]];
    
}

static void on_int64(void *ctx, const char *code, const char *name, int64_t value) {
    NSMutableArray *stack = (__bridge NSMutableArray *)(ctx);
    [[stack lastObject] setValue: @(value)
                          forKey: [NSString stringWithUTF8String:name]];
}

static void on_uint32(void *ctx, const char *code, const char *name, uint32_t value) {
    NSMutableArray *stack = (__bridge NSMutableArray *)(ctx);
    [[stack lastObject] setValue: @(value)
                          forKey: [NSString stringWithUTF8String:name]];
}

static void on_uint64(void *ctx, const char *code, const char *name, uint64_t value) {
    NSMutableArray *stack = (__bridge NSMutableArray *)(ctx);
    [[stack lastObject] setValue: @(value)
                          forKey: [NSString stringWithUTF8String:name]];
}

static void on_date(void *ctx, const char *code, const char *name, uint32_t value) {
    time_t timeval = value;
    struct tm *timestruct = gmtime(&timeval);
    
    timestruct->tm_isdst = -1;
    time_t t = mktime(timestruct);
    
    NSMutableArray *stack = (__bridge NSMutableArray *)(ctx);
    [[stack lastObject] setValue: [NSDate dateWithTimeIntervalSince1970:t +[[NSTimeZone localTimeZone] secondsFromGMT]]
                          forKey: [NSString stringWithUTF8String:name]];
}

static void on_string(void *ctx, const char *code, const char *name, const char *buf, size_t len) {

    char *str = (char *)malloc(len +1);
    strncpy(str, buf, len);
    str[len] = '\0';

    NSMutableArray *stack = (__bridge NSMutableArray *)(ctx);
    [[stack lastObject] setValue: [NSString stringWithUTF8String:str]
                          forKey: [NSString stringWithUTF8String:name]];
    
    free(str);

}

static void on_data(void *ctx, const char *code, const char *name, const char *buf, size_t len) {
    NSMutableArray *stack = (__bridge NSMutableArray *)(ctx);
    [[stack lastObject] setValue: [NSData dataWithBytes:buf length:len]
                          forKey: [NSString stringWithUTF8String:name]];
}


@implementation RRDMAP


#pragma mark -
#pragma mark RRDMAP


+ (NSData *)dataFromDictionary:(NSDictionary *)dictionary {
    NSMutableData *mutableData = [NSMutableData data];
    
    [dictionary enumerateKeysAndObjectsUsingBlock: ^(NSString *key, id obj, BOOL *stop) {
        
        [mutableData appendBytes: [key UTF8String]
                          length: [key lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
        
        if( [obj isKindOfClass:[NSNumber class]] ){
            uint32_t valueLength = htonl(sizeof(uint32_t));
            [mutableData appendBytes:&valueLength length:sizeof(valueLength)];
            
            uint32_t bits = htonl((uint32_t)[obj unsignedIntValue]);
            [mutableData appendBytes:&bits length:sizeof(uint32_t)];
        }else if( [obj isKindOfClass:[NSString class]] ){
            const char *value = [obj UTF8String];
            
            uint32_t valueLength = htonl((uint32_t)strlen(value));
            [mutableData appendBytes:&valueLength length:sizeof(valueLength)];
            
            [mutableData appendBytes:value length:strlen(value)];
        }else if( [obj isKindOfClass:[NSDictionary class]] ){
            NSData *data = [self dataFromDictionary:obj];
            
            uint32_t bits = htonl((uint32_t)data.length);
            [mutableData appendBytes:&bits length:sizeof(uint32_t)];
            
            [mutableData appendData:data];
        }else{
            NSAssert(NO, @"Unhandled type");
        }
        
    }];
    
    return [mutableData copy];
}


+ (NSDictionary *)dictionaryFromData:(NSData *)data {
    
    NSMutableArray *stack = [NSMutableArray arrayWithObject: [NSMutableDictionary dictionary]];
    
    dmap_settings settings = {
        .on_dict_start = on_dict_start,
        .on_dict_end   = on_dict_end,
        .on_int32      = on_int32,
        .on_int64      = on_int64,
        .on_uint32     = on_uint32,
        .on_uint64     = on_uint64,
        .on_date       = on_date,
        .on_string     = on_string,
        .on_data       = on_data,
        .ctx           = (__bridge void *)(stack)
    };
    
    dmap_parse(&settings, [data bytes], data.length);
    
    NSAssert(stack.count == 1, @"Stack is too big?");
    
    return stack.count?stack[0]:nil;
    
}


@end
