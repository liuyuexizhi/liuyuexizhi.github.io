## 需求

在之前测试使用的 Nexus Platform Plugin for Jenkins 插件基础上，给每个产物生成 xml 格式的归档属性文件，在上传时一同上传至 nexus 库。

## 方法

添加 Jenkins 扩展共享库的方法，使用 groovy 语法调用 shell 脚本生成 xml

### 使用指南

> pipeline 使用示例

```groovy
#!groovy
@Library('jk-pipeline-library@master') _

// jenkins agent lable 名
def jenkins_agent_lable = 'ue4-build-yw-test'

// 远程仓库信息
def remote_repo_url = 'ssh://git@git-lfs.ppgame.com:2223/Alpha/ue4plugins/testcontentsample.git'
def remote_branch = '*/release'
def credentials_id = 'c92dd488-7868-478c-9b3d-6add5afc52f1'
// checkout 到本地的文件夹名
def local_dir = 'local_dir'

// 归档文件信息
// 如果文件在根目录请留空 def file_dir = ''
// def file_dir = ''
def file_name = 'testcontentsample.zip'
def file_extension = 'zip'
//  下边两个变量参考 neuxs 文档
def group_id = 'ue4.plugin'
def artifact_id = 'testcontentsample'

def plugin_type = 'content'

// jenkins的neuxs插件信息
// 需要事先在jenkins全局配置中设置
def nexus_instance_id = 'nexus3-test'
// 需要事先在neuxs中创建的maven库名
def nexus_repository_id = 'maven-releases'


def prepareJob(){
    //def version = sh(label: '', returnStdout: true, script: "cat ${version_path} | xargs echo").trim()
    def version = powershell(label: '', encoding: 'utf-8', returnStdout: true, script: "Get-Content -encoding utf8 -Path VERSION -RAW").trim()
    def descripsion = powershell(label: '', encoding: 'utf-8', returnStdout: true, script: "Get-Content -encoding utf8 -Path DESCRIPTION -RAW").trim()


    def commitUser = powershell(label: '', encoding: 'utf-8', returnStdout: true, script: 'git show -s --format=%an').trim()
    def commitNumber = powershell(label: '', encoding: 'utf-8', returnStdout: true, script: 'git rev-parse HEAD').trim()
    def commitTime = powershell(label: '', encoding: 'utf-8', returnStdout: true, script: "git show -s --format=%ad --date=format:'%Y-%m-%d-%H:%M:%S'").trim()
    env.version = "${version}"
    env.descripsion = "${descripsion}"
    env.commitTime = "${commitTime}"
    env.commitUser = "${commitUser}"
    env.commitNumber = "${commitNumber}"
}


//pipeline
pipeline {
  agent { label "${jenkins_agent_lable}" }
  stages {
    stage('checkout code') {
        steps {
            // checkout code
            checkout([$class: 'GitSCM',
                branches: [[name: "${remote_branch}"]],
                doGenerateSubmoduleConfigurations: false,
                extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: "${local_dir}"],
                    [$class: 'CleanBeforeCheckout']],
                submoduleCfg: [],
                userRemoteConfigs: [[credentialsId: "${credentials_id}",
                    url: "${remote_repo_url}"]]
            ])
        }
    }

    // stage('change workpath') {
    //     when {
    //         expression { "${file_dir}" == '' }
    //     }
    //     steps {
    //         changeWorkpath("${local_dir}")
    //     }
    // }

    stage('build') {
        steps {
            dir("${local_dir}"){
                // build code
                //===================构建代码写在这里============================//
                // sh(label: '', script: "zip -r ${file_name} Content/")
                bat(label: '', script: "cd Content/ && WinRAR.exe a -r ../${file_name} *")
                //===================构建代码写在这里============================//
                // 生成一些构建信息
                prepareJob()
            }
        }
    }

    stage('create xml config') {
        steps{
            dir("${local_dir}"){
                // 这里使用的jenkins扩展共享库方法
                buildXmlFile_Win(
                    "'type=${plugin_type}' 'version=${env.version}' 'groupId=${group_id}' 'artifactId=${artifact_id}' 'buildId=${env.BUILD_NUMBER}' 'commitId=${env.commitNumber}' 'commitUser=${env.commitUser}' 'commitTime=${env.commitTime}' 'descripsion=${env.descripsion}'"
                )
            }
        }
    }

    stage('upload to nexus') {
        steps{
            dir("${local_dir}"){
                // nexus publisher
                nexusPublisher(
                    nexusInstanceId: "${nexus_instance_id}",
                    nexusRepositoryId: "${nexus_repository_id}",
                    packages: [
                        [
                            $class: 'MavenPackage',
                            mavenAssetList: [
                                // 上传文件列表
                                [classifier: '', extension: "${file_extension}", filePath: "${file_name}"],
                                [classifier: 'metadata', extension: 'xml', filePath: 'metadata.xml']
                            ],
                            mavenCoordinate: [
                                artifactId: "${artifact_id}",
                                groupId: "${group_id}",
                                packaging: "${file_extension}",
                                version: "${env.version}",
                                // 仅 nexus pro 版本支持 tag
                                //tagName: ''
                            ]
                        ]
                    ])
                // nexusPublisher end
            } // dir end
        } // steps end
    }
  } // stages end
} // pipeline end
```

### Jenkins扩展共享库源码

> JenkinsABS/jk-pipeline-library/vars/buildXmlFile.groovy

```groovy
def call(var){
    // 导入 shell 脚本
    def cmd = libraryResource 'scripts/buildXml.sh'
    withEnv(['parameters=' + var]){
        def run_statue = sh(cmd)
        println run_statue
    }
}
```

> JenkinsABS/jk-pipeline-library/resources/scripts/buildXml.sh

```bash
#!/bin/bash

xml_base="<metadata>=INSERT_HERE=</metadata>"
xml_file='metadata.xml'

function usage_info()
{
    echo 'usage: bash create_xml.sh "author=xxx" "version=1.0.1" "key=value"...'
    exit 0
}

function creeat_xml()
{
    long_str=''
    for kv in $parameters
    do
        key=$(echo ${kv} | cut -d '=' -f 1)
        value=$(echo ${kv} | cut -d '=' -f 2)
        long_str="${long_str}<${key}>${value}</${key}>\n"
    done
    xml_out=$(echo ${xml_base} | sed "s@=INSERT_HERE=@\n${long_str}@")
    echo "${xml_out}" > ${xml_file}
    cat "${xml_file}"
}

function main()
{
    echo $parameters
    ### 参数为 0
    # [ $# -eq 0 ] && usage_info


    for kv in $parameters
    do
        if [[ ! ${kv} =~ '=' ]]
        then
            echo 'error: parameters error.'
            usage_info
        fi
    done
    creeat_xml $parameters


}
main $@
```
