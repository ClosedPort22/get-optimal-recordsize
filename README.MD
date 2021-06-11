# get-optimal-recordsize
给定`zpool`的参数和文件列表，找出空间利用率最高的`recordsize`大小。
适用于优化归档数据（不会再更改的数据）或类似文件（会更改，但增减的文件类型、大小比较可控，比如平均5-10MiB大小的JPEG文件）的空间利用率。可用`于mirror`、`stripe`和`raidz`的单`vdev` `zpool`，下文的`vdev`和`zpool`基本可以互换。目前尚不清楚是否适用于多`vdev`的`zpool`。（todo：做测试）
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