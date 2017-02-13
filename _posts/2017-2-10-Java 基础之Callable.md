---
​---
layout:     post
title:      "Java 基础之Callable"
date:       "2018-02-10 20:59:00"
author:     "ijays"
catalog: true
tags: [Java基础,线程]
​---
---



在开发中，我们总是要和线程打交道，而在Java中，创建线程的方法有三种，分别是继承Thread 类实现run() 方法、实现Runnable 接口重写run() 方法以及本文所记录Callable 和Future 创建线程。

## Callable 特点

Callable 接口是从Java5 之后引入的，几乎是Runnable 接口的增强版，它提供了一个call() 作为线程的执行体，并且此方法可以有返回值，可以声明抛出异常，弥补了Runnable接口的不足。

不同于Runnable 接口，Callable 对象不能直接作为Thread 的target，即无法直接启动线程。而且call() 方法还有一个返回值，这个方法并不是直接调用，它是作为线程的执行体被调用的。为了解决这个问题，Java 中提供了Future 接口来接收call() 的返回值，并且提供了FutureTask 实现类，该类同时实现了Future 和Callable 接口，因此可以作为Thread 的target，同时可以使用cancle() /get() /isDone()等方法来控制它关联的Callable事物。

## Callable 创建线程的步骤

1. 创建Callable 接口的实现类，并实现call() 方法，该call() 方法将作为线程执行体，且该call() 方法有返回值。
2. 创建Callable 实现类的实例，使用FutureTask 类来包装Callable 对象，该FutureTask 封装了该Callable 对象的call() 方法的返回值。
3. 使用FutureTask 对象作为Thread 对象的target 创建并启动线程。
4. 调用Future 对象的 get()方法来获得子线程起线程执行结束后的返回值。

说这么多，还是直接看代码吧……

```java
public class CallableThread implements Callable<Integer> {

	// 实现call(),作为线程执行体
	@Override
	public Integer call() {
		int i = 0;
		for (; i < 100; i++) {
			System.out.println(Thread.currentThread().getName() + "的循环变量i的值：" + i);
		}
		return i;
	}

	public static void main(String[] args) {
		CallableThread ct = new CallableThread();
      //使用FutureTask 来包装Callable 对象，这里的泛型即为get 返回的类型
		FutureTask<Integer> task = new FutureTask<>(ct);
		for (int i = 0; i < 100; i++) {
			System.out.println(Thread.currentThread().getName() + " 的循环变量i+的值；" + i);
			if (i == 20) {
              //启动子线程
				new Thread(task, "有返回值的线程").start();
			}
		}
		try {
			System.out.println("子线程的返回值：" + task.get());
		} catch (InterruptedException e) {
			e.printStackTrace();
		} catch (ExecutionException e) {
			e.printStackTrace();
		}
	}
}

```

从上面的代码不难看出，使用Callable 创建线程和创建Runnable 实现类并没有太大的差别，只是Callable 的call() 方法允许生命抛出异常，而且允许带返回值。需要主要的是，程序最后调用FutureTask的get() 方法来返回call()执行结束后的返回值，这个方法将导致主线程==被阻塞==，直到call() 执行结束并返回。