---
layout:     post
title:      "LeetCode刷题日志-Roman To Integer"
date:       "2018-08-02 20:00:00"
author:     "ijays"
catalog: true
tags: [LeetCode,算法]
---

昨晚刷题，随机选到了一道把罗马数字转换为整型的问题。

## 题目

在罗马数字中使用以下字符来表示特定的数字，

| Symbols | Value |
| :-----: | :---: |
|    I    |   1   |
|    V    |   5   |
|    X    |  10   |
|    L    |  50   |
|    C    |  100  |
|    D    |  500  |
|    M    | 1000  |

罗马数字一般从左到右书写，表示数值为各值相加，如VI表示5+1=6。但是如果I在V的左边表示5-1=4，同理，

- I 在 V 或者 X 左边表示为4和9
- X 在 L 或者 C 左边表示为90和100
- C在 D 或者 M 左边表示为900和1000

最后题目还有个提示，数字在1和3999之间。

## 思路

其实看到这道题的时候开始觉得很简单，用一个哈希表存储罗马字符与整数的映射，然后将传入的字符串转成单个字符读取对应的数字，再判断数字是否是需要减去前面的数字。

写了一会儿代码，前面都很顺利，直到写到如何判断前面的数字需要减去，在这里卡了一会儿。经过仔细观察数字的规律得知，想 IX 这种需要减去前面的数字的罗马数都是能被 5 **整除**的。如果我们写一个 for 循环，去读取当前字符对应的数字，并且读取**下一个**字符对应的数字，如果下一个数字能够满族被5整除的条件，那么就将当前数字置为负数，最后将所有的数字加起来得到结果。

## 我的答案

```java
class Solution {
    public int romanToInt(String s) {
        if(s == null || s.length == 0){
            return 0;
        }
        Map<String, String> map = new HashMap<>(8);
        map.put("I", "1");
        map.put("V", "5");
        map.put("X", "10");
        map.put("L", "50");
        map.put("C", "100");
        map.put("D", "500");
        map.put("M", "1000");

        char[] array = s.toCharArray();
        int count = 0;
        for (int i = 0; i < array.length; i++) {
            int value = Integer.parseInt(map.get(String.valueOf(array[i])));
            if (i + 1 < array.length) {
                //读取下一个字符对应的值
                int valueNext = Integer.parseInt(map.get(String.valueOf(array[i + 1])));
                if ((valueNext % 5 == 0 && value % 5 != 0) || ((valueNext % 500 == 0) && value % 500 != 0) || ((valueNext % 50 == 0) && value % 50 != 0)) {
                 //如果下一个数字满足条件，就将当前数值置为负数
                    value = 0 - value;
                }

            }
            count = value + count;

        }
        return count;
    }
}
```

## 反思

做完后回过头来想，这里从前往后扫，判断的是下一个值是否满足条件。其实也可以判断当前值是否比上一个值大，如IV，做法类似，但是判断逻辑中会少很多模运算，这也是网上很多人的做法。





