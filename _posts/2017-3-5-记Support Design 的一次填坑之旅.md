---
layout:     post
title:      "记Support Design 的一次填坑之旅"
date:       "2017-03-5 23:48:00"
author:     "ijays"
linear-gradient:    "linear-gradient(120deg,#2b488a,#ca3749)"
catalog: true
tags: [Java基础,线程]
---

# 记Support Design 的一次填坑之旅

最近因为Android Studio 升级到2.3正式版，将之前的老项目也进行了依赖更新，在这个过程中，发现了一些问题，将其记录如下。

## FloatingActionButton.Behavior View的可见性

这个标题比较抽象，其实就是当RecyclerView 上滑的时候隐藏FloatingActionButton，在下滑时将其展示出来。然而，从23.3.0版本的Support Design包到25.2.0后，发现FloatingActionButton 隐藏后无法将其设置为Visible，在onStartNestedScroll() 方法中也无法再次接收到事件序列。主要逻辑代码如下：

```java
   @Override
    public void onNestedScroll(CoordinatorLayout coordinatorLayout, FloatingActionButton child, View target, int dxConsumed, int dyConsumed, int dxUnconsumed, int dyUnconsumed) {

        if ((dyConsumed > 0 || dyUnconsumed > 0) && child.getVisibility() == View.VISIBLE && !isTakingAnimation) {
            //手指往上滑动
            AnimationUtil.scaleHide(child, mViewPropertyAnimatorListener);
            if (mOnStateChangedListener != null) {
                mOnStateChangedListener.onChanged(false);
            }
        } else if ((dyConsumed < 0 || dyUnconsumed < 0) && child.getVisibility() != View.VISIBLE) {
            //手指往下滑动
            AnimationUtil.scaleShow(child, null);
            if (mOnStateChangedListener != null) {
                mOnStateChangedListener.onChanged(true);
            }
        }
    }
//其中mViewPropertyAnimatorListener 主要代码
  @Override
  public void onAnimationEnd(View view) {
        isTakingAnimation = false;
        view.setVisibility(View.GONE);
    }
```

Google一番过后，[在Android 官方issue上找到了这个问题](https://code.google.com/p/android/issues/detail?id=230298)，找到了其中的原因：

> ```Java
> It's because this:
> if (view.getVisibility() == View.GONE) {
>     // If it's GONE, don't dispatch
>     continue;
> }
> in CoordinatorLayout.onStartNestedScroll() sources.
> Temporary solution is to add listener to FAB:
> child.hide(
>     new FloatingActionButton.OnVisibilityChangedListener() {
>         @Override
>         public void onHidden(FloatingActionButton fab) {
>              super.onHidden(fab);
>              fab.setVisibility(View.INVISIBLE);
>         }
>     }
> );
> ```

很多人跟我一样认为这是一个bug，但是Chris Banes大神表示这并不是bug，而是feature，并且将其标注为WorkAsIntended。所以这个问题暂时的解决办法就是将GONE 换成INVISIBLE。

## BottomSheetBehavior 的setState() 无效

出现问题的还有底部的View，其展现效果和上面的FloatingActionButton 一样，并且是一个联动的效果。然而，上面的问题解决之后，发现下面的View 毫无动静，一动也不动。原代码如下：

```java
mBottomSheetBehavior = BottomSheetBehavior.from(mContainer);
mBottomSheetBehavior.setState(isShow ? BottomSheetBehavior.STATE_EXPANDED : BottomSheetBehavior.STATE_COLLAPSED);
//布局文件
<LinearLayout
    android:id="@+id/container"
    android:layout_width="match_parent"
    android:layout_height="50dp"
    android:background="@color/colorPrimary"
    android:orientation="vertical"
    app:layout_behavior="@string/bottom_sheet_behavior" />
```

检查代码并没有发现什么问题，只好从BottomSheetBehavior 的源码中寻找答案。

```Java
public final void setState(final @State int state) {
    //篇幅所限，省略参数检查部分代码
    // Start the animation; wait until a pending layout if there is one.
    ViewParent parent = child.getParent();
    if (parent != null && parent.isLayoutRequested() && ViewCompat.isAttachedToWindow(child)) {
        child.post(new Runnable() {
            @Override
            public void run() {
                startSettlingAnimation(child, state);
            }
        });
    } else {
        startSettlingAnimation(child, state);
    }
}
```

setState() 方法中判断了parentView 即CoordinatorLayout是否添加到了窗口中，最终都会执行到startSettlingAnimation 方法中。

```Java
void startSettlingAnimation(View child, int state) {
    int top;
    if (state == STATE_COLLAPSED) {
        top = mMaxOffset;
    } else if (state == STATE_EXPANDED) {
        top = mMinOffset;
    } else if (mHideable && state == STATE_HIDDEN) {
        top = mParentHeight;
    } else {
        throw new IllegalArgumentException("Illegal state argument: " + state);
    }
    setStateInternal(STATE_SETTLING);
    if (mViewDragHelper.smoothSlideViewTo(child, child.getLeft(), top)) {
        ViewCompat.postOnAnimation(child, new SettleRunnable(child, state));
    }
}
```

这里根据设置的不同状态对top（即偏移量）进行了赋值，接着设置内部状态为STATE_SETTLING，同时设置了onStateChanged 的回调。我们知道BottomSheetBehavior 的动画是利用了ViewDragHelper 来实现的，因此接下就调用了ViewDragHelper的smoothSlideViewTo 方法，它的返回值决定了是否能够执行状态改变的动画。

```Java
/**
 * Settle the captured view at the given (left, top) position.
 *
 * @param finalLeft Target left position for the captured view
 * @param finalTop Target top position for the captured view
 * @param xvel Horizontal velocity
 * @param yvel Vertical velocity
 * @return true if animation should continue through {@link #continueSettling(boolean)} calls
 */
private boolean forceSettleCapturedViewAt(int finalLeft, int finalTop, int xvel, int yvel) {
  //这里的mCapturedView为child，即执行动画的View
    final int startLeft = mCapturedView.getLeft();
    final int startTop = mCapturedView.getTop();
    final int dx = finalLeft - startLeft;
    final int dy = finalTop - startTop;

    if (dx == 0 && dy == 0) {
        // Nothing to do. Send callbacks, be done.
        mScroller.abortAnimation();
        setDragState(STATE_IDLE);
        return false;
    }

    final int duration = computeSettleDuration(mCapturedView, dx, dy, xvel, yvel);
    mScroller.startScroll(startLeft, startTop, dx, dy, duration);

    setDragState(STATE_SETTLING);
    return true;
}
```

从smoothSlideViewTo 方法中最终会走到forceSettleCapturedViewAt 方法，根据传入的x 轴，y 轴起始位置计算出真正的偏移量，当x轴，y轴的偏移量均为0时则表示不移动，那么返回回去使得动画无法执行。这样看来问题就缩小到了穿入的距离参数上面。

从上面代码得知，上面的finalTop 即之前根据状态设置的top，其源头为mMaxOffset以及mMaxOffset。

```Java
// Offset the bottom sheet
mParentHeight = parent.getHeight();
int peekHeight;
if (mPeekHeightAuto) {
    if (mPeekHeightMin == 0) {
        mPeekHeightMin = parent.getResources().getDimensionPixelSize(
                R.dimen.design_bottom_sheet_peek_height_min);
    }
    peekHeight = Math.max(mPeekHeightMin, mParentHeight - parent.getWidth() * 9 / 16);
} else {
    peekHeight = mPeekHeight;
}
mMinOffset = Math.max(0, mParentHeight - child.getHeight());
mMaxOffset = Math.max(mParentHeight - peekHeight, mMinOffset);
```