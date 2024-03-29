
## CPU性能
### 平均负载
> 使用 `uptime` 和 `top` 命令查看到的平均负载
>
> 对应的三个数字依次代表着:

+ 过去 1 分钟的平均负载
+ 过去 5 分钟的平均负载
+ 过去 15 分钟的平均负载

**1. 平均负载是什么？**
> 平均负载是指单位时间内，系统处于 `可运行状态` 和 `不可中断状态` 的平均进程数，也就是 `平均活跃进程数`。

可运行状态的进程，是指正在使用 CPU 或者正在等待 CPU 的进程。ps 查看进程状态为 R 状态。

不可中断状态的进程，是指正处于内核态关键流程中的进程，并且这些流程是不可打断的。ps 查看进程状态为 D 状态。

平均负载为 2 时意味着
+ 在具有 2 个 cpu 的系统上，cpu 刚好被用完
+ 在具有 4 个 cpu 的系统上，cpu 空闲 50%
+ 在具有 1 个 cpu 的系统上，一半进程数等待

**2. 平均负载多少为合理？**
> 首先需要查询到 cpu 的个数
> 使用 `top` 命令或者查看 `/proc/cpuinfo` 文件

```shell
grep 'model name' /proc/cpuinfo | wc -l
```

`注：当平均负载比 cpu 个数大的时候，系统就已经出现过载。`

> 其次，三个数字代表着平均负载的趋势，可以从趋势的角度判断情况在稳定、变好或者变坏

**3. 平均负载为多少时，我们需要重点关注？**

推荐：`平均负载高于 cpu 数量 70% 的时候`

更为推荐的做法：将平均负载监控起来，根据更多的历史数据，判断负载趋势。比如负载陡增翻倍，但并未高于 cpu 数量的 70% 情况，也需要重点关注。  

**4. 平均负载案例分析**
> 使用工具:
> + stress：Linux系统压力测试工具
> + systat：包含常用的性能工具

> 安装以上工具：

```shell
yum install stress sysstat
```

> 使用工具命令分析
> `mpstat` 和 `pidstat` 包含在 `sysstat` 工具包里
> `mpstat`  是一个常用的多核性能分析工具
> `pidstat`  是一个常用的进程性能分析工具

```shell
# 模拟一个cpu满载
stress --cpu 1 --timeout 600
# 模拟 io 压力
stress -i 1 --timeout 600
# 模拟大量进程
stress -c 8 --timeout 600

# 分别查看性能情况
## 实时查看 uptime 变动情况
watch -d uptime
## 显示所有 CPU 的指标，并在间隔 5 秒输出一组数据
mpstat -P ALL 5 1
## 查找进程占用情况
pidstat -u 5 1
```
> 以上分析指出，平均负载高可能出现的原因：
> + **CPU 密集型进程**（单进程占用大量cpu）
> + **I/O 密集型进程**（IO占用导致的cpu压力）
> + **大量进程的场景**（多进程并发的情况）

### CPU上下文

CPU 上下文切换，是保证 Linux 系统正常工作的核心功能之一，一般情况下不需要我们特别关注。

但 **过多的上下文切换，会把 CPU 时间消耗在寄存器、内核栈以及虚拟内存等数据的保存和恢复上** ，从而缩短进程真正运行的时间，导致系统的整体性能大幅下降。


**1. 怎么查看cpu上下文切换情况？**
> 使用 `vmstat` 工具查看整体状况

```shell
$ vmstat 5 1

procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 1  0      0 3462228   4172 268348    0    0    95    24   94  203  1  1 95  2  0
```
特别关注的四行内容：
+ cs（context switch）是上下文切换的次数
+ in（interrupt）是每秒中断的次数
+ r（Running or Runnable）就绪队列长度，正在运行和等待cpu的进程数
+ b（Blocked）是处于不可中断睡眠状态的进程数

> 使用 `pidstat` 查看进程状况

```shell
# -w 选项显示上下文相关列
pidstat -w 5 1

23时07分11秒   UID       PID   cswch/s nvcswch/s  Command
23时07分16秒     0         3      0.20      0.00  ksoftirqd/0
23时07分16秒     0         9      5.80      0.00  rcu_sched
```
特别关注的两行内容：
+ cswch（voluntary context switches）表示每秒自愿上下文切换的次数
+ nvcswch（non voluntary context switches）表示每秒非自愿上下文切换的次数

两者的概念分别为：
+ **自愿上下文切换：指进程无法获取所需资源，导致的上下文切换**
+ **非自愿上下文切换：指进程由于时间片已到期等原因，被系统强制调度，进而发生的上下文切换**

举例说明：
+ 自愿上下文切换：IO、内存等系统资源不足时，就会发生自愿上下文切换
+ 非自愿上下文切换：大量进程争抢CPU时，就容易发生非自愿上下文切换

**2. cpu上下文切换案例分析**
> 使用工具
> + `sysbench` 模拟系统多线程调度切换
> + `sysstat` 包含常用性能分析工具

```shell
# 使用 sysbench 模拟多线程
sysbench  --threads=10 --max-time=300 threads run

# 使用 vmstat 查看系统总体状况
vmstat 1

# 使用 pidstat 查看进程状况
# -w 进程上下文切换状况
# -t 线程上下文切换状况
pidstat -w -u -t 1

# 查看中断信息
watch -d cat /proc/interrupts
```

### CPU使用率
 > 常用的cpu时间指标

| 名称  | 缩写 | 含义 | 备注 |
| --- | --- | --- | --- |
| user | us | 用户态的cpu时间 | 不包含nice时间 |
| nice | ni  | 低优先级用户态时间  | nice可选值-20到19，越大优先级越低 |
| system | sys | 内核态的cpu时间 | |
| idle | id | 空闲时间 | 不包含等待IO的cpu时间 |
| iowait | wa | 等待IO的cpu时间 | |
| irq | hi | 处理硬中断的cpu时间 | |
| softirq | si |处理软中断的cpu时间 | |
| steal | st | 被其他虚拟机占用的cpu时间| 当前系统运行在虚拟机中cpu |
| guest | guest | 运行虚拟机的cpu时间 | 通过虚拟化运行其他系统 |
| guest_nice | gnice | 以低优先级运行虚拟机的cpu时间 | |

> cpu使用率是指
>
> **(1) 除空闲时间（idel）外的其他时间，占用总 cpu 时间的百分比**
>
> **(2) 性能工具给出的都是间隔一段时间（比如 3 秒）的平均 cpu 使用率**

**1. 怎么查看 CPU 使用率？**
+ `top` 工具的 %CPU 列表示进程的 cpu 使用率。包括用户态和内核态的总和。
+ `pidstat` 工具详细划分了以上表格的各个数据

**2. CPU 过高怎么办？**
我们可以使用 `top` `ps` `pidstat` 很容易找出 cpu 占用高的进程。
但是要找出代码里占用 cpu 高的函数就没那么显而易见。
我们可以使用，`perf` 工具（linux性能分析工具）。

使用方法：
1. 第一种，`perf top` 类 `top` 命令，查找显示占用 cpu 最高的函数或指令
    
    + Samples 采样数，数字越大越精确。
    + event 事件类型
    + Event count 事件总数量
    + Overhead 表示改性能事件在采样数据中的比例
    + Shared 表示该函数或指令所在的动态共享对象（进程名、内核、lib名等）
    + Object 表示动态共享对象的类型。[.] 表示用户程序或者lib库，[k]代表着内核空间。
    + Symbol 表示符号名，也就是函数名。

2. 第二种，`perf record` 保存数据，`perf report` 恢复显示数据

3. `perf` 命令加上 `-g` 参数可以开启调用关系的采样


**3. CPU 使用率案例？**

+ 第一、简单的使用率高的案例
> 使用 ab 工具（HTTP服务性能测试工具）模拟nginx客户端
> 使用 top 命令查找cpu占用高的进程号
> 使用 perf top -g -p 进程号，查看进程调用关系

+ 第二、无法明显找出占用cpu的案例
> 应当考虑是短时应用导致的问题，比如：
> + 应用里调用了其他二进制程序，这些程序运行时间足够短，以至于top工具不容易发现
> + 应用本身不停地崩溃重启，而初始化过程可能占用相当多的cpu

> 解决方法：
> 先使用 `top` 命令查找可疑点，如task、进程状态等
> 使用 `pstree` 或者 `execsnoop` 命令找到可疑进程的父进程

> 备注：`ab` 工具使用

```shell
ab
    | -c 指定请求并发数
    | -t 指定请求时长（s）
    | -n 指定请求数量
```

+ 第三、大量不可中断进程和僵尸进程
> 进程状态

| 缩写 | 全称 | 解释 |
| --- | --- | --- |
| R | Running/Runnable | 就绪队列中 |
| D | Disk Sleep | 不可中断状态睡眠 |
| Z | Zombie | 僵尸进程 | 
| S | Interruptible Sleep | 可中断状态睡眠 |
| I | Idle | 空闲状态 | 
| T | Stopped/Traced | 暂停/跟踪状态 |
| X | Dead | 进程消亡 |

不可中断状态：系统为了保证进程数据与硬件状态一致性，而如果硬件迟迟没有响应，造成进程处于不可中断状态。

僵尸进程：由于一些原因，父进程未能及时回收的子进程，而造成的大量已退出的子进程占用PID。

> 一、`iowait高` 的解决思路
> 1. 使用 `dstat` 可以看出 iowait 升高时，io读写情况等
> 2. 使用 `top` 可以找出 D 状态下的进程号
> 3. 使用 `pidstat -d <pid>` 可以查出(指定或全部)进程的 io 情况
> 4. 使用 `strace -p <pid>` 可以跟踪进程系统调用
> 5. 使用 `perf top -g` 查看进程调用情况
> > 结论：
> > 可能由于 程序直接调用 sys_read 对磁盘直接 io，而没有经过系统缓存造成 iowait 升高
> > 
> 二、`僵尸进程多` 的解决思路：
> 1. 使用 `pstree` 找出僵尸进程的父进程
> 2. 查看父进程的程序代码找出其子进程的处理函数，比如 wait() 或 waitpid()
> > 结论:
> > 可能没有或者没有调用到 wait() 函数
>>
> 三、总结：
> 1. iowait 高不一定代表 I/O 有性能瓶颈
> 2. 碰到 iowait 升高时，需要先用 dstat、pidstat 等工具，确认是不是磁盘I/O 的问题，然后再找是哪些进程导致了 I/O。
> 3. 等待 I/O 的进程一般是不可中断状态，查找 D 状态的进程多为可疑进程


### 软中断
**1. 概念**
> 中断：
> 1. 中断其实是一种异步的事件处理机制，可以提高系统的并发处理能力
> 2. 为了减少对正常进程运行调度的影响，中断处理程序就需要尽可能快地运行

> Linux 将中断处理过程分成了两个阶段，也就是上半部和下半部:
> 1. 为了解决中断处理程序执行过长和中断丢失的问题
> 2. **上半部用来快速处理中断**（硬中断，快速执行）
> 3. **下半部用来延迟处理上半部未完成的工作，通常以内核线程的方式运行**（软中断，延迟执行）

> 软中断包括：
> 1. 硬件中断程序的下半部分
> 2. 内核的自定义事件（内核调度和RCU锁等）

> 查看软中断和内核线程：
> 1. `/proc/softirqs` 提供了软中断的运行情况
> 2. `/proc/interrupts` 提供了硬中断的运行情况
> 3. `ps aux | grep softirq` 查看内核线程

**2. 案例分析思路**
> `hping3` 模拟一个 SYN FLOOD

```shell
# hping3 构造 TCP/IP 协议数据包
# -S 表示设置 TCP 协议的 SYN
# -i u100 表示每隔 100 微秒发送一个网络帧
hping3 -S -p 80 -i u100 192.168.2.142
```
> 网络分析

| 名称 | 简称 | 含义 |
| --- | --- | --- |
| rxpck/s && txpck/s | PPS | 每秒收发网络帧数 |
| rxkB/s && txkB/s | BPS | 每秒收发网络字节数 |

```shell
# sar 查看网络收发情况
# -n DEV 表示显示网络收发的报告
sar -n DEV 1

# tcpdump 网络抓包
tcpdump -i eth0 -n tcp port 80
```

> 网络接收的软中断解决思路
> 症状：系统响应明显变慢
> 1. 通过 `top` 查找的 `si` 明显异常，`ksoftirqd` 占用 cpu 异常，判断 **系统软中断异常**
> 2. 通过 `watch -d cat /proc/softirqs` 查看软中断变化情况，定位到 NET_RX 变化最快，判断 **网络收发软中断异常**
> 3. 通过 `sar -n DEV 1` 定位到 rxpck/s 比较大，但 rxpck/s 却比较小，判断 **网络接收大量小包异常**
> 4. 通过 `tcpdump -i eth0 -n tcp port 80` 定位到异常机器ip发过来的大量 SYN 包，判断 **遭受对应ip的 SYN FLOOD攻击**
>
> 解决方法：
> 从交换机或者硬件防火墙封掉来源 IP


### CPU性能分析思路

**1. CPU的性能指标**
![da684d7fc35b3176a076d8f1a701ba31.png](en-resource://database/5265:1)

**2. 性能工具**
> 第一个维度：根据指标找工具

![fdad8e6d54885ec8123d52bed7bf7348.png](en-resource://database/5266:1)

> 第二个维度：根据工具找指标

![882573f2132945fc0e86dd853fd3fbb2.png](en-resource://database/5263:1)

**3. 工具间的关联关系**
![91334936fda06c61a21e46457d635617.png](en-resource://database/5264:1)


### CPU性能优化思路

**怎么评估性能优化的效果？**
1. 确定性能的量化指标
    > 多维度的指标上评估性能
    > 例如：
    > 1. 从应用程序的维度，使用 `吞吐量` 和 `请求延迟` 指标
    > 2. 从系统资源的维度，使用 `cpu使用率` 指标

2. 测试优化前的性能指标
3. 测试优化后的性能指标
    > 接下来的两个步骤，主要是为了对比优化前后的性能
    > 我们使用 `ab` 等工具时，
    > 1. 避免性能工具干扰应用程序的性能，性能工具要在不同机器上运行
    > 2. 避免外部环境的变化影响性能指标的评估，优化前后应用程序所处环境要一致

**多个性能问题怎么选择处理？**
1. 不是所有性能问题都值得优化
2. 找出最重要的、最大程度提升性能的问题，开始优化
    > 找出最重要的性能问题：
    > 1. 系统资源达到瓶颈，首先优化的是系统资源使用的问题
    > 2. 首先优化那些瓶颈导致的，性能指标变化幅度最大的问题

**多种优化方法怎么选择？**
1. 性能优化是有成本的
2. 权衡成本与好处，做出最适合的选择

**应用程序的性能优化**
1. 编译器优化    
    > 如：
    > gcc 提供 `-o2` 选项开启自动优化

2. 算法优化
3. 异步处理
4. 多线程代替多进程
5. 善用缓存

**系统的性能优化**
1. CPU 绑定
2. CPU 独占
3. 优先级调整
4. 为进程设置资源限制
5. NUMA 优化
6. 中断负载均衡

**避免过早优化**
1. 优化会带来复杂性的提升，降低可维护性
2. 需求你不是一成不变的


### 问题

**1. 使用 perf 工具不显示函数名**
> perf 找不到待分析进程依赖的库
> 四个解决方法：
> 1. 在容器外面构建相同路径的依赖库（不推荐）
> 2. 在容器内部运行 perf，可能容器内部没有权限执行（不推荐）
> 3. 指定符号路径为容器文件系统的路径
> ```
> # bindfs 的基本功能是实现目录绑定，需要额外安装
> $ mkdir /tmp/foo
> $ PID=$(docker inspect --format {{.State.Pid}} phpfpm)
> $ bindfs /proc/$PID/root /tmp/foo
> $ perf report --symfs /tmp/foo
> # 使用完成后不要忘记解除绑定
> $ umount /tmp/foo/
> ```
> 4. 在容器外面保存分析记录，在容器里面查看结果