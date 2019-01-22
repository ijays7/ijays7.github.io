---
layout:     post
title:      "RxLifecycle原理解析"
date:       "2019-01-22 20:00:00"
author:     "ijays7"
catalog: true
tags: [RxLifecycle,原理分析,RxJava]
---

## 前言

我们在使用 RxJava 的时候，往往会惊诧于它带来的便利，但同时他也是一把双刃剑，如果开发人员不注意，那么就极有可能造成内存泄露。千里之堤，溃于蚁穴，过多的内存泄漏最终会拖垮我们的应用，大大的影响体验。鉴于此种情况，一波聪明的工程师想到了一些巧妙的解决方案，其中一个就是就是本文的主角 **RxLifecycle**

## 使用

1. 首先在 build.gradle 中引入依赖：

   ```groovy
   // 截止2019.01.22版本为3.0.0
   implementation 'com.trello.rxlifecycle3:rxlifecycle:3.0.0'
   // If you want to bind to Android-specific lifecycles
   implementation 'com.trello.rxlifecycle3:rxlifecycle-android:3.0.0'
   // If you want pre-written Activities and Fragments you can subclass as providers
   implementation 'com.trello.rxlifecycle3:rxlifecycle-components:3.0.0'
   ```

2. RxLifecycle 有多种配置方式，具体可以查看[官方文档](https://github.com/trello/RxLifecycle) ，这里介绍最简单直接的一种方式，直接继承 RxAcitivty/RxFragment 等

   ```java
   public class MainActivity extends RxActivity {
       ...
   }
   ```

3. 接下来就是代码调用来自动解除订阅，这里有两种方式

   第一种是直接在发射数据的时候和生命周期绑定:

   ```java
    RetrofitClient.getInstance().updateMallGoods(g).subscribeOn(Schedulers.io())
                       .observeOn(AndroidSchedulers.mainThread())
                       .compose(this.bindToLifecycle())
                       .subscribe({
                          Log.e("TAG","success")
                       }, {
                          Log.e("TAG","failed==>")
                       })
   ```

   第二种是调用 bindUntilEvent() 在特定的生命周期来取消订阅，比如ActivityEvent.DESTROY：

   ```java
    RetrofitClient.getInstance().updateMallGoods(g).subscribeOn(Schedulers.io())
                       .observeOn(AndroidSchedulers.mainThread())
                       .compose(this.bindUntilEvent(ActivityEvent.DESTROY))
                       .subscribe({
                          Log.e("TAG","success")
                       }, {
                          Log.e("TAG","failed==>")
                       })
   ```

   通过调用 compose() 方法来将发送事件同生命周期绑定，这样我们就可以愉快的使用 RxJava 了。

## 原理分析

为什么在之前的代码中加一行代码就可以了呢？我们先从添加的这行代码来看

```java
compose(this.bindToLifecycle())
```

我们知道，compose 操作是将上游的 Observable 转换成另外的一个 Observable，那么继续进到 bindToLifecycle() 方法中查看。

### RxActivity

bindToLifecycle() 和bindUntilEvent 都是是RxActivity 中的方法。

```java
public abstract class RxActivity extends Activity implements LifecycleProvider<ActivityEvent{
    // 内部存储了一个behaviorSubject
    private final BehaviorSubject<ActivityEvent> lifecycleSubject = BehaviorSubject.create();

    @Override
    @NonNull
    @CheckResult
    public final Observable<ActivityEvent> lifecycle() {
        return lifecycleSubject.hide();
    }

    @Override
    @NonNull
    @CheckResult
    public final <T> LifecycleTransformer<T> bindUntilEvent(@NonNull ActivityEvent event) {
        // 在特定的生命时取消订阅
        return RxLifecycle.bindUntilEvent(lifecycleSubject, event);
    }

    @Override
    @NonNull
    @CheckResult
    public final <T> LifecycleTransformer<T> bindToLifecycle() {
        return RxLifecycleAndroid.bindActivity(lifecycleSubject);
    }

    @Override
    @CallSuper
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // 在Activity 的每个生命周期中发射事件
        lifecycleSubject.onNext(ActivityEvent.CREATE);
    }

    @Override
    @CallSuper
    protected void onStart() {
        super.onStart();
        lifecycleSubject.onNext(ActivityEvent.START);
    }

    @Override
    @CallSuper
    protected void onResume() {
        super.onResume();
        lifecycleSubject.onNext(ActivityEvent.RESUME);
    }

    @Override
    @CallSuper
    protected void onPause() {
        lifecycleSubject.onNext(ActivityEvent.PAUSE);
        super.onPause();
    }

    @Override
    @CallSuper
    protected void onStop() {
        lifecycleSubject.onNext(ActivityEvent.STOP);
        super.onStop();
    }

    @Override
    @CallSuper
    protected void onDestroy() {
        lifecycleSubject.onNext(ActivityEvent.DESTROY);
        super.onDestroy();
    }
}
```

可以看到，在 RxLifecycle 中存储了一个 BehaviorSubject  对象，它其实是一个 Observable，并且在 Activity 生命周期的每一个回调方法都发射对应的生命周期状态。

### bindUntilEvent( )

这个方法进一步会走到这里：

```java
 public static <T, R> LifecycleTransformer<T> bindUntilEvent(@Nonnull final Observable<R> lifecycle,
                                                                @Nonnull final R event) {
        checkNotNull(lifecycle, "lifecycle == null");
        checkNotNull(event, "event == null");
        return bind(takeUntilEvent(lifecycle, event));
    }

 private static <R> Observable<R> takeUntilEvent(final Observable<R> lifecycle, final R event) {
        return lifecycle.filter(new Predicate<R>() {
            @Override
            public boolean test(R lifecycleEvent) throws Exception {
                // 返回特定生命周期的 Observable
                return lifecycleEvent.equals(event);
            }
        });
    }
```

上面的代码比较简单，通过 filter 操作分离出指定生命周期的Observable，接下来将这个 Observable 返回，最终返回了一个 LifecycleTransformer，是个什么东西呢？

```java
public final class LifecycleTransformer<T> implements ObservableTransformer<T, T>,
                                                      FlowableTransformer<T, T>,
                                                      SingleTransformer<T, T>,
                                                      MaybeTransformer<T, T>,
                                                      CompletableTransformer{
     // 存储了Observable
    final Observable<?> observable;

    LifecycleTransformer(Observable<?> observable) {
        checkNotNull(observable, "observable == null");
        this.observable = observable;
    }

    @Override
    public ObservableSource<T> apply(Observable<T> upstream) {
        // 核心方法，当接收到这个Observable时停止事件传递
        return upstream.takeUntil(observable);
    }
        // 省略          
```

这个 LifecycleTransformer 实际上就是上面 compose() 的参数，将不同类型的 Observable（如Observable、Flowable）进行转换。

这个时候其实我们已经知道 bindUntilEvent() 的原理了，在 Activity 的每生命周期回调方法都会发送事件，过滤出事先指定状态的 Observable，然后调用 调用 takeUntil 操作符终止整个事件，即实现了在合适的时机进行 unsubcribe 的目的。那没有明确指定生命周期的时候又是怎么操作的呢？

### bindActivity

我们继续跟着代码走

```java
public static <T> LifecycleTransformer<T> bindActivity(@NonNull final Observable<ActivityEvent> lifecycle) {
        // 继续调用bind()
        return bind(lifecycle, ACTIVITY_LIFECYCLE);
}
public static <T, R> LifecycleTransformer<T> bind(@Nonnull Observable<R> lifecycle,
                                                      @Nonnull final Function<R, R> correspondingEvents) {
        checkNotNull(lifecycle, "lifecycle == null");
        checkNotNull(correspondingEvents, "correspondingEvents == null");
       // 继续调用bind()
        return bind(takeUntilCorrespondingEvent(lifecycle.share(), correspondingEvents));
    }

    private static <R> Observable<Boolean> takeUntilCorrespondingEvent(final Observable<R> lifecycle,
                                                                       final Function<R, R> correspondingEvents) {
        return Observable.combineLatest(
            lifecycle.take(1).map(correspondingEvents),
            lifecycle.skip(1),
            new BiFunction<R, R, Boolean>() {
                @Override
                public Boolean apply(R bindUntilEvent, R lifecycleEvent) throws Exception {
                    return lifecycleEvent.equals(bindUntilEvent);
                }
            })
            .onErrorReturn(Functions.RESUME_FUNCTION)
            .filter(Functions.SHOULD_COMPLETE);
    }
  // 最终返回 LifecycleTransformer
  public static <T, R> LifecycleTransformer<T> bind(@Nonnull final Observable<R> lifecycle) {
        return new LifecycleTransformer<>(lifecycle);
    }
 // Figures out which corresponding next lifecycle event in which to unsubscribe, for Activities
    private static final Function<ActivityEvent, ActivityEvent> ACTIVITY_LIFECYCLE =
        new Function<ActivityEvent, ActivityEvent>() {
            @Override
            public ActivityEvent apply(ActivityEvent lastEvent) throws Exception {
                // 将事件进行转换
                switch (lastEvent) {
                    case CREATE:
                        return ActivityEvent.DESTROY;
                    case START:
                        return ActivityEvent.STOP;
                    case RESUME:
                        return ActivityEvent.PAUSE;
                    case PAUSE:
                        return ActivityEvent.STOP;
                    case STOP:
                        return ActivityEvent.DESTROY;
                    case DESTROY:
                        throw new OutsideLifecycleException("Cannot bind to Activity lifecycle when outside of it.");
                    default:
                        throw new UnsupportedOperationException("Binding to " + lastEvent + " not yet implemented");
                }
            }
        };
}
```

我们一步一步的来看，在第一个 bind( ) 中传入了一个 ACTIVITY_LIFECYCLE，这是一个事件转换的 Function，后面还会用到。

接下来核心的就是 takeUntilCorrespondingEvent( ) 这个方法了，最外面是是 combineLatest 操作符，将两个 Observable 合并成一个 Observable，第一个参数 **lifecycle.take(1).map(correspondingEvents)** 即是取事件流中的第一个事件进行 map 操作，调用了上面的 ACTIVITY_LIFECYCLE 这个 Function，那么经过操作后返回的就是 ActivityEvent.DESTROY 了。

第二参数 **lifecycle.skip(1)** 即是跳过第一个事件，那么就剩下了除去 ActivityEvent.CREATE 的其他5个事件，在 combine 的时候判断当事件相等的时候返回 true，相当于判断 ActivityEvent.DESTROY 和 ActivityEvent.START、ActivityEvent.ONRESUME、ActivityEvent.PAUSE、ActivityEvent.STOP 以及 ActivityEvent.DESTROY 是否相等，结果当时是返回 false，false，false，false，true，也就意味着将在 ONDESTROY 的时候进行上述的 takeUntil 操作。

## 总结

至此，RxLifecycle 的基本原理已经被我们摸清了，其实原理并不复杂，核心是将上游的 Observable 通过compose 操作进行转换，在特定的时候进行 unsubscribe 操作（基于 takeUntil ）。而我们继承 RxActivity/RxFragment 的目的就是为了进行生命周期的判断，内部存储一个 BehaviorSubject，在 Activity 的每个生命周期发射事件，经过一系列巧妙的操作符操作最终转化为布尔类型的状态事件，虽然会带来一定程度上代码侵入性，但内部的设计思想仍然也许多值得我们学习借鉴的地方。









