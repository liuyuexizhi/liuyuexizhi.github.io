#!/bin/bash
# set -e

md5_file='md5sum.txt'

function md5_clear()
{
    # 检查记录的文件是否被删除
    [ -f ${md5_file} ] || touch ${md5_file}
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
                thisfile=$(echo ${fname} | sed "s@-\[.*\]@@")
                topath="../_posts/${thisfile}"
                rm -fv ${topath}
            else
                fullname=$(basename ${each})
                arr_name=($(echo ${fullname} | tr '-' ' '))
                img_path="../posts_imgs/$(echo ${arr_name[@]} | awk '{print $1"/"$2"/"$3}')"
                for i in $(seq 0 3)
                do
                    unset arr_name[i]
                done
                img_name=$(echo ${arr_name[@]} | tr ' ' '-')
                target="${img_path}/${img_name}"
                rm -fv ${target}
            fi
        fi
    done
}

function md5_tool()
{
    the_file=$1
    if [[ $(grep -F ${the_file} ${md5_file}) ]]
    then
        md5_new=$(md5sum ${the_file} | awk '{print $1}')
        md5_old=$(grep -F ${the_file} ${md5_file} | awk '{print $1}')
        if [[ ${md5_new} == ${md5_old} ]]
        then
            return 0
        else
            sed -i "s@${md5_old}@${md5_new}@"  ${md5_file}
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
        fullname=$(basename ${post})
        tag=$(echo ${fullname} | grep -Eo '\[.*\]')
        thisfile=$(echo ${fullname} | sed "s@-\[.*\]@@")
        thistitle=$(echo ${thisfile} | sed "s@\.md@@" | awk -F '-' '{$1="";$2="";$3="";print}' | xargs echo -n | tr ' ' '-')
        topath="../_posts/${thisfile}"

        [[ -f ${topath} ]] && rm -fv ${topath}

        echo "=====Format[Posts]:: ${thisfile} ====="
        sed -e "1 i ---\ncategories: ${tag}\ntitle: ${thistitle}\n---\n\n## 目录\n+ this is a toc line\n{:toc}\n\n{% raw %}\n" \
            -e "$ a {% endraw %}" \
            -e "s/<\(.*\)>/\\\<\1\\\>/" ${post} > ${topath}
        # sed -e "4 a ## 目录\n+ this is a toc line\n{:toc}\n" \
        #     -e "4 a {% raw %}\n" \
        #     -e "$ a {% endraw %}" \
        #     -e "1 a title: ${this_title}" \
        #     -e "s/<\(.*\)>/\\\<\1\\\>/" ${post} > ${topath}
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
        fullname=$(basename ${each})
        arr_name=($(echo ${fullname} | tr '-' ' '))
        img_path="../posts_imgs/$(echo ${arr_name[@]} | awk '{print $1"/"$2"/"$3}')"
        for i in $(seq 0 3)
        do
            unset arr_name[i]
        done
        img_name=$(echo ${arr_name[@]} | tr ' ' '-')
        target="${img_path}/${img_name}"

        [[ -f ${target} ]] && rm -fv ${target}

        echo "=====Format[Images]:: ${fullname} ====="
        [[ -d "${img_path}" ]] || mkdir -p ${img_path}         
        cp -f "${each}" "${target}"
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
