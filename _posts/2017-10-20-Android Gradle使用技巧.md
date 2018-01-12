---
layout:     post
title:      "Android Gradle 小技巧"
date:       "2017-10-20 20:00:00"
author:     "ijays"
catalog: true
tags: [Gradle]
---

记录一些在Android 开发中使用到的Gradle 小技巧

### 保存敏感信息

在开发中，可能会使用到一些敏感的信息，比如签名信息或者某些服务的key 等，直接写在如build.gradle 文件中是不合适的。只时候我们可以将信息写入到gradle.properties 这个配置文件当中（实际上也可以新建一个后缀名为 .preperties 的文件）。

这里我在项目根目录中新建了一个名为param.properties 的文件，里面写入了一些appKey 的信息。

```groovy
appKey = XXX  //注意没有加双引号会被当被做int 解析
```

接下来在build.gradle 文件中可以通过Properties 去加载上文的这个文件（如果是直接写在gradle.properties 中则可以略过这一步）。

```groovy
  Properties properties = new Properties();
  properties.load(new FileInputStream(file("../param.properties")))
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
          //注意如果上面没有添加双引号，则需要转义才能被当作String 解析
            buildConfigField("String", "hotfixAppId", "\"${properties['hotfixAppId']}\"")
        }
    }
```

最后在代码中想引用这个appKey 就只需要使用 BuildConfig.appKey 就可以了。

### 配置apk输出名字

在没有配置的情况下，使用Android Studio 默认打包出来文件名是app_debug 或是app_release，每次手动修改十分麻烦，好在可以在build.gradle 文件中配置。

```groovy
 //修改生成的apk名字及输出文件夹
    applicationVariants.all { variant ->
        variant.outputs.each { output ->
            //新名字
            def newName
            //时间戳
            def timeNow
            //输出文件夹
            def outDirectory
            timeNow = getDate()
            outDirectory = output.outputFile.getParent()

            //AutoBuildTest-v1.0.1-xiaomi-release.apk
            newName = 'AutoBuildTest-v' + APP_VERSION + '-' + variant.buildType.name + '.apk'
        }
    
        output.outputFile = new File(output.outputFile.parent, newName);
    }
```



### 第三方Key管理

在Android 开发中，时常会用到一些第三方SDK，例如消息推送、支付等。这些KEY 都是保存在AndroidManifest 文件中，比如：

```xml
    <meta-data
            android:name="com.alibaba.app.appkey"
            android:value="XXX" /> <!-- 请填写你自己的- appKey -->
```

为了方便统一管理，我们可以用一个变量代替，在build.gradle 中动态的替换。

在Manifest 文件中：

```xml
    <meta-data
            android:name="com.alibaba.app.appkey"
            android:value="${ali_push_key}" /> <!-- 请填写你自己的- appKey -->
```

在build.gradle 文件中：

```
debug{
   manifestPlaceholders = [ali_push_key:XXX]
}
release{
   manifestPlaceholders = [ali_push_key:XXX]
}
```



### 查看gradle task执行时间

查看各个task 的执行时间。

Gradle 命令中自带了查看task 执行时间的命令。eg

```shell
./gradlew assembleDebug --profile
```

执行成功后会在项目的build 目录中生成reports 目录，所有的task 执行时间都保存在其中的一个html 文件中。​



