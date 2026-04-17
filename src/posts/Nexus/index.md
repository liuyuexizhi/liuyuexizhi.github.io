---
title: Nexus
date: 2024-07-27T14:09:43+08:00
lastmod: 2026-04-16T16:14:35+08:00
---

# docker 安装

> install\_nexus

```bash
docker run -d \
    -p 8081:8081 \
    -v /data/nexus3:/nexus-data \
    --name nexus3 \
    sonatype/nexus3:3.87.1-alpine

cat /data/nexus3/admin.password
```

nginx 代理配置

```bash
server {
    listen 80;
    
    #填写绑定证书的域名
    server_name nexus.inner-cicvd.com;
    
    #强制将http的URL重写成https
    #rewrite ^(.*) https://$server_name$1 permanent; 
    location / {
        #proxy_redirect off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://10.200.1.114:8081;
    }
}
```

‍

# 升级迁移数据库

升级到 3.70.4 版本，nexus 老版本默认数据库 OrientDB 不再支持，需要迁移到 H2 数据库

使用工具：https://help.sonatype.com/en/orientdb-downloads.html

```bash
# 目前版本为：3.52.0
docker run -itd -p 8081:8081 -v /data/nexus3:/nexus-data --restart=always --name nexus3 sonatype/nexus3:3.52.0

# 登录 web 页面上的：系统设置 - task - 创建备份任务（搜关键字：backup）- 手动 - 单次运行

# 备份路径设置为：/nexus-data/backup/

# 拷贝 nexus-db-migrator-3.70.4-02.jar 到 /nexus-data/backup/

# 停止并删除
docker stop nexus3
docker rm nexus3

# 运行指定版本
docker run -it --rm -p 8081:8081 -v /data/nexus3:/nexus-data --restart=always --name nexus3 sonatype/nexus3:3.70.4 bash
cd /nexus-data/backup/
java -Xmx4G -Xms4G -XX:+UseG1GC -XX:MaxDirectMemorySize=2867M -jar nexus-db-migrator-3.70.4-02.jar--migration_type=h2

# 执行完后会生成 nexus.mv.db，拷贝到 db 文件夹
cp nexus.mv.db ../db/

# 设置配置文件
cd ../etc/
vim nexus.properties
nexus.datastore.enabled=true

# 启动新版本 3.70.4 之后的版本均可
docker run -itd -p 8081:8081 -v /data/nexus3:/nexus-data --restart=always --name nexus3 sonatype/nexus3:3.87.1-alpine
```

‍

# 配置yum代理仓库

选择 yum（proxy）,创建以下几个仓库：

```bash
centos7-centosplus    https://vault.centos.org/7.9.2009/centosplus/
centos7-epel          https://archives.fedoraproject.org/pub/archive/epel/7/
centos7-extras        https://vault.centos.org/7.9.2009/extras/
centos7-os            https://vault.centos.org/7.9.2009/os/
centos7-updates       https://vault.centos.org/7.9.2009/updates/

# 以上 vault.centos.org archives.fedoraproject.org vault.centos.org 三个域名分别点一次 View certificate => 添加证书信任
# 不点应该也可以
```

在 centos7 机器上清除原有 repo 文件，添加自定义文件，如 cicvd.repo

```bash
[base]
name=CentOS-$releasever - Base
baseurl=http://nexus.inner-cicvd.com/repository/centos7-os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-$releasever - Updates
baseurl=http://nexus.inner-cicvd.com/repository/centos7-updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-$releasever - Extras
baseurl=http://nexus.inner-cicvd.com/repository/centos7-extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[centosplus]
name=CentOS-$releasever - Plus
baseurl=http://nexus.inner-cicvd.com/repository/centos7-centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[epel]
name=EPEL 7 - Nexus Proxy
baseurl=http://nexus.inner-cicvd.com/repository/centos7-epel/$basearch/ 
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 
```

执行

```bash
yum clean all
yum makecache
```

‍

# 参考文档

[help.sonatype.com](assets/https://help.sonatype.com/repomanager3)

[github.com](assets/https://github.com/sonatype/docker-nexus3)

‍
