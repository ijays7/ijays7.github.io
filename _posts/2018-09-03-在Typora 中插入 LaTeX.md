---
layout:     post
title:      "Typora中插入数学公式"
date:       "2018-09-03 20:00:00"
author:     "ijays"
catalog: true
tags: [LaTeX,Typora]
---

最近会有在 Typora 和 Keynote 中插入数学公式的需求，开始 Google 了好一阵，为了防止自己忘记，特此记录一下。

## 在Typora 中插入 LaTeX

LaTeX 是一种强大的排版系统，对于复杂的表格和数学公式支持相当不错，那么在 Typora 中如何插入 LaTeX 呢？

Typora 天然支持了 LaTeX 语法，可以使用 快捷键 ==command + alt + b== 和 ==$$ + enter== 键来进入 LaTeX 编辑框。

## 插入常见的数学公式

### 下标

插入下标需要使用“_”符号

### 上标

插入上标需要使用"^"符号，当上标的内容大于一个字符时，需要使用“{}”来进行包裹，如
$$
10^{-7}
$$
根据上面的内容，我们就可以写出水的电离的方程式了，其中中间的双箭头使用的是“\rightleftharpoons”。
$$
H_2O \rightleftharpoons H^++OH^-
$$

### 叉乘

如果需要使用叉来表示乘法运算符，需要使用 "\times"，eg
$$
a \times b
$$

### 点乘

如果需要使用点来表示乘法运算符，需要使用 "\cdot"，eg
$$
a \cdot b
$$

### 除以

表示除法运算符需要使用 “\div”，eg
$$
a \div b
$$
上面只写出了一些常用的简单运算符表示方法，如果需要使用更多可以[参考这篇文章](https://math.meta.stackexchange.com/questions/5020/mathjax-basic-tutorial-and-quick-reference)



