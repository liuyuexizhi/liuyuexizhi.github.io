## 介绍

> k8s [官方支持](https://jimmysong.io/kubernetes-handbook/develop/client-go-sample.html) 维护 python java go 语言的客户端 api 调用
>
> 以 [python](https://github.com/kubernetes-client/python) 为例，操作 k8s 中的资源，需要小心区分 api 版本
>
> 创建资源可以使用 yaml 或 内置方法两种方式 


## 加载配置

```python
from kubernetes import client, config

config.load_kube_config(config_file='kube_config_cluster.yml')
```


## 创建 Job

两种方式：
+ 通过封装方法创建（灵活）
+ 通过yaml文件创建（简单）


### 1. 通过封装方法创建

```python
def create_job_object():
    # Configureate Pod template container
    container = client.V1Container(
        name="busybox-job-uid002",
        image="busybox:latest",
        command=["/bin/sh", "-c", "sleep 300s"])
    # Create and configurate a spec section
    template = client.V1PodTemplateSpec(
        metadata=client.V1ObjectMeta(labels={"app": "usybox", "used": "false"}),
        spec=client.V1PodSpec(restart_policy="Never", containers=[container]))
    # Create the specification of deployment
    spec = client.V1JobSpec(
        template=template,
        backoff_limit=4,
        parallelism=1,
        completions=1)
    # Instantiate the job object
    job = client.V1Job(
        api_version="batch/v1",
        kind="Job",
        metadata=client.V1ObjectMeta(name="usybox-job-uid002"),
        spec=spec)

    return job


def create_job(api_instance, job_obj):
    api_response = api_instance.create_namespaced_job(
        body=job_obj,
        namespace="practice")
    print("Job created. status='%s'" % str(api_response.status))


def main():
    # 创建对应的apiserver版本对象
    batch_v1 = client.BatchV1Api()
    # 创建job实例（相当于写yaml文件）
    job_obj = create_job_object()
    # 开始创建
    create_job(batch_v1, job_obj)
```

### 2. 通过yaml文件创建

**准备写好的yaml文件**

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: busybox-job-uid002
spec:
  parallelism: 1
  completions: 1
  template:
    metadata:
      labels:
        used: "false"
    spec:
      containers:
        - name: busybox-uid001
          image: busybox:latest
          command: ["/bin/sh","-c","sleep 300s"]
      restartPolicy: Never
```

**调用api创建**

```python
def create_job(api_instance, yaml_path):
    with open(yaml_path) as yaml_body:
        job_obj = yaml.safe_load(yaml_body)
        api_response = api_instance.create_namespaced_job(
            body=job_obj,
            namespace="practice")
        print("Job created. status='%s'" % str(api_response.status))


def main():
    # 创建对应的apiserver版本对象
    batch_v1 = client.BatchV1Api()
    # 开始创建
    create_job(batch_v1, yaml_path)
```


### 查询 pod

**查询指定命名空间下所有pod**

```python
# pod api 版本为 v1
v1 = client.CoreV1Api()
ret = v1.list_namespaced_pod('practice')
# ret.items 有很多信息可以查询
for i in ret.items:
    print("{}\t{}\t{}".format(i.status.pod_ip, i.metadata.namespace, i.metadata.name))
```

**查询指定命名空间下过滤标签的pod**

```python
v1 = client.CoreV1Api()
ret = v1.list_namespaced_pod(namespace='practice', label_selector="used=false")
```

### 更新 Pod

> 需求：更新 label "used=true"

```python
v1 = client.CoreV1Api()
    body = {
        "metadata": {
            "labels": {
                "used": "true",
                "test": "test"
            }
        }
    }

    v1.patch_namespaced_pod(
        name='busybox-job-uid002-5hh5v',
        namespace='practice',
        body=body
    )
```

### 删除 Job

```python
def delete_job(api_instance):
    api_response = api_instance.delete_namespaced_job(
        name="busybox-job-uid002",
        namespace="practice",
        body=client.V1DeleteOptions(
            propagation_policy='Foreground',
            grace_period_seconds=5))
    print("Job deleted. status='%s'" % str(api_response.status))
```