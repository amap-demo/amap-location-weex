//
//  WXAMapLocation.m
//  WeexDemo
//
//  Created by whj on 2018/10/29.
//  Copyright © 2018年 taobao. All rights reserved.
//

#import "WXAMapLocationModule.h"
#import <AMapLocationKit/AMapLocationKit.h>

@interface WXAMapLocationModule ()<AMapLocationManagerDelegate>

@property (nonatomic,strong) AMapLocationManager *locManager;
@property (nonatomic,copy) WXModuleKeepAliveCallback singleLocCallBack;
@property (nonatomic,copy) WXModuleKeepAliveCallback repeatLocCallBack;

@end

@implementation WXAMapLocationModule

WX_EXPORT_METHOD_SYNC(@selector(getLocation:completionBlock:))
WX_EXPORT_METHOD_SYNC(@selector(watchLocation:interval:repeatLocationBlock:))
WX_EXPORT_METHOD_SYNC(@selector(stopLocation))


/**
 * 获取一次位置,如果当前正在连续定位，调用此方法将会失败
 * @param withReGeocode 是否反地理编码(获取逆地理信息需要联网)
 * @param singleLocCallBack 单次定位完成后的Block
 */
- (void)getLocation:(BOOL)withReGeocode completionBlock:(WXModuleKeepAliveCallback)singleLocCallBack {
    __weak typeof(self) weakSelf = self;
    [self.locManager requestLocationWithReGeocode:withReGeocode completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        NSDictionary *result = [weakSelf createResultDictWithLocation:location LocationReGeocode:regeocode  error:error];
        if (result && singleLocCallBack) {
            singleLocCallBack(result, NO);
        }
    }];
}

/**
 * 持续获取位置信息
 * @param needAddress 是否需要地址信息
 * @param interval 时间间隔(目前此参数无效)
 * @param repeatLocCallBack 继续定位的回调
 */
- (void)watchLocation:(BOOL)needAddress interval:(NSUInteger)interval repeatLocationBlock:(WXModuleKeepAliveCallback)repeatLocCallBack {
    self.repeatLocCallBack = repeatLocCallBack;
    self.locManager.locatingWithReGeocode = needAddress;
    [self.locManager startUpdatingLocation];
}

/**
 * 停止定位
 */
- (void)stopLocation {
    [self.locManager stopUpdatingLocation];
    self.locManager = nil;
}

#pragma mark - AMapLocationDelegate

/**
 *  @brief 连续定位回调函数.注意：如果实现了本方法，则定位信息不会通过amapLocationManager:didUpdateLocation:方法回调。
 *  @param manager 定位 AMapLocationManager 类。
 *  @param location 定位结果。
 *  @param reGeocode 逆地理信息。
 */
- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode {
    if (self.repeatLocCallBack) {
        NSDictionary *result = [self createResultDictWithLocation:location LocationReGeocode:reGeocode error:nil];
        self.repeatLocCallBack(result, YES);
    }
}

#pragma mark - Utils

/**
 * 根据传参构造结果字典
 * @param location 定位信息
 * @param regeocode 反地理编码
 * @param error 错误信息
 * @return 构造好的结果
 */
- (NSDictionary *)createResultDictWithLocation:(CLLocation *)location LocationReGeocode:(AMapLocationReGeocode *)regeocode error:(NSError *)error {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [self setDict:result Value:[self getFormatTime:[NSDate date]] forKey:@"callbackTime"];
    if (location && error.code == 0) {
        [self setDict:result Value:@"0" forKey:@"code"];
        [self setDict:result Value:@(location.coordinate.latitude).description forKey:@"lat"];
        [self setDict:result Value:@(location.coordinate.longitude).description forKey:@"lon"];
        [self setDict:result Value:[self getFormatTime:location.timestamp] forKey:@"locTime"];
        if (!regeocode)  return result;
        [self setDict:result Value:regeocode.formattedAddress forKey:@"addr"];
        [self setDict:result Value:regeocode.city forKey:@"city"];// 更多字段请参考AMapLocationReGeocode头文件中自行添加
    }else {
        [self setDict:result Value:@(error.code).description forKey:@"code"];
        [self setDict:result Value:error.localizedFailureReason forKey:@"errorInfo"];
        [self setDict:result Value:error.localizedDescription forKey:@"errorDetail"];
    }
    return [result copy];
}

- (void)setDict:(NSMutableDictionary *)dict Value:(id)value forKey:(NSString *)key {
    value =  value ? value : @"";
    key = key ? key:@"key";
    [dict setObject:value forKey:key];
}

- (NSString *)getFormatTime:(NSDate*)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSString *timeString = [formatter stringFromDate:date];
    return timeString;
}
#pragma mark - GETTER

- (AMapLocationManager *)locManager {
    if (!_locManager) {
        _locManager = [[AMapLocationManager alloc] init];
        _locManager.delegate = self;
        [_locManager setLocationTimeout:3.0];
        [_locManager setReGeocodeTimeout:3.0];
    }
    return _locManager;
}

@end
