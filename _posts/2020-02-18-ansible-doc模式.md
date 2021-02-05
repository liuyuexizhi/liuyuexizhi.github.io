---
categories: [ansible]
title: ansible-doc模式
---

## 目录
+ this is a toc line
{:toc}

{% raw %}

## 主机组
### 指定用户
```bash
ansible all -m ping
ansible all -m ping -u tyler
ansible all -m ping -u tyler --sudo
ansible all -m ping -u tyler --sudo --sudo-user batman
ansible all -m ping -u tyler -b
ansible all -m ping -u tyler -b --become-user batma
```
### 指定 inventory
```bash
# 用于指定自定义hosts路径，默认/etc/ansible/hosts,也可指定逗号分隔的主机列表
ansible all -i ./hosts -m ping            
ansible all -i 172.18.1.226,172.18.1.230 -m ping

```

### hosts 文件
```
# 普通
[webservers]
mail.example.com
Foo.example.com
Bar.example.com

[dbservers]
One.example.com
Two.example.com
three.example.com
# 指定端口
badwolf.example.com:5309
# 设置主机别名为 jumper
jumper ansible_ssh_port=5555 ansible_ssh_host=192.168.1.50
# 通配符匹配
www[01:50].example.com

[databases]
db-[a:f].example.com
```

```
# 为每个主机指定连接类型和连接用户
[targets]
localhost ansible_connection=local

other1.example.com ansible_connection=ssh ansible_ssh_user=mpdehaan

other2.example.com ansible_connection=ssh ansible_ssh_user=mdehaan
```

```
# 可以为每个主机单独指定一些变量，这些变量随后可以在 playbooks 中使用
[atlanta]
host1 http_port=80 maxRequestsPerChild=808
host2 http_port=303 maxRequestsPerChild=909
[atlanta]
host1
host2
# 也可以为一个组指定变量，组内每个主机都可以使用该变量
[atlanta:vars]
ntp_server=ntp.atlanta.example.com
proxy=proxy.atlanta.example.com
[atlanta]
host1
host2
```

```
[raleigh]
host2
host3

# southeast组包含atlanta组和raleigh组
[southeast:children]
atlanta
raleigh

# 为southeast组指定变量
[southeast:vars]
some_server=foo.southeast.example.com
halon_system_timeout=30
self_destruct_countdown=60
escape_pods=2
```

#### hosts 文件支持的参数
```bash
# 指定主机别名对应的真实 IP
251 ansible_ssh_host=183.60.41.251

# 指定连接到这个主机的 ssh 端口，默认 22
ansible_ssh_port=4399

# 连接到该主机的 ssh 用户
ansible_ssh_user=tyler

# 连接到该主机的 ssh 密码（连-k 选项都省了），安全考虑还是建议使用私钥或在命令行指定-k 选项输入
ansible_ssh_pass=xxxxxx

# sudo 密码
ansible_sudo_pass=xxxxxx

# (v1.8+的新特性):sudo 命令路径
ansible_sudo_exe=/usr/bin

# 连接类型，可以是 local、ssh 或 paramiko
ansible_connection=ssh

# 私钥文件路径
ansible_ssh_private_key_file=./

# 目标系统的 shell 类型，默认为 sh
ansible_shell_type=bash

# python 解释器路径, 默认是/usr/bin/python
ansible_python_interpreter=/usr/local/python

# 这里的"*"可以是 ruby 或 perl 或其他语言的解释器
ansible_*_interpreter=/usr/local/perl

```

## 通配模式
> ansible \<pattern_goes_hear> -m <modeule_name> -a <arguments\>

+ 例子文件
```bash
]# cat /etc/ansible/hosts 
[test01]
172.18.1.226

[test02]
172.18.1.227


]#
```

+ 所有主机
```bash
]# ansible all -m ping --one-line
172.18.1.226 | SUCCESS => {"changed": false,"ping": "pong"}
172.18.1.227 | SUCCESS => {"changed": false,"ping": "pong"}
]#
```

+ 直接指定主机组
```bash
]# ansible test01 -m ping --one-line
172.18.1.226 | SUCCESS => {"changed": false,"ping": "pong"}
]# ansible test02 -m ping --one-line
172.18.1.227 | SUCCESS => {"changed": false,"ping": "pong"}
]#
```

+ 匹配
```bash
]# ansible 172.18.1.* -m ping --one-line
172.18.1.226 | SUCCESS => {"changed": false,"ping": "pong"}
172.18.1.227 | SUCCESS => {"changed": false,"ping": "pong"}
]#
```

+ `:` 号表示并，均执行
```bash
]# ansible test01:test02 -m ping --one-line
172.18.1.226 | SUCCESS => {"changed": false,"ping": "pong"}
172.18.1.227 | SUCCESS => {"changed": false,"ping": "pong"}

]#
```

+ `!` 号 非模式匹配
```bash
]# ansible test03:\!test02 -m ping --one-line
172.18.1.226 | SUCCESS => {"changed": false,"ping": "pong"}
]#
```

+ `&` 号 交集匹配
```bash
]# ansible test03:\&test02 -m ping --one-line
172.18.1.227 | SUCCESS => {"changed": false,"ping": "pong"}
]#
```

+ 取组内特定编号主机，从0开始
```
]# ansible test03[0] -m ping --one-line
172.18.1.226 | SUCCESS => {"changed": false,"ping": "pong"}
]# ansible test03[0:1] -m ping --one-line
172.18.1.226 | SUCCESS => {"changed": false,"ping": "pong"}
172.18.1.227 | SUCCESS => {"changed": false,"ping": "pong"}
]#
```

+ `~`开头，表示正则匹配
```bash
]# ansible ~.* -m ping --one-line
172.18.1.226 | SUCCESS => {"changed": false,"ping": "pong"}
172.18.1.227 | SUCCESS => {"changed": false,"ping": "pong"}
]#
```

## ansible 模块

### copy
```bash
ansible test03 -m copy -a "src=/etc/hosts dest=~/hosts.tmp mode=600"
```

### file
```bash
# 改权限
ansible test02 -m file -a "dest=~/hosts.tmp mode=600 owner=tyler group=tyler"

# 创建目录 相当于 mkdir -p
ansible test02 -m file -a "dest=~/ansible/test/temp mode=755 owner=tyler group=tyler state=directory"

# 删除文件或目录
ansible test02 -m file -a "dest=~/ansible state=absent"
```

### apt && yum
```bash
# 确保 acme 包已经安装，但不更新
ansible webservers -m yum -a "name=acme state=present"

# 确保安装包到一个特定的版本
ansible webservers -m yum -a "name=acme-1.5 state=present"

# 确保一个软件包是最新版本
ansible webservers -m yum -a "name=acme state=latest"

# 确保一个软件包没有被安装
ansible webservers -m yum -a "name=acme state=absent"

```

### script
```bash
# 远程执行本地脚本
ansible webservers -m script -a "/home/test.sh 12 34"
```

### stat
```bash
# 获取远程文件的状态信息
ansible webservers -m stat -a "path=/etc/syctl.conf"
```

### get_url
```bash
# 远程下载指定 url 到本地
ansible webservers -m get_url -a "url=http://www.baidu.com dest=/tmp/index.html mode=0440 force=yes"
```

### cron
```bash
# 远程主机的 crontab 配置
ansible webservers -m cron -a "name='check dirs' hour='5,2' job='ls -alh > /dev/null'"

效果：
* 5,2 * * * ls -alh > /dev/null
```

### mount
```bash
# 远程主机分区挂载
ansible webservers -m mount -a "name=/mnt/data src=/dev/sd0 fstype=ext4 opts=ro state=present"
```

### service
```bash
# 远程主机系统服务管理
ansible webservers -m service -a "name=nginx state=stoped"
ansible webservers -m service -a "name=nginx state=restarted"
ansible webservers -m service -a "name=nginx state=reloaded"
```

### user
```bash
# 远程主机用户管理
ansible webservers -m user -a "name=wang comment='user wang'"
ansible webservers -m user -a "name=wang state=absent remove=yes"
```






{% endraw %}
