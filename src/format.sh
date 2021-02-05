#!/bin/bash
# set -e

md5_file='md5sum.txt'

function md5_clear()
{
    # 检查记录的文件是否被删除
    for ff in $(awk '{print $2}' ${md5_file})
    do
        if [[ -f ${ff} ]]
        then
            continue
        else
            fname=$(basename ${ff})
            suffix=${fname##*.}
            sed -i "/${fname}/d" ${md5_file}
            if [[ ${suffix} == 'md' ]]
            then
                rm -fv ../_posts/${fname}
            else
                temp_str=${fname:11}
                img=${temp_str#*-}
                img_date=${fname:0:10}
                img_path="../posts_imgs/$(echo ${img_date} | tr '-' '/')"
                rm -fv ${img_path}/${img}
            fi
        fi
    done
}

function md5_tool()
{
    the_file=$1
    [ -f ${md5_file} ] || touch ${md5_file}
    if [[ $(grep ${the_file} ${md5_file}) ]]
    then
        md5_new=$(md5sum ${the_file} | awk '{print $1}')
        md5_old=$(grep ${the_file} ${md5_file} | awk '{print $1}')
        if [[ ${md5_new} == ${md5_old} ]]
        then
            return 0
        else
            sed -i "s@${md5_old}@${md5_old}@"  ${md5_file}
            return 1
        fi
    else
        md5sum ${the_file} >> ${md5_file}
        return 1
    fi
}

function handle_post()
{
    # 处理文章
    [[ -d '../_posts' ]] || exit "dir[../posts] not found."
    for post in $(find ./posts -type f -name "*.md")
    do
        md5_tool ${post}
        [[ $? == 0 ]] && continue
        post_file=$(basename ${post})
        temp_str=${post_file:11}
        this_title=${temp_str%.*}
        target_name="../_posts/${post_file}"

        [[ -f ${target_name} ]] && rm -fv ${target_name}

        echo "=====Format[Posts]:: ${post_file} ====="
        sed -e "4 a ## 目录\n+ this is a toc line\n{:toc}\n" \
            -e "4 a {% raw %}\n" \
            -e "$ a {% endraw %}" \
            -e "1 a title: ${this_title}" \
            -e "s/<\(.*\)>/\\\<\1\\\>/" ${post} > ${target_name}
    done
}

function handle_imag()
{
    # 处理图片
    [[ -d '../posts_imgs' ]] || exit "dir[../posts_imgs] not found."
    for each in $(find ./posts/imgs -type f)
    do
        md5_tool ${each}
        [[ $? == 0 ]] && continue
        full_name=$(basename ${each})
        temp_str=${full_name:11}
        img=${temp_str#*-}
        img_date=${full_name:0:10}
        img_path="../posts_imgs/$(echo ${img_date} | tr '-' '/')"
        target_name="${img_path}/${img}"

        [[ -f ${target_name} ]] && rm -fv ${target_name}

        echo "=====Format[Images]:: ${full_name} ====="
        [[ -d "${img_path}" ]] || mkdir -p ${img_path}         
        cp -f "${each}" "${target_name}"
    done
}

function main()
{
    cd $(dirname $0)
    md5_clear
    handle_post
    handle_imag
    cd -
}

main $@
