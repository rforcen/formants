//
//  Vectorf.h
//  voiceXplorer
//
//  Created by asd on 17/10/2018.
//  Copyright © 2018 voicesync. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef float real;

NS_ASSUME_NONNULL_BEGIN

@interface RealArray : NSObject

@property float*data; // use them for speed
@property int n;
@property float max, min, dist;

+(RealArray*)init;
+(RealArray*)initWithSize:(int)size;
+(RealArray*)initWithArray:(RealArray*)org;
+(RealArray*)initWithReals:(float*)org size:(int)size;
+(RealArray*)initWithOversampArray:(int)size array:(RealArray*)array;

-(void)copyFromArray:(RealArray*)org;
-(void)copyReals:(void*)org size:(int)size;
-(void)setTozero;
-(void)calcMaxMin;
-(void)scale01;
-(RealArray*)scaleAbs;
-(void)abs;
-(float)maxInRange:(int)from sz:(int)sz;
-(float)minInRange:(int)from sz:(int)sz;
-(RealArray*)subarrayWithRange: (NSRange)range;
-(void)add:(RealArray*)ain;
-(float)scaledValue:(int)i;
-(float)get:(int)i;
-(void)set:(float)f i:(int)i;
-(void)dealloc;
@end

NS_ASSUME_NONNULL_END
