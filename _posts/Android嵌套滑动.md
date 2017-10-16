Android嵌套滑动

我们知道，在Android 中触摸事件的传递机制是自顶向下，自外而内的，一旦确定了消费事件的View，那么随后事件都会传递到该View。基于这种机制，可以实现绝大部分的交互效果，但是如果想要子View 通知父View 处理事件却无法办到。这是就要使用到NestedScrolling(嵌套滑动)机制。

## 概述

NestedScrolling 机制能够让父View 和子View 在滚动时进行配合，常见于下拉刷新，收起／展开标题栏等。

要实现嵌套滑动，父View 需要实现NestedScrollingParent 接口，子View 需要实现NestedScrollingChild 接口。其中，child 是事件的发起者，Parent 只是接受回调并作出响应。

## NestedScrolling 事件传递

在NestedScrolling 机制中，NestedScrolling 机制使用dx，dy表示，分别表示子View Touch 事件处理方法中判定的x 和y 方向上的偏移量。其中传递过程为：

1. 由子View 产生NestedScrolling 事件；
2. 发送给父View 进行处理，父View 处理之后，返回消费的偏移量；
3. 子View根据父View 消费的偏移量计算NestedScrolling事件剩余偏移量；
4. 根据剩余偏移量判断是否能处理滚动事件；如果能处理滑动事件，则将自身情况通知父View；
5. 事件传递完成。

## 方法调用流程

