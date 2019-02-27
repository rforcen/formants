//
//  Vectorf.m
//  voiceXplorer
//
//  Created by asd on 17/10/2018.
//  Copyright © 2018 voicesync. All rights reserved.
//

#import "RealArray.h"

const int sizeReal=sizeof(real);

@implementation RealArray
+(RealArray*)init {
    RealArray*v=[[super alloc]init];
    return v;
}
+(RealArray*)initWithSize:(int)size {
    RealArray*v=[[super alloc]init];
    v.n=size;
    v.data=calloc(size, sizeReal);
    return v;
}
+(RealArray*)initWithArray:(RealArray*)org {
    RealArray*v=[[super alloc]init];
    [v copyFromArray:org];
    return v;
}
+(RealArray*)initWithOversampArray:(int)size array:(RealArray*)array {
    RealArray*v=[RealArray initWithSize:size]; // size>array.n
    for (int i=0; i<size; i++)
        v.data[i]=array.data[i % array.n];
    return v;
}
+(RealArray*)initWithReals:(float*)org size:(int)size {
    RealArray*v=[RealArray initWithSize:size];
    memcpy(v.data, org, size*sizeReal);
    return v;
}
-(void)copyFromArray:(RealArray*)org {
    if(_n) free(_data);
    _n=org.n;    
    _data=calloc(_n, sizeReal);
    memcpy(_data, org.data, _n*sizeReal);
}
-(void)copyReals:(void*)org size:(int)size {
    if(_n) free(_data);
    _n=size;
    _data=calloc(_n, sizeReal);
    memcpy(_data, org, _n*sizeReal);
}
-(RealArray*)subarrayWithRange: (NSRange)range {
    RealArray*v=[RealArray initWithSize:(int)range.length];
    for (int i=(int)range.location; i<range.length; i++)
        v.data[i-range.location]=_data[i];
    return v;
}
-(void)add:(RealArray*)ain { // self+=ain
    for (int i=0; i<MIN(_n, ain.n); i++)
        _data[i]+=ain.data[i];
}
-(void)setTozero {
    memset(_data, 0, _n*sizeReal);
}
-(void)calcMaxMin { // update min, max, dist=|max-min|
    _max=-FLT_MAX; _min=FLT_MAX;
    for (int i=0; i<_n; i++) {
        float d=_data[i];
        _max=MAX(_max, d);
        _min=MIN(_min, d);
    }
    _dist=(_min!=_max) ? (_max-_min):1;
}
-(void)scale01 {
    [self calcMaxMin];
    for (int i=0; i<_n; i++)
        _data[i]=(_data[i] - _min) / _dist;
}
-(void)abs {
    for (int i=0; i<_n; i++)
        _data[i]=fabsf(_data[i]); // |data|
}
-(RealArray*)scaleAbs { // scale 0..1 of |data|
    _max=-FLT_MAX; _min=FLT_MAX; // calc max,min of |data|
    for (int i=0; i<_n; i++) {
        float d=_data[i]=fabsf(_data[i]); // data = |data|
        _max=MAX(_max, d);
        _min=MIN(_min, d);
    }
    _dist=(_min!=_max) ? (_max-_min):1;
    for (int i=0; i<_n; i++)  _data[i]=(_data[i]-_min) / _dist;
    return self;
}

-(float)scaledValue:(int)i {
    return (_data[i] - _min) / _dist;
}
-(float)minInRange:(int)from sz:(int)sz {
    float _min=FLT_MAX;
    for (int i=from; i<from+sz; i++) {
        float d=_data[i];
        _min=MIN(_min, d);
    }
    return _min;
}
-(float)maxInRange:(int)from sz:(int)sz {
    float _max=-FLT_MAX;
    for (int i=from; i<from+sz; i++) {
        float d=_data[i];
        _max=MAX(_max, d);
    }
    return _max;
}

-(float)get:(int)i {                return _data[i]; }
-(void)set:(float)f i:(int)i {     _data[i]=f; }
-(void)dealloc { _n=0; free(_data); _data=NULL; }

@end
