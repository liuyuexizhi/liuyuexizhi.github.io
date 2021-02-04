#!/bin/bash

cd $(dirname $0)

# 处理文章
[ -d ../_posts/ ] && rm -rf ../_posts/* || exit "dir not found."
for post in $(find ./posts -type f -name "*.md")
do
    post_file=$(basename ${post})
    temp_str=${post_file:11}
    this_title=${temp_str%.*}
    echo "=====Format[Posts]:: ${post_file} ====="
    sed -e "4 a ## 目录\n+ this is a toc line\n{:toc}\n" \
        -e "4 a {% raw %}\n" \
        -e "$ a {% endraw %}" \
        -e "1 a title: ${this_title}" \
        -e "s/<\(.*\)>/\\\<\1\\\>/" ${post} > ../_posts/${post_file}
done

# 处理图片
[ -d ../posts_imgs/ ] && rm -rf ../posts_imgs/* || exit "dir not found."
for each in $(find ./posts/imgs -type f)
do
    full_name=$(basename ${each})
    temp_str=${full_name:11}
    img=${temp_str#*-}
    img_date=${full_name:0:10}
    img_path="../posts_imgs/$(echo ${img_date} | tr '-' '/')"
    echo "=====Format[Images]:: ${full_name} ====="
    [[ -d "${img_path}" ]] || mkdir -p ${img_path}         
    cp -f "${each}" "${img_path}/${img}"
done

cd -
