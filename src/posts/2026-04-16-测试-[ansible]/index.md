---
title: 2026-04-16-测试-[ansible]
date: 2026-04-16T17:16:15+08:00
lastmod: 2026-04-16T17:17:06+08:00
---

> # 一、yaml 清单
>
> ```yaml
> apiVersion: apps/v1
> kind: Deployment
> metadata:
>   labels:
>     app: yearning
>   name: yearning
>   namespace: inner-devops
> spec:
>   replicas: 1
>   selector:
>     matchLabels:
>       app: yearning
>   strategy:
>     type: Recreate
>   template:
>     metadata:
>       creationTimestamp: null
>       labels:
>         app: yearning
>       namespace: inner-devops
>     spec:
>       containers:
>         - env:
>             - name: SECRET_KEY
>               value: dbcjqheupqjasdfr
>             - name: MYSQL_ADDR
>               value: >-
>                 mysql-inner-prod-sts-master-svc.inner-base-app.svc.cluster.local:3306
>             - name: MYSQL_USER
>               value: yearning_user
>             - name: MYSQL_PASSWORD
>               value: yearning_user@2023
>             - name: MYSQL_DB
>               value: yearning
>           image: harbor.inner-cicvd.com/from-public/yeelabs/yearning:v3.1.6.3
>           imagePullPolicy: IfNotPresent
>           name: yearning
>           ports:
>             - containerPort: 8000
>               name: yearning-port
>               protocol: TCP
>           resources: {}
>           terminationMessagePath: /dev/termination-log
>           terminationMessagePolicy: File
>           volumeMounts:
>             - mountPath: /data
>               name: yearning-pvc
>             - mountPath: /etc/localtime
>               name: volume-localtime
>       dnsPolicy: ClusterFirst
>       restartPolicy: Always
>       schedulerName: default-scheduler
>       securityContext: {}
>       terminationGracePeriodSeconds: 30
>       volumes:
>         - hostPath:
>             path: /etc/localtime
>             type: ''
>           name: volume-localtime
>         - name: yearning-pvc
>           persistentVolumeClaim:
>             claimName: yearning-pvc
> ```
