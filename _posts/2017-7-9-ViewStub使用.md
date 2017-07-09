---
layout:     post
title:      "ViewStub的使用"
date:       "2017-7-9 20:00:00"
author:     "ijays"
catalog: true
tags: [View, Android]
---

ViewStub 的使用

## 介绍

一般在介绍Android 布局优化的时候，都会说到使用include 标签，merge 标签和ViewStub，前两个使用的频率还比较高，后者相对来说使用就不是那么频繁了。前几天刚好做一个error 的界面，并不想一开始就将资源加载进内存中，然后改变visibility，于是就想到了使用ViewStub，这里记录下ViewStub 的使用，方便以后查看。

## 使用

正如前文所说，ViewStub 最大的特点是按需加载，即一开始并不将加载到内存中，在需要显示的时候，才去渲染整个布局，因此它非常轻量级，几乎可以无视。

下面是ViewStub 中显示的布局：

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

    <ImageView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="center_horizontal"
        android:layout_marginTop="113dp"
        android:src="@drawable/calling_overtime" />

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="center_horizontal"
        android:layout_marginTop="30dp"
        android:text="请求超时"
        android:textColor="#484c50"
        android:textSize="32sp" />

</LinearLayout>
```

xml 中使用ViewStub：

```xml
 <Button
        android:id="@+id/bt_view_stub_inflate"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="viewstub inflate" />

    <!-- layout 属性中声明需要加载的布局文件，
         还有一个inflateId属性声明所加载布局文件的根布局id-->
    <ViewStub
        android:id="@+id/view_stub"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_marginTop="30dp"
        android:layout="@layout/view_stub_layout" />
```

xml 文件中定义好后，有两种方式来显示ViewStub。

- visible

调用ViewStub 的setVisibility() 方法来显示这个View，即

```java
mViewStub.setVisibility(View.VISIBLE);
```

- inflate

通过ViewStub 的inflate() 方法来显示这个View，即

```java
View inflatedView = mViewStub.inflate();
```

这两种方式的区别从上面的使用也可以出来了，后者可以获取到inflate 进去的View，然后动态的去修改具体的显示。这里我们可以看下ViewStub 的inflate 实现。

```java
public View inflate() {
        //获取父容器 
        final ViewParent viewParent = getParent();

        if (viewParent != null && viewParent instanceof ViewGroup) {
            if (mLayoutResource != 0) {
              //mLayoutResource 即ViewStub 显示的View
                final ViewGroup parent = (ViewGroup) viewParent;
                final LayoutInflater factory;
                if (mInflater != null) {
                    factory = mInflater;
                } else {
                    factory = LayoutInflater.from(mContext);
                }
              //生成需要加载的View
                final View view = factory.inflate(mLayoutResource, parent,
                        false);

                if (mInflatedId != NO_ID) {
                    view.setId(mInflatedId);
                }

                final int index = parent.indexOfChild(this);
                //从父布局中移除ViewStub
                parent.removeViewInLayout(this);

                final ViewGroup.LayoutParams layoutParams = getLayoutParams();
              //将显示的View 加入parent 中
                if (layoutParams != null) {
                    parent.addView(view, index, layoutParams);
                } else {
                    parent.addView(view, index);
                }

                mInflatedViewRef = new WeakReference<View>(view);

                if (mInflateListener != null) {
                  //设置inflate 回调
                    mInflateListener.onInflate(this, view);
                }

                return view;
            } else {
                throw new IllegalArgumentException("ViewStub must have a valid layoutResource");
            }
        } else {
            throw new IllegalStateException("ViewStub must have a non-null ViewGroup viewParent");
        }
    }

```

从上面的代码中我们我们就可以为之前的结论找到证据了。在调用inflate() 方法后，ViewStub 才会根据设置的layout 生成View，将其add 到父布局中，同时自身也完成使命，将自己的位子移交给inflate 的View。也正因为ViewStub 的这种实现，导致了ViewStub不能inflate 两次，因为在都不在了啊。

## 最后

基于ViewStub 的特性，适合那种在初始化时不需要显示，只在某些情况下才显示并且频次不高的界面，虽然使用有局限性，但相比初始化就已经加载在布局树上，ViewStub 显然更具效率。

