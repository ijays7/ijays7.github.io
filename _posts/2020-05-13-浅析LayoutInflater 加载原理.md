在Android 开发中，我们经常会遇到使用LayoutInflater 的场景，如RecyclerView 显示item 布局，Activity 使用setContentView 方法设置layout 等，今天我们就尝试从代码中揭开LayoutInflater 的神秘面纱😊。

## 加载布局文件

我们以  ==setContentView== 作为切入点查看，

```java
  @Override
  public void setContentView(@LayoutRes int layoutResID) {
      getDelegate().setContentView(layoutResID);
  }
```

发现Activity 将填充布局工作委托给了==AppCompatDelegate==，

```java
 @Override
 public void setContentView(int resId) {
      ensureSubDecor();
   // 1. 从顶层ViewGroup 中获取content 容器
      ViewGroup contentParent = mSubDecor.findViewById(android.R.id.content);
   // 2. 移除内部所有View
      contentParent.removeAllViews();
   // 3. 将布局中的View 填充到content 容器中
      LayoutInflater.from(mContext).inflate(resId, contentParent);
      mAppCompatWindowCallback.getWrapped().onContentChanged();
  }
```

跟我们平时动态添加布局一样，这里 ==AppCompatDelegate== 主要做了3 件事情：找到容器，移除内部已有的View，再往里添加View，最核心的当然是第三步，继续往下走。

```java
    public View inflate(@LayoutRes int resource, @Nullable ViewGroup root, boolean attachToRoot) {
      // ... 
      // 通过布局文件id(resource) 获取布局文件解析器
        XmlResourceParser parser = res.getLayout(resource);
        try {
            return inflate(parser, root, attachToRoot);
        } finally {
            parser.close();
        }
    }
```

这里通过 ==getLayout( )== 方法将传入的布局文件id 转换成了Java 对象，这里面是如何实现的呢？继续往下走。

```java
public class ResourcesImpl {   
    @NonNull
    XmlResourceParser loadXmlResourceParser(@NonNull String file, @AnyRes int id, int assetCookie, @NonNull String type) throws NotFoundException {
      // ...
            try {
                synchronized (mCachedXmlBlocks) {
                  // ...
                  // Not in the cache, create a new block and put it at
                  // the next slot in the cache.
                  // 通过 AssetManager 加载布局文件
                    final XmlBlock block = mAssets.openXmlBlockAsset(assetCookie, file);
                    if (block != null) {
                        final int pos = (mLastCachedXmlBlockIndex + 1) % num;
                        mLastCachedXmlBlockIndex = pos;
                        final XmlBlock oldBlock = cachedXmlBlocks[pos];
                        if (oldBlock != null) {
                            oldBlock.close();
                        }
                        cachedXmlBlockCookies[pos] = assetCookie;
                        cachedXmlBlockFiles[pos] = file;
                        cachedXmlBlocks[pos] = block;
                        return block.newParser(id);
                    }
                }
            } catch (Exception e) {
              // 处理异常
            }
        }
    }
}
```

代码跟到这里，终于知道了布局文件是如何被加载的了：在 ==ResourcesImpl== 中通过 ==AssetManager== 调用一个native 方法将布局文件加载到内存，转换成 ==XmlBlock== 对象。

## 解析布局文件

经过上面的分析终于知道布局文件是如何被加载进内存的了，So far so good。继续回到上面的 ==inflate( )==。

```java
 public View inflate(XmlPullParser parser, @Nullable ViewGroup root, boolean attachToRoot) {
        synchronized (mConstructorArgs) {
          // ...
            try {
              // 这里返回从xml 文件中解析好的View 
              // Temp is the root view that was found in the xml
                    final View temp = createViewFromTag(root, name, inflaterContext, attrs);
              
                    if (root != null) {
                     
                        // Create layout params that match root, if supplied
                        params = root.generateLayoutParams(attrs);
                        if (!attachToRoot) {
                            // Set the layout params for temp if we are not
                            // attaching. (If we are, we use addView, below)
                            temp.setLayoutParams(params);
                        }
                    }

                    // 是否将解析好的View 添加到容器中
                    // We are supposed to attach all the views we found (int temp)
                    // to root. Do that now.
                    if (root != null && attachToRoot) {
                        root.addView(temp, params);
                    }
                }
            } catch (Exception e) {
               // 异常处理
            }
            return result;
        }
    }
```

我们可以看到， ==createViewFromTag( )== 返回了Xml 文件中的View，并且根据传入两个参数 ==root== 和 ==attachToRoot== 来判断是否需要加入容器中，接续看 ==createViewFromTag( )==

```java
    View createViewFromTag(View parent, String name, Context context, AttributeSet attrs,
            boolean ignoreThemeAttr) {
      // ...
        try {
          // 调用 tryCreateView 来创建View
            View view = tryCreateView(parent, name, context, attrs);

          // ...
            return view;
        } catch (InflateException e) {
          // 异常处理
        }
    }

```

```java
 public final View tryCreateView(@Nullable View parent, @NonNull String name,
        @NonNull Context context,
        @NonNull AttributeSet attrs) {
        // 这里为什么叫TAG_1995，我也不知道😂😂
        if (name.equals(TAG_1995)) {
            // Let's party like it's 1995!
            return new BlinkLayout(context, attrs);
        }

        View view;
        if (mFactory2 != null) {
            view = mFactory2.onCreateView(parent, name, context, attrs);
        } else if (mFactory != null) {
            view = mFactory.onCreateView(name, context, attrs);
        } else {
            view = null;
        }
        // ...
        return view;
    }
```

上面实际上是调用了 ==tryCreateView( )== ，而这里又会根据 Factory(Factory2) 接口来创建View。查看继承关系发现，最开始接受 ==Activity== 委托的 ==AppCompatDelegateImpl== 实现了 ==LayoutInflater.Factory2== 接口，兜兜转转，又回到了最开始的地方。

```java
    @Override
    public View createView(View parent, final String name, @NonNull Context context,
            @NonNull AttributeSet attrs) {
        if (mAppCompatViewInflater == null) {
            TypedArray a = mContext.obtainStyledAttributes(R.styleable.AppCompatTheme);
            String viewInflaterClassName =
                    a.getString(R.styleable.AppCompatTheme_viewInflaterClass);
            if (viewInflaterClassName == null) {
                // Set to null (the default in all AppCompat themes). Create the base inflater
                // (no reflection)
                mAppCompatViewInflater = new AppCompatViewInflater();
            } else {
                try {
                  // 使用反射创建 AppCompatViewInflater 实例
                    Class<?> viewInflaterClass = Class.forName(viewInflaterClassName);
                    mAppCompatViewInflater =
                            (AppCompatViewInflater) viewInflaterClass.getDeclaredConstructor()
                                    .newInstance();
                } 
              // ...
            }
        }
      // 通过 AppCompatViewInflater 的 createView 来创建 View
        return mAppCompatViewInflater.createView(parent, name, context, attrs, inheritContext,
                IS_PRE_LOLLIPOP, /* Only read android:theme pre-L (L+ handles this anyway) */
                true, /* Read read app:theme as a fallback at all times for legacy reasons */
                VectorEnabledTintResources.shouldBeUsed() /* Only tint wrap the context if enabled */
        );
    }
```

在 ==AppCompatDelegateImpl== 的 ==createView( )== 中，通过反射创建了 ==AppCompatViewInflater== 对象，并且将创建View 的工作又委托给了 ==AppCompatViewInflater.createView( )==。真是麻烦啊，不过很快就能看见曙光了。

```java
  final View createView(View parent, final String name, @NonNull Context context,
            @NonNull AttributeSet attrs, boolean inheritContext,
            boolean readAndroidTheme, boolean readAppTheme, boolean wrapContext) {
     // ... 

        View view = null;

        // We need to 'inject' our tint aware Views in place of the standard framework versions
        switch (name) {
            case "TextView":
                view = createTextView(context, attrs);
                verifyNotNull(view, name);
                break;
        // ...
             if (view == null && originalContext != context) {
            // If the original context does not equal our themed context, then we need to manually
            // inflate it using the name so that android:theme takes effect.
            view = createViewFromTag(context, name, attrs);
        }
 }
    
  @NonNull
  protected AppCompatTextView createTextView(Context context, AttributeSet attrs) {
    // 终于看到了new 对象
        return new AppCompatTextView(context, attrs);
  }
```

Finally！！！在 ==AppCompatViewInflater.createView( )== 中我们真正的看到了Xml 中的View 是如何被new 出来的了。根据Xml 中的标签来返回相应的对象，如 TextView ，ImageView 这种系统提供的View 会通过直接new 对象的方式返回；而像我们平时自定义的View 则会通过反射的方式调用构造方法来创建。

## 总结

至此，我们终于将Android 布局文件加载显示的完整流程走完了，主要有两个步骤：

1. 通过 AssetManger 将布局文件加载进内存，转换成Xml 对象，这是一个IO 操作
2. 遍历上一步解析的Xml 对象，创建相应的View，并将其添加进View 树中

