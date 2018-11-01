## 前述 

1. [高德官网申请Key](http://lbs.amap.com/dev/#/).
2.  阅读[开发指南](http://lbs.amap.com/api/android-location-sdk/locationsummary/).Android/iOS
3.  基于Weex 版本：v1.3.11
4. 本工程是基于React Native环境创建，并不是创建了一个library，如需要修改成library请参考[官网](https://facebook.github.io/react-native/docs/native-modules-setup)

## Weex 环境搭建
请参考[Weex官网](https://weex.apache.org/cn/guide/set-up-env.html)

## 开发 - [Android](#android) / [iOS](#ios)
配置好Weex环境后，下载本工程，可以通过npm install安装之后，通过weex run android/ios 直接运行查看效果

### <a name="android">Android </a> - 引入高德定位SDk的jar包

1. [通过jar包的方式引入](https://lbs.amap.com/api/android-location-sdk/guide/create-project/android-studio-create-project#t2)
2. [通过Gradle方式集成](https://lbs.amap.com/api/android-location-sdk/guide/create-project/android-studio-create-project#t3)


### 配置AndroidManifest.xml
1. 注册定位SDK需求的权限

```
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_LOCATION_EXTRA_COMMANDS"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```
2. 填写您的key

    注意工程中的的key是测试使用的key，在使用过程中请使用自己的key

```
<meta-data
        android:name="com.amap.api.v2.apikey"
        android:value="您的key"/>
```
3. 注册定位service

```
<service android:name="com.amap.api.location.APSService"/>
```

### 关键代码
#### 编写模块
##### WXAMapLocationModule.java

注解方式指定Module名称
```
@WeexModule(name = "amapLocation")
public class WXAMapLocationModule extends WXModule
```

通过@JSMethod暴露方法给js

```
/**
     * 获取一次位置
     * @param needAddress 是否需要逆地理信息
     * @param jsCallback
     */
    @JSMethod(uiThread = true)
    public void getLocation(boolean needAddress, final JSCallback jsCallback) {
        if (null == locationOption) {
            locationOption = new AMapLocationClientOption();
        }
        /**
         * 设置定位模式为高精度模式，实际开发中可以根据需要自行设置
         */
        locationOption.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy);
        locationOption.setOnceLocation(true);
        locationOption.setNeedAddress(needAddress);

        if (null == locationClient) {
            locationClient = new AMapLocationClient(mWXSDKInstance.getContext());
        }
        locationClient.setLocationOption(locationOption);
        locationClient.setLocationListener(new AMapLocationListener() {
            @Override
            public void onLocationChanged(AMapLocation location) {
                Map<String, Object> resultMap = buildLocationResult(location);
                if (null != resultMap
                        && resultMap.size() > 0
                        && null != jsCallback) {
                    //回调结果给JS
                    jsCallback.invoke(resultMap);
                }
            }
        });
        locationClient.startLocation();
    }

    /**
     * 持续获取位置信息
     * @param needAddress 是否需要地址信息
     * @param interval 定位间隔
     * @param jsCallback
     */
    @JSMethod(uiThread = true)
    public void watchLocation(boolean needAddress, int interval, JSCallback jsCallback) {
        if (null == locationOption) {
            locationOption = new AMapLocationClientOption();
        }
        keepCallBack = jsCallback;
        /**
         * 设置定位模式为高精度模式，实际开发中可以根据需要自行设置
         */
        locationOption.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy);
        locationOption.setNeedAddress(needAddress);
        locationOption.setOnceLocation(false);
        /**
         * 定位间隔，单位毫秒
         */
        locationOption.setInterval(interval);
        if(null != locationClient){
            locationClient.stopLocation();
            locationClient.onDestroy();
            locationClient = null;
        }
        locationClient = new AMapLocationClient(mWXSDKInstance.getContext());

        locationClient.setLocationOption(locationOption);
        locationClient.setLocationListener(locationListener);
        locationClient.startLocation();
    }

    /**
     * 停止定位
     */
    @JSMethod(uiThread = true)
    public void stopLocation() {
        if (null != locationClient) {
            locationClient.stopLocation();
            locationClient.onDestroy();
            locationClient = null;
        }
    }
```
#### 注册模块
在WXApplication中添加以下代码
```
WXSDKEngine.registerModule("amapLocation", WXAMapLocationModule.class);
```
##### 编写AMapLocationPackage类实现ReactPackage接口
```
@Override
public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
    List<NativeModule> modules = new ArrayList<NativeModule>();
    modules.add(new AMapLocationModule(reactContext));
    return modules;
}

@Override
public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
    return Collections.emptyList();
}
```


## <a name="ios">iOS </a> 集成高德定位SDK的`AMapLocation`
1. 通过framework集成，从高德开放平台官网下载[定位SDK](https://lbs.amap.com/api/ios-location-sdk/download)，拖入工程方式集成
2. 通过cocoapods集成，进入项目目录platforms/ios/ 打开Podfile文件，添加`pod 'AMapLocation'`,然后在iOS目录下执行`pod install`

#### 注：使用pod集成时候，WeexSDK 写为`pod 'WeexSDK', '0.18.0.3'`这版本，目前最新版`0.19.0`会出现报错，出现白屏问题 (2018.11.1)

***

### 配置Xcode工程

1. plist文件权限,在项目info.plist文件中，加入一下权限

  ```
       <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
      <string>路过导航需要您的定位服务，否则可能无法使用，如果您需要使用后台导航功能请选择“始终允许”。</string>
       <key>NSLocationAlwaysUsageDescription</key>
      <string>路过导航需要您的定位服务，否则可能无法使用。</string>
       <key>NSLocationWhenInUseUsageDescription</key>
      <string>路过导航需要您的定位服务，否则可能无法使用。</string>
  ```
2. 填写您的key **注意**:工程中的的key是测试使用的key，在使用过程中请使用自己的key

  ```
  // 这里是到 https://lbs.amap.com/dev/key/app 开放平台申请应用的key，设置到这里
    [AMapServices sharedServices].apiKey =@"您的key";
  ```
  
  
### 关键代码
#### 编写模块 **WXAMapLocationModule**


    ```
    #import "WXAMapLocationModule.h"
    #import <AMapLocationKit/AMapLocationKit.h>

    @interface WXAMapLocationModule ()<AMapLocationManagerDelegate>
    @property (nonatomic,strong) AMapLocationManager *locManager;
    @property (nonatomic,copy) WXModuleKeepAliveCallback singleLocCallBack;
    @property (nonatomic,copy) WXModuleKeepAliveCallback repeatLocCallBack;
    @end

    @implementation WXAMapLocationModule
    
    ###Js中调用 在src/index.vue中实现对定位的调用
    
    WX_EXPORT_METHOD_SYNC(@selector(getLocation:completionBlock:))
    WX_EXPORT_METHOD_SYNC(@selector(watchLocation:interval:repeatLocationBlock:))
    WX_EXPORT_METHOD_SYNC(@selector(stopLocation))


    /**
     * 获取一次位置,如果当前正在连续定位，调用此方法将会失败
     * @param withReGeocode 是否反地理编码(获取逆地理信息需要联网)
     * @param singleLocCallBack 单次定位完成后的Block
     */
    - (void)getLocation:(BOOL)withReGeocode completionBlock: (WXModuleKeepAliveCallback)singleLocCallBack {
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

    // 定位回调代理

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
    
    ```
    
###  注册模块
* 在`WeexSDKManager`类中注册模块
  `[WXSDKEngine registerModule:@"amapLocation" withClass:[WXAMapLocationModule class]];`




###Js中调用
在src/index.vue中实现对定位的调用

```
<script>
export default {
  name: '高德定位示例',
  data () {
        return {
          result: '',
        }
      },
  methods: {
      onceLocation: function() {
         weex.requireModule('amapLocation').getLocation(true, loc => {
            var str;
            if(loc.code != 0){
              this.result = '定位失败\n，errorCode:' + loc.code + '\n错误说明：' + loc.errorDetail
              console.error('定位失败：' + loc.code + "," + loc.errorDetail)
            } else {
              str = '定位成功\n'
              + '经纬度：' + loc.lon + ',' + loc.lat + '\n'
              if(loc.addr != 'undefined' && loc.addr != null && loc.addr != ''){
                str += '地址：' + loc.addr +'\n'
              }
              str += '回调时间：' + loc.callbackTime
              this.result = str
            }
           });
       },
      watchLocation: function() {
        weex.requireModule('amapLocation').watchLocation(false, 2000, loc => {
        var str;
        if(loc.code != 0){
          this.result = '定位失败\n，errorCode:' + loc.code + '\n错误说明：' + loc.errorDetail
          console.error('定位失败：' + loc.code + "," + loc.errorDetail)
        } else {
          str = '定位成功\n'
          + '经纬度：' + loc.lon + ',' + loc.lat + '\n'
          if(loc.addr != 'undefined' && loc.addr != null && loc.addr != ''){
            str += '地址：' + loc.addr +'\n'
          }
          str += '回调时间：' + loc.callbackTime
          this.result = str
        }
       });
      },
      stopLocation: function() {
        weex.requireModule('amapLocation').stopLocation();
      },
    }
}
</script>
```

## 运行

```
//在android、iOS设备上运行
weex run android / ios
```