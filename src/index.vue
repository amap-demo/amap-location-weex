<template>
<div>
  <div class="wrapper">
    <text class="greeting">高德定位SDK weex示例!</text>
    <div @click="onceLocation" class="button">
			<text style="color:#FFFFFF">单次定位</text>
		</div>
    <div @click="watchLocation" class="button">
			<text style="color:#FFFFFF">连续定位</text>
		</div>
		<div @click="stopLocation" class="button">
			<text style="color:#FFFFFF">停止定位</text>
		</div>



  </div>
  <div class="panel">
      <text class="text">{{result}}</text>
  </div>
  </div>
</template>

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
              this.result = '单次-定位失败\n，errorCode:' + loc.code + '\n错误说明：' + loc.errorDetail
              console.error('单次-定位失败：' + loc.code + "," + loc.errorDetail)
            } else {
              str = '单次-定位成功\n'
              + '经纬度：' + loc.lon + ',' + loc.lat + '\n'
              if(loc.addr != 'undefined' && loc.addr != null && loc.addr != ''){
                str += '地址：' + loc.addr +'\n'
              }
              str += '回调时间：' + loc.locTime
              this.result = str
            }
           });
       },
			watchLocation: function() {
        weex.requireModule('amapLocation').watchLocation(false, 2000, loc => {
        var str;
        if(loc.code != 0){
          this.result = '多次-定位失败\n，errorCode:' + loc.code + '\n错误说明：' + loc.errorDetail
          console.error('多次-定位失败：' + loc.code + "," + loc.errorDetail)
        } else {
          str = '多次-定位成功\n'
          + '经纬度：' + loc.lon + ',' + loc.lat + '\n'
          if(loc.addr != 'undefined' && loc.addr != null && loc.addr != ''){
            str += '地址：' + loc.addr +'\n'
          }
          str += '回调时间：' + loc.locTime
          this.result = str
        }
       });
			},
			stopLocation: function() {
        weex.requireModule('amapLocation').stopLocation();
          this.result = '已停止定位';
			},
		}
}
</script>

<style scoped>
  .wrapper {
    justify-content: top;
    align-items: center;
  }

  .panel {
    flex-direction: column;
    justify-content: left;
    border-width: 2px;
    border-style: solid;
    border-color: rgb(162, 217, 192);
    background-color: rgba(162, 217, 192, 0.2);
  }

  .greeting {
    text-align: center;
    margin-top: 70px;
    font-size: 50px;
    color: #41B883;
  }
  .message {
    margin: 30px;
    font-size: 32px;
    color: #727272;
  }
  .button {
		margin: 20px;
		padding:20px;
		background-color:#1BA1E2;
		color:#FFFFFF;
	}
	.text {
    font-size: 30px;
    text-align: left;
    padding-left: 25px;
    padding-right: 25px;
    color: #41B883;
  }
</style>
