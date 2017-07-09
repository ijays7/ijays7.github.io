---
layout:     post
title:      "发布lib到jCenter&MavenCentral"
date:       "2017-04-18 20:59:00"
author:     "ijays"
catalog: true
tags: [jCenter]
---



## 注册账号

首先我们需要到https://bintray.com/ 这个网站去注册账号（需自备梯子），完成后在profile 中找到API KEY，先复制下后面有用。

![](http://upload-images.jianshu.io/upload_images/565012-53408b0c5da6b799.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1080)

## 创建Maven 仓库

点击创建一个仓库。

![](http://upload-images.jianshu.io/upload_images/565012-22779e49e24bcb11.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/500)

这里Name 需命名为Maven，类型也为Maven。

![](http://upload-images.jianshu.io/upload_images/565012-6c8f355d963979f9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1080)

## 创建项目

新建一个Project，在其build.gradle 文件中添加如下依赖：

```groovy
 classpath 'com.jfrog.bintray.gradle:gradle-bintray-plugin:1.7.3'
 classpath 'com.github.dcendents:android-maven-gradle-plugin:1.5'
```

## 编写上传脚本

接下来需要在需要上传lib 的gradle 文件中编写脚本。

添加plugin：

```groovy
apply plugin: 'com.github.dcendents.android-maven'
apply plugin: 'com.jfrog.bintray'
```

 生成pom 文件：

```groovy
 // 项目地址
def siteUrl = "https://github.com/example"
//项目的git 地址
def gitUrl = "https://github.com/example.git"

group = "com.ijays"//定义groupId，即compile 'group:name:version'
version = "0.3.0"

install {
    repositories.mavenInstaller {
        // This generates POM.xml with proper paramters
        pom.project {
            packaging 'aar'

            // Add your description here
            name 'example'//lib 的名字
            url siteUrl

            // Set your license
            licenses {
                license {
                    name 'The Apache Software License, Version 2.0'
                    url 'http://www.apache.org/licenses/LICENSE-2.0.txt'
                }
            }

            developers {
                developer {
                    id 'ijays7'
                    name 'ijays7'
                    email 'ijaysdev#gmail.com'
                }
            }

            scm {
                connection gitUrl
                developerConnection gitUrl
                url siteUrl
            }
        }
    }
}
```

上传到jCenter 并通过审核还需要javadocjar 和sourcejar，我们可以通过以下脚本生成：

```groovy
task sourcesJar(type: Jar) {
    from android.sourceSets.main.java.srcDirs
    classifier = 'sources'
}
task javadoc(type: Javadoc) {
    source = android.sourceSets.main.java.srcDirs
    classpath += project.files(android.getBootClasspath().join(File.pathSeparator))
}
task javadocJar(type: Jar, dependsOn: javadoc) {
    classifier = 'javadoc'
    from javadoc.destinationDir
}
artifacts {
    archives javadocJar
    archives sourcesJar
}
```

接下来最关键的一步配置，将项目上传到bintray。这就需要用到之前复制的API KEY。由于我们会将项目托管到诸如GitHub 这样的开源网站，任何人都能看到源码，因此我们将私钥KEY 写入local.properties 这个不会被加入到版本控制的文件中，格式如下：

```groovy
bintray.user=你的名字
bintray.apikey=API KEY
```

build.gradle 文件中：

```groovy
Properties properties = new Properties()
properties.load(project.rootProject.file('local.properties').newDataInputStream())

bintray {
    user = properties.getProperty("bintray.user")
    key = properties.getProperty("bintray.apikey")
    configurations = ['archives']
    pkg {
        repo = "maven"
        name = "lib 的名字"
        websiteUrl = siteUrl
        vcsUrl = gitUrl
        licenses = ["Apache-2.0"]
        publish = true
    }
}
```

上面的代码中即是读取local.properties 文件中的user 和key 字段，最后配置项目的参数，十分简单的代码。但笔者在此纠结了好久，因为最开始看到网上的写法是

```groovy
Properties properties = new Properties()
if (project.rootProject.findProject('local.properties') != null) {
  //这样写一直没有成功，私以为可能和使用的Android 版本有关系，导致没有拿到user 和key 的值
    properties.load(project.rootProject.file('local.properties').newDataInputStream())
}
```

## 上传到bintray

至此，准备工作都做完了，最后只需要分别在命令行中执行

```groovy
//编译生成aar 文件
gradle build 
//上传到bintray
gradle bintrayUpload
```

当看到下图时就表示已经上传成功。

![](http://upload-images.jianshu.io/upload_images/565012-3c6e9d5ffc16db79.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/500)

再来看看bintray 网站上面，已经可以看到我们上传的lib，而在我们的项目中也已经可以以maven 的方式引用了，但一般我们通过jCenter来使用，这是只需要点击关联到jCenter ，输入发布lib 的描述即可。一般来说，少则2到3小时，多则1天，我们的lib 就会通过审核，之后每次update 就是立即生效了。

![](http://upload-images.jianshu.io/upload_images/565012-60aab8801b6ffc42.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/720)



![](http://upload-images.jianshu.io/upload_images/565012-98963ee45e555738.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/720)



