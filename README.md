##  前述 

1. [高德官网申请Key](http://lbs.amap.com/dev/#/).
2.  阅读[开发指南](http://lbs.amap.com/api/android-location-sdk/locationsummary/).Android
3.  基于Weex 版本：0.56.0
4. 本工程是基于React Native环境创建，并不是创建了一个library，如需要修改成library请参考[官网](https://facebook.github.io/react-native/docs/native-modules-setup)

## Weex 环境搭建
请参考[Weex官网](https://weex.apache.org/cn/guide/set-up-env.html)

## 开发
配置好Weex环境后，下载本工程，可以通过weex run android 直接运行查看效果

### 引入高德定位SDk的jar包

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
//在android设备上运行
weex run android 
```
