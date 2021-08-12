### 脚本式和声明式
> 脚本式：是一种限制形式的 Groovy 语法

```groovy
node {  
    stage('Build') { 
        // 
    }
    stage('Test') { 
        // 
    }
    stage('Deploy') { 
        // 
    }
}
```

> 声明式：提供更丰富的语法特性
```groovy
pipeline {
    agent any 
    stages {
        stage('Build') { 
            steps {
                // 
            }
        }
        stage('Test') { 
            steps {
                // 
            }
        }
        stage('Deploy') { 
            steps {
                // 
            }
        }
    }
}
```

### 重要参考

**1. 语法指引**
https://www.jenkins.io/zh/doc/book/pipeline/syntax/#agent

**2. 片段生成器**
> 可以根据已安装的插件为各个步骤创建代码段

${YOUR_JENKINS_URL}/pipeline-syntax

**3. 全局变量参考**
> 包含由流水线或插件提供的可用于流水线的变量文档。

${YOUR_JENKINS_URL}/pipeline-syntax/globals

**4. 声明式指令生成器**
> 提供声明式语法块的一些参考

${YOUR_JENKINS_URL}/directive-generator

### 一些语法特性
**1. 使用环境变量**
> 测试在 pipeline 块以外的定义变量使用 "${env.xxx}" 为空
> pipeline 块以内任意位置引用，使用正常

**2. 设置环境变量**
> 声明式：使用 environment 块，且有作用域。
```groovy
def jenkins_agent_lable = "ue4-plugin-build-220-90"

pipeline {
    agent { label "${jenkins_agent_lable}" }
    environment {
        AA = "global env"
    }

    stages {
        stage('stage01') {
            steps {
                echo "${env.AA}"
            }
        }
        stage('stage02') {
            environment {
                AA = "local env"
            }
            steps {
                echo "${env.AA}"
            }
        }
    }
}
```

**3. 设置变量**
> 声明式共有三种方式
```groovy
// 第一种：直接pipeline块之上定义
def flag = 'this is a flag'
pipeline {
    agent { label "ue4-plugin-build-220-90" }
    stages {
        stage('stage01') {
            steps {
                echo "${flag}"
            }
        }
    }
}

// 第二种：类似调用函数式设置
def set_p() {
    flag = 'this is a flag'
}
pipeline {
    agent { label "ue4-plugin-build-220-90" }
    stages {
        stage('stage01') {
            steps {
                set_p()
                echo "${flag}"
            }
        }
    }
}

// 第三种：script 块更为灵活的方式
def set_p(def flag) {
    return flag
}
pipeline {
    agent { label "ue4-plugin-build-220-90" }
    stages {
        stage('stage01') {
            steps {
                script {
                    flag = set_p("this is a flag")
                    echo "${flag}"
                }
            }
        }
    }
}
```

**4. 取secret里的用户名和密码**
> 默认输出 `USR:PSW`
> 使用 `_USR` 后缀取到用户名
> 使用 `_PSW` 后缀取到密码

```groovy
pipeline {
    agent { label "ue4-plugin-build-220-90" }
    environment {
        MY_SECRET = credentials('imgbuild-harbor')
    }
    stages {
        stage('stage01') {
            steps {
                bat("echo ${MY_SECRET} > test.txt")
                bat("echo ${MY_SECRET_USR} >> test.txt")
                bat("echo ${MY_SECRET_PSW} >> test.txt")
            }
        }
    }
}
```

**5. 使用参数构建**
> 使用 `parameters` 块来设置流水线需要参数传入
> 使用 `${params.XXX}` 来引用传入的参数
```groovy
pipeline {
    agent { label "ue4-plugin-build-220-90" }
    parameters {
        string(name: 'Greeting', defaultValue: 'Hello', description: 'HOw should I greet the world?')
    }

    stages {
        stage('stage01') {
            steps {
                echo "${params.Greeting} World!"
            }
        }
    }
}
```

**6. 故障处理**
> 声明式：使用 `post` 块来处理
> 脚本式：依赖 `try catch finally` 来处理

```groovy
// post 与 stages 同级，放在流水线最后
pipeline {
    agent { label "ue4-plugin-build-220-90" }

    stages {
        stage('stage01') {
            steps {
                echo "hello world."
            }
        }
    }
    post {
        always {
            echo "this is a always."
        }
        failure {
            echo "this is a failure."
        }
        success {
            echo "this is a success."
        }
    }
}
```

**7. 使用多个agent**
> agent 支持多个类型的执行器选择，参考官方文档
> agent 可以通过作用域，划分不同 stage 使用不同的 agent 。

**8. 可选参数**
> 可以省略 `()` 
> 当调用只有一个强制参数的步骤时，可以省略参数名称
```
git urt: 'xxxx', branch:'master'
sh 'echo hello'
```

**9. 并行执行**
> `parallel` 关键字，可以并行在不同agent机器上运行

### 流水线中使用容器
> 在流水线版本 2.5 及其以后，流水线内置了与 docker 进行交互的支持


### 扩展共享库
> url：https://www.jenkins.io/zh/doc/book/pipeline/shared-libraries/