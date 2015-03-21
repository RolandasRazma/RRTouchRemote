//
//  RRDMAP.h
//  BonjourWeb
//
//  Created by Rolandas Razma on 20/03/2015.
//
//

#import <Foundation/Foundation.h>


@interface RRDMAP : NSObject

+ (NSData *)dataFromDictionary:(NSDictionary *)dictionary;
+ (NSDictionary *)dictionaryFromData:(NSData *)data;

@end
