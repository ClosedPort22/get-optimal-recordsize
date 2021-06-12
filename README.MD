# get-optimal-recordsize
给定`zpool`的参数和文件列表，找出空间利用率最高的`recordsize`大小。

适用于优化归档数据（不会再更改的数据）或类似文件（会更改，但增减的文件类型、大小比较可控，比如平均5-10MiB大小的JPEG文件）的空间利用率。可用于mirror、stripe和raidz的单`vdev` `zpool`，下文的`vdev`和`zpool`基本可以互换。目前尚不清楚是否适用于多`vdev`的`zpool`。（todo：做测试）

目前这种计算方法误差比较大（大概在1-3%），文件数量较多时尤为严重，但一般情况不影响得出结论。由于ZFS默认的压缩算法lz4并不会出现压缩后大小反而比压缩前还大的情况，此脚本只考虑数据未压缩的情况（metadata除外），如果开启压缩overhead不会高于未压缩时的值（理论上`recordsize`越大压缩效率越高，因为每个块都有自己的字典，但是没测试过）。
# 工作流程
## 参数
- `-RAIDZLevel` `vdev`的`raidz`等级（可选值0-3，0代表`mirror`或`stripe`）
- `-StripeWidth` `vdev`的硬盘数，只有`raidz`等级为1-3的时候才有意义

可选：
- `-Path` 指定目录，默认当前目录
- `-MaxExponent` 最大的`recordsize`，以2的n次幂表示。默认值20对应一般情况下的最大值1MiB。把这个作为参数之一是因为ZFS其实最大支持16MiB，但是需要手动设置，参见[OpenZFS官方文档](https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Workload%20Tuning.html#larger-record-sizes)
- `-ashift` `vdev`的`ashift`值
- `-AvgMetadataPerBlock` 每个块的metadata（压缩过）占用大小的平均值，这个数值背后没有任何理论支撑，纯属经验值，所以误差是难免的（主要是因为没找到这方面的documentation）。我自己测试的结果是压缩后大约97 bytes/block，虽然测未压缩的metadata更好，但是禁用metadata压缩我一直没有设置成功

## 输出
脚本会遍历所有的`recordsize`选项，然后列出对应的overhead %

例子：
```
.\get-optimal-recordsize.ps1 -RaidZLevel 2 -StripeWidth 6 -Path 'e:\test\'
Data size is 3146914761 bytes

Record Size Actual Size Overhead %
----------- ----------- ----------
       4096  6371961525 102.48%
       8192  6338262980 101.41%
      16384  3172740829 0.82%
      32768  3170848065 0.76%
      65536  3180837712 1.08%
     131072  3206688543 1.90%
     262144  3261753558 3.65%
     524288  3371697343 7.14%
    1048576  3621363266 15.08%
```

# 计算模型
这里只是接近实验值的模型，未必是实际情况。模型主要分为两部分：1. 适用于所有布局；2. 针对RAID-Z

## 适用于所有布局
1. 所有小于recordsize的文件均存储为可变大小的块，块的大小为扇区大小（ashift）的整数倍；
2. 所有大于等于recordsize的文件均存储为一个或多个大小等于recordsize的固定大小块
3. 每个块会附加固定大小的metadata
4. 大小为0的文件会直接忽略（因为它们好像直接存储在metadata中，[出处](https://github.com/openzfs/zfs/issues/8771#issuecomment-495811601)）

## 针对RAID-Z
请参见[这里](https://jro.io/nas/#overhead)

所以overhead包括：
1. 对于可变大小的块，实际存储数据和扇区末尾之间的slack space
2. 对于固定大小的块，实际存储数据和块末尾之间的slack space
3. RAID-Z可变大小的stripe所需的额外parity扇区
4. RAID-Z为了使stripe能被整除而添加的padding扇区