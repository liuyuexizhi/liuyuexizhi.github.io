## 常用参数分类
```
# 调试类
-v, --verbose                          输出信息
-q, --disable                          在第一个参数位置设置后 .curlrc 的设置直接失效，这个参数会影响到 -K, --config -A, --user-agent -e, --referer
-K, --config FILE                      指定配置文件
-L, --location                         跟踪重定向 (H)


# CLI显示设置
-s, --silent                           Silent模式, 任务下载不输出, 任务出错不输出
-S, --show-error                       显示错误. 在选项 -s 中，当 curl 出现错误时将显示
-f, --fail                             显示连接失败时 HTTP 错误信息
-i, --include                          显示 response 的 header (H/F)
-I, --head                             仅显示响应头
-l, --list-only                        只列出FTP目录的名称 (F)
-#, --progress-bar                     以进度条显示传输进度（配合 -o 使用下载文件）


# 数据传输类
-X, --request [GET|POST|PUT|DELETE|…]  使用指定的 http method 例如 -X POST
-H, --header &lt;header&gt;            设定 request里的 header 例如 -H "Content-Type: application/json"
-e, --referer                          设定 referer (H)
-d, --data &lt;data&gt;                设定 http body 默认使用 content-type application/x-www-form-urlencoded (H)
    --data-raw &lt;data&gt;            ASCII 编码 HTTP POST 数据 (H)
    --data-binary &lt;data&gt;         binary 编码 HTTP POST 数据 (H)
    --data-urlencode &lt;data&gt;      url 编码 HTTP POST 数据 (H)
-G, --get                              使用 HTTP GET 方法发送 -d 数据 (H)
-F, --form &lt;name=string&gt;         模拟 HTTP 表单数据提交 multipart POST (H)
    --form-string &lt;name=string&gt;  模拟 HTTP 表单数据提交 (H)
-u, --user &lt;user:password&gt;       使用帐户，密码 例如 admin:password
-b, --cookie &lt;data&gt;              cookie 文件 (H)
-j, --junk-session-cookies             读取文件中但忽略会话cookie (H)
-A, --user-agent                       user-agent设置 (H)


# 传输设置
-C, --continue-at OFFSET               断点续转
-x, --proxy [PROTOCOL://]HOST[:PORT]   在指定的端口上使用代理
-U, --proxy-user USER[:PASSWORD]       代理用户名及密码


# 文件操作
-T, --upload-file &lt;file&gt;         上传文件
-a, --append                           添加要上传的文件 (F/SFTP)


# 输出设置
-o, --output &lt;file&gt;              将输出写入文件，而非 stdout
-O, --remote-name                      将输出写入远程文件
-D, --dump-header &lt;file&gt;         将头信息写入指定的文件
-c, --cookie-jar &lt;file&gt;          操作结束后，要写入 Cookies 的文件位置
```

## 常用 curl 实例

### 抓取/下载
```
# 抓取页面内容到文件中
curl -o index.html https://www.baidu.com/

# 抓取远程文件 -O(大写的) 不跟参数
curl -O https://www.test.com/test.zip

# 高级下载
## 循环下载(正则)
curl -O http://mydomain.net/~zzh/screen[1-10].JPG
curl -O http://mydomain.net/~{zzh,nick}/[001-201].JPG # >like zzh/001.JPG
curl -o #2_#1.jpg http://mydomain.net/~{zzh,nick}/[001-201].JPG # like >001_zzh.jpg

## 断点续传
curl -c -O http://mydomain.net/~zzh/screen1.JPG

## 分段下载
curl -r 0-100 -o img.part1 http://mydomian.cn/thumb/xxx.jpg
# 整合 part
cat img.part* >img.jpg
```

### 登陆
```
#  相当于设置 http 头 Authorization
curl --user user:password http://blog.mydomain.com/login.php

# 保存 cookie
curl -c ./cookie_c.txt -F log=aaaa -F pwd=****** http://blog.mydomain.com/login.php
# 使用 cookie
curl -b ./cookie_c.txt  http://blog.mydomain.com/wp-admin
```

### 传输
```
# 伪造来源地址
curl -e http://localhost http://www.sina.com.cn

# 代理
curl -x 10.10.90.83:80 -o home.html http://www.sina.com.cn

# ftp 传输
curl -O ftp://xukai:test@192.168.242.144:21/www/focus/enhouse/index.php
curl -T xukai.php ftp://xukai:test@192.168.242.144:21/www/focus/enhouse/

# post
curl -d "user=nickname&password=12345" http://www.yahoo.com/login.cgi
curl -F upload= $localfile  -F $btn_name=$btn_value http://mydomain.net/~zzh/up_file.cgi

# 模仿浏览器
curl -A "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)" -o page.html http://mydomain.net
```