package com.amap.amaplocation.weex;

import android.text.TextUtils;
import android.util.Log;

import com.alibaba.weex.plugin.annotation.WeexModule;
import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;
import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;
import com.taobao.weex.common.WXModule;

import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

/**
 * @author hongming.wang
 * @date 2018/9/18
 * @mail hongming.whm@alibaba-inc.com
 */
@WeexModule(name = "amapLocation")
public class WXAMapLocationModule extends WXModule {

    private JSCallback keepCallBack = null;
    private AMapLocationClient locationClient = null;
    private AMapLocationClientOption locationOption = null;

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

    AMapLocationListener locationListener = new AMapLocationListener() {
        @Override
        public void onLocationChanged(AMapLocation location) {
            Map<String, Object> resultMap = buildLocationResult(location);
            if (null != resultMap
                    && resultMap.size() > 0
                    && null != keepCallBack) {
                //回调结果给JS,此方法可以连续回调
                keepCallBack.invokeAndKeepAlive(resultMap);
            }
        }
    };

    /**
     * 拼接定位结果
     * @param location
     * @return
     */
    private Map<String, Object> buildLocationResult(AMapLocation location) {
        if (null != location) {
            int errorCode = location.getErrorCode();
            Map<String, Object> resultMap = new HashMap<String, Object>();
            resultMap.put("callbackTime", formatUTC(System.currentTimeMillis(), null));
            if (errorCode == AMapLocation.LOCATION_SUCCESS) {
                resultMap.put("code", 0);
                resultMap.put("lat", location.getLatitude());
                resultMap.put("lon", location.getLongitude());
                resultMap.put("addr", location.getAddress());
                resultMap.put("locTime", formatUTC(location.getTime(), null));
            } else {
                resultMap.put("code", location.getErrorCode());
                resultMap.put("errorInfo", location.getErrorInfo());
                resultMap.put("errorDetail", location.getLocationDetail());
            }
            return resultMap;
        }
        return null;
    }

    /**
     * 格式化时间
     *
     * @param l
     * @param strPattern
     * @return
     */
    private String formatUTC(long l, String strPattern) {
        if (TextUtils.isEmpty(strPattern)) {
            strPattern = "yyyy-MM-dd HH:mm:ss";
        }
        SimpleDateFormat sdf = new SimpleDateFormat(strPattern, Locale.CHINA);
        return sdf == null ? "NULL" : sdf.format(l);
    }

}
