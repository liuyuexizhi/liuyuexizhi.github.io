---
categories: 
title: k8s-source-code-learning-plan-bean-bag-generation-z1yvn67
---

## 目录
+ this is a toc line
{:toc}

{% raw %}

---  
title: K8s 源码学习计划（豆包生成）  
date: '2025-09-24 14:35:05'  
permalink: /post/k8s-source-code-learning-plan-bean-bag-generation-z1yvn67.html  
layout: post  
published: true  
---  
  
  
  
## 一、前置知识准备阶段（3-4 周）  
  
### 核心目标  
  
掌握阅读 K8s 源码的基础工具与理论，避免因基础缺失导致源码理解断层。  
  
### 学习内容  
  
1. **Go 语言进阶（1.5-2 周）**  
  
- 重点攻克 K8s 高频使用特性：goroutine 并发模型（channel、sync 包）、接口（interface）与多态、反射（reflect）、结构体标签（struct tag）、Go 模块（mod）管理  
- 实战练习：编写简单 HTTP 服务（模拟 K8s 组件间通信）、实现基于 channel 的任务调度（对标 K8s 控制器并发逻辑）  
- 工具掌握：GoLand 调试（断点、变量监控）、pprof 性能分析（后续源码性能优化会用到）  
  
2. **K8s 基础与架构（1 周）**  
  
- 核心资源理解：Pod（生命周期、容器共享资源）、Service（服务发现逻辑）、Deployment（控制器扩缩容原理）  
- 架构拆解：控制平面（apiserver/controller-manager/scheduler）与节点组件（kubelet/kube-proxy）的交互流程（如 Pod 创建的 “apiserver→scheduler→kubelet” 链路）  
- 实战：用 Kind/Minikube 搭建单节点集群，通过kubectl describe跟踪 Pod 创建过程，记录各组件日志输出  
  
3. **容器运行时基础（0.5-1 周）**  
  
- 核心：Containerd 架构（runtime v2、CRI 接口）、OCI 规范（config.json、runtime-spec）  
- 实战：用ctr命令手动创建容器（从拉取镜像到启动 / 删除），对比docker run的底层差异；查看 Containerd 与 Kubelet 的通信日志（journalctl -u containerd）  
  
## 二、K8s 源码环境搭建与整体结构认知（2 周）  
  
### 核心目标  
  
能编译源码、调试单组件，理解源码目录逻辑与核心依赖。  
  
### 学习内容  
  
1. **源码环境搭建（3-4 天）**  
  
- 源码获取：Fork Kubernetes 仓库（[https://github.com/kubernetes/kubernetes](https://github.com/kubernetes/kubernetes)），切换到稳定版本（如 v1.28.x，避免最新版 bug）  
- 编译配置：  
- 安装依赖（apt install gcc make git，Go 1.20+）  
- 执行make all编译核心组件（apiserver、kubelet 等），验证编译产物（\_output/local/bin/linux/amd64/下）  
- 调试配置：用 GoLand 打开源码，设置GOFLAGS\=-mod\=vendor（使用官方依赖），配置 apiserver 调试参数（指定 etcd 地址、证书路径）  
- 简化调试：使用make hack/[local-up-cluster.sh](http://local-up-cluster.sh)启动本地集群，快速验证源码修改效果  
  
2. **源码目录结构解析（3-4 天）**  
  
|目录|核心作用|重点关注模块（容器开发方向）|  
| ----------| -------------------------------------| ----------------------------------------------------------------|  
|cmd/|各组件入口（apiserver、kubelet 等）|cmd/kubelet/（容器生命周期管理）|  
|pkg/|核心业务逻辑|pkg/kubelet/（kubelet 核心）、pkg/apis/（API 定义）|  
|staging/|待毕业的核心模块（独立仓库前）|staging/src/k8s.io/cri-api/（CRI 接口）|  
|vendor/|第三方依赖（锁定版本）|vendor/github.com/containerd/containerd/（与 Containerd 交互）|  
|hack/|编译、测试脚本|hack/local-up-cluster.sh（本地集群脚本）|  
  
3. **核心依赖与接口认知（3-4 天）**  
  
- 关键依赖：etcd-client（数据存储）、client-go（K8s API 客户端）、cri-api（容器运行时接口）  
- 核心接口：  
- CRI 接口（staging/src/[k8s.io/cri-api/pkg/apis/runtime/v1/](http://k8s.io/cri-api/pkg/apis/runtime/v1/)）：RuntimeService（容器 / 沙箱管理）、ImageService（镜像管理）  
- kubelet 与 CRI 的交互逻辑：pkg/kubelet/cri/下的remote\_runtime.go（远程调用 Containerd 的 CRI 实现）  
  
## 三、核心模块源码深入学习（8-10 周）  
  
### 核心目标  
  
聚焦容器开发相关模块（kubelet、CRI、容器生命周期），理解 “K8s 如何管控容器” 的底层逻辑。  
  
### 阶段 1：kubelet 核心逻辑（3-4 周）  
  
#### 1. kubelet 启动流程（1 周）  
  
- 跟踪入口：cmd/kubelet/kubelet.go的main()→Run()→StartKubelet()  
- 关键步骤：  
- 配置加载（从 apiserver 或本地文件获取 Pod 配置）：pkg/kubelet/config/config.go  
- CRI 客户端初始化：pkg/kubelet/cri/remote/remote\_runtime.go的NewRemoteRuntimeService()（连接 Containerd 的 CRI 服务端）  
- 核心组件启动：Pod 管理器（PodManager）、状态管理器（StatusManager）、容器运行时管理器（RuntimeManager）  
  
#### 2. Pod 生命周期管理（2-3 周）  
  
- 核心链路：“Pod 配置接收→容器创建→启动→健康检查→销毁”  
  
1. ​**Pod 配置接收**：pkg/kubelet/config/podconfig.go的PodConfig监听 apiserver 的 Pod 变更（watch 机制）  
2. ​**容器创建前置处理**​：pkg/kubelet/kuberuntime/kuberuntime\_manager.go的CreatePodSandbox()（创建 Pod 沙箱，对应 Containerd 的 namespace）  
3. ​**镜像拉取**​：pkg/kubelet/kuberuntime/kuberuntime\_image.go的PullImage()（调用 CRI 的PullImage接口，Containerd 拉取镜像到本地）  
4. ​**容器启动**​：pkg/kubelet/kuberuntime/kuberuntime\_container.go的StartContainer()（构建 OCI 配置，调用 CRI 的CreateContainer+StartContainer）  
5. ​**健康检查**：pkg/kubelet/prober/prober.go的prober（liveness/readiness 探针，通过 exec/http/tcp 检查容器状态）  
6. ​**容器销毁**​：pkg/kubelet/kuberuntime/kuberuntime\_container.go的KillContainer()（调用 CRI 的StopContainer+RemoveContainer）  
  
- 实战：修改PullImage()逻辑，添加自定义镜像拉取日志；调试StartContainer()，跟踪 OCI 配置如何传递给 Containerd  
  
### 阶段 2：CRI 接口与容器运行时交互（2-3 周）  
  
#### 1. CRI 接口定义与实现（1 周）  
  
- 接口规范：staging/src/[k8s.io/cri-api/pkg/apis/runtime/v1/runtime.proto](http://k8s.io/cri-api/pkg/apis/runtime/v1/runtime.proto)（gRPC 协议，定义容器 / 沙箱 / 镜像的核心操作）  
- K8s 侧 CRI 客户端：pkg/kubelet/cri/remote/（封装 gRPC 调用，与 Containerd 的 CRI 服务端通信）  
- Containerd 侧 CRI 实现：containerd/cri/（Containerd 的 CRI 插件，实现RuntimeService和ImageService接口）  
  
#### 2. 容器运行时交互细节（1-2 周）  
  
- 关键交互：  
- 沙箱创建：kubelet→CRI（CreatePodSandbox）→Containerd（创建 sandbox 容器，基于 pause 镜像）  
- 容器网络配置：CRI 调用 CNI 插件（如 Calico），为 Pod 配置网络（pkg/kubelet/dockershim/network/cni/cni.go）  
- 容器日志收集：pkg/kubelet/logs/logs.go（kubelet 通过 CRI 获取容器日志，提供kubectl logs能力）  
- 实战：编写简单 CRI 模拟服务（实现ListContainers接口），让 kubelet 连接该服务，验证接口通信逻辑  
  
### 阶段 3：控制器模式与 Deployment（2-3 周）  
  
#### 1. 控制器核心原理（1 周）  
  
- 控制器模式：“监听（Watch）→比较（Compare）→调谐（Reconcile）” 循环  
- 核心框架：pkg/controller/的Controller接口（Run()启动监听，worker()处理事件）  
- client-go 依赖：vendor/[k8s.io/client-go/tools/cache](http://k8s.io/client-go/tools/cache)（Informer 机制，本地缓存 apiserver 数据，减少请求压力）  
  
#### 2. Deployment 控制器源码（1-2 周）  
  
- 入口：pkg/controller/deployment/deployment\_controller.go的DeploymentController  
- 核心逻辑：  
- 监听对象：Deployment、ReplicaSet、Pod 的变更事件  
- Reconcile 流程：  
  
1. 获取 Deployment 期望状态（如 replicas: 3）  
2. 对比当前状态（实际运行的 ReplicaSet/Pod 数量）  
3. 调谐操作（如创建 / 删除 ReplicaSet、扩缩容 Pod）  
  
- 容器开发关联：理解 Deployment 如何通过控制器间接管控 Pod（容器）的创建与扩缩容，为后续自定义控制器开发打基础  
- 实战：修改 Deployment 控制器的扩缩容逻辑（如添加自定义扩缩容阈值），编译后替换集群中的controller-manager，验证效果  
  
## 四、实践与扩展阶段（4-6 周）  
  
### 核心目标  
  
通过实战将源码知识转化为容器开发能力，拓展技术边界。  
  
### 学习内容  
  
1. **自定义 CRD 与控制器开发（2 周）**  
  
- 需求：开发 “自定义容器部署资源（MyDeployment）”，支持 “容器启动前执行自定义脚本” 的特性  
- 步骤：  
  
1. 定义 CRD（CustomResourceDefinition）：指定 MyDeployment 的 API 结构（如spec.script字段存储启动脚本）  
2. 生成 client-go 代码：用code-generator生成 MyDeployment 的客户端（方便控制器操作 CRD）  
3. 开发控制器：基于pkg/controller/框架，实现 Reconcile 逻辑（监听 MyDeployment，创建 Pod 时注入spec.script的执行步骤）  
4. 部署验证：将 CRD 和控制器部署到集群，创建 MyDeployment 实例，验证脚本是否执行  
5. **容器运行时插件开发（1-2 周）**  
  
- 需求：为 Containerd 开发简单的 “容器启动钩子插件”（在容器启动后发送通知到指定接口）  
- 步骤：  
  
1. 了解 Containerd 插件机制（containerd/plugin）：定义插件类型（如TaskMonitor）  
2. 实现插件逻辑：监听 Containerd 的TaskStart事件，触发 HTTP 通知  
3. 集成测试：将插件编译到 Containerd，启动容器后验证通知是否触发  
4. **K8s 问题排查与源码调试（1 周）**  
  
- 场景 1：Pod 启动卡在 “ContainerCreating”→ 调试 kubelet 的CreatePodSandbox()逻辑，查看 CRI 调用日志（--v\=5开启详细日志）  
- 场景 2：容器健康检查失败→ 跟踪pkg/kubelet/prober/的探针执行逻辑，验证 exec 命令是否正确传递  
- 工具：kubectl debug（调试运行中 Pod）、dlv（远程调试 kubelet 组件）  
  
## 五、学习资源推荐  
  
1. **官方文档**  
  
- K8s 源码贡献指南：[https://github.com/kubernetes/kubernetes/blob/master/CONTRIBUTING.md](https://github.com/kubernetes/kubernetes/blob/master/CONTRIBUTING.md)  
- CRI 规范：[https://github.com/kubernetes/cri-api/blob/master/pkg/apis/runtime/v1/runtime.proto](https://github.com/kubernetes/cri-api/blob/master/pkg/apis/runtime/v1/runtime.proto)  
  
2. **书籍**  
  
- 《Kubernetes 源码剖析》（深入讲解核心模块逻辑）  
- 《Go 语言实战》（巩固 Go 进阶特性）  
  
3. **视频与课程**  
  
- 极客时间《深入剖析 Kubernetes》（从架构到源码的系统讲解）  
- KubeCon 演讲：“Deep Dive into Kubelet”（最新源码特性解读）  
  
4. **社区与工具**  
  
- Kubernetes Slack：#sig-node（kubelet 相关讨论）、#sig-contributor-experience（源码学习交流）  
- 源码阅读工具：Sourcegraph（在线浏览 K8s 源码，支持跳转）  
{% endraw %}
